param(
  [string]$ApiBaseUrl = 'http://127.0.0.1:3100',
  [Parameter(Mandatory = $true)]
  [string]$DatabaseUrl,
  [string]$PsqlPath = 'C:\Program Files\PostgreSQL\16\bin\psql.exe'
)

$ErrorActionPreference = 'Stop'
$apiRoot = $ApiBaseUrl.TrimEnd('/')
$psqlDatabaseUrl = $DatabaseUrl.Split('?')[0]
$testId = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$email = "mobile.e2e.$testId@example.com"
$password = 'SaberPlus2026A'
$newPassword = 'SaberPlus2027B'

function Invoke-Api {
  param(
    [Parameter(Mandatory = $true)][string]$Method,
    [Parameter(Mandatory = $true)][string]$Path,
    [int]$ExpectedStatus = 200,
    [hashtable]$Body,
    [string]$Token
  )

  $parameters = @{
    Uri = "$apiRoot$Path"
    Method = $Method
    UseBasicParsing = $true
    Headers = @{ Accept = 'application/json' }
  }
  if ($Body) {
    $parameters.ContentType = 'application/json'
    $parameters.Body = $Body | ConvertTo-Json -Compress
  }
  if ($Token) {
    $parameters.Headers.Authorization = "Bearer $Token"
  }

  try {
    $response = Invoke-WebRequest @parameters
    $status = [int]$response.StatusCode
    $content = $response.Content
  } catch {
    if (-not $_.Exception.Response) { throw }
    $response = $_.Exception.Response
    $status = [int]$response.StatusCode
    $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
    try { $content = $reader.ReadToEnd() } finally { $reader.Dispose() }
  }

  if ($status -ne $ExpectedStatus) {
    throw "$Method $Path devolvió $status; se esperaba $ExpectedStatus."
  }
  Write-Host "OK $status $Method $Path"
  if ($content) { return $content | ConvertFrom-Json }
  return $null
}

function Read-UserToken {
  param([Parameter(Mandatory = $true)][string]$Column)

  if (-not (Test-Path -LiteralPath $PsqlPath)) {
    throw "No se encontró psql en $PsqlPath"
  }
  if ($Column -notin @('tokenVerificacion', 'tokenRecuperacion')) {
    throw 'Columna de token no permitida.'
  }

  $sql = 'SELECT \"{0}\" FROM \"Usuario\" WHERE correo = ''{1}'';' -f $Column, $email
  $token = & $PsqlPath -d $psqlDatabaseUrl -tA -v ON_ERROR_STOP=1 -c $sql
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($token)) {
    throw "No se pudo recuperar $Column para el usuario E2E."
  }
  return $token.Trim()
}

Write-Host "Validando autenticación real en $apiRoot"

Invoke-Api -Method GET -Path '/' -ExpectedStatus 200 | Out-Null

$registration = Invoke-Api -Method POST -Path '/auth/registro' -ExpectedStatus 201 -Body @{
  nombre = 'Usuario Móvil E2E'
  correo = $email
  contrasena = $password
}
if ([string]::IsNullOrWhiteSpace($registration.usuarioId)) {
  throw 'El registro no devolvió usuarioId.'
}

$unverifiedLogin = Invoke-Api -Method POST -Path '/auth/login' -ExpectedStatus 201 -Body @{
  correo = $email
  contrasena = $password
}
$unverifiedProfile = Invoke-Api -Method GET -Path '/auth/perfil' -ExpectedStatus 200 -Token $unverifiedLogin.accessToken
if ($unverifiedProfile.correoVerificado -or -not $unverifiedProfile.requiereVerificacionCorreo) {
  throw 'El perfil no indicó que el estudiante individual debe verificar su correo.'
}

$verificationToken = Read-UserToken -Column 'tokenVerificacion'
Invoke-Api -Method POST -Path '/auth/verificar-correo' -ExpectedStatus 201 -Body @{
  token = $verificationToken
} | Out-Null

$login = Invoke-Api -Method POST -Path '/auth/login' -ExpectedStatus 201 -Body @{
  correo = $email
  contrasena = $password
}
if ([string]::IsNullOrWhiteSpace($login.accessToken)) {
  throw 'El login no devolvió accessToken.'
}
if ($login.usuario.rol -ne 'ESTUDIANTE') {
  throw "El login devolvió un rol inesperado: $($login.usuario.rol)"
}

$profile = Invoke-Api -Method GET -Path '/auth/perfil' -ExpectedStatus 200 -Token $login.accessToken
if ($profile.correo -ne $email -or -not $profile.correoVerificado) {
  throw 'El perfil autenticado no coincide con la cuenta verificada.'
}

Invoke-Api -Method POST -Path '/auth/solicitar-recuperacion' -ExpectedStatus 201 -Body @{
  correo = $email
} | Out-Null
$recoveryToken = Read-UserToken -Column 'tokenRecuperacion'
Invoke-Api -Method POST -Path '/auth/restablecer-contrasena' -ExpectedStatus 201 -Body @{
  token = $recoveryToken
  nuevaContrasena = $newPassword
} | Out-Null

Invoke-Api -Method POST -Path '/auth/login' -ExpectedStatus 401 -Body @{
  correo = $email
  contrasena = $password
} | Out-Null

$newLogin = Invoke-Api -Method POST -Path '/auth/login' -ExpectedStatus 201 -Body @{
  correo = $email
  contrasena = $newPassword
}
if ([string]::IsNullOrWhiteSpace($newLogin.accessToken)) {
  throw 'El login con la nueva contraseña no devolvió accessToken.'
}

Invoke-Api -Method GET -Path '/auth/perfil' -ExpectedStatus 401 | Out-Null
Invoke-Api -Method POST -Path '/auth/reenviar-verificacion' -ExpectedStatus 201 -Body @{
  correo = "unknown.$testId@example.com"
} | Out-Null

Write-Host 'Validando el repositorio Dart de Flutter contra la API...'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $projectRoot
try {
  & flutter test test/auth_api_live_test.dart `
    "--dart-define=AUTH_E2E_API_BASE_URL=$apiRoot" `
    "--dart-define=AUTH_E2E_EMAIL=$email" `
    "--dart-define=AUTH_E2E_PASSWORD=$newPassword"
  if ($LASTEXITCODE -ne 0) {
    throw 'El repositorio Flutter no superó la prueba contra la API real.'
  }

  & flutter test test/diagnostic_api_live_test.dart `
    "--dart-define=AUTH_E2E_API_BASE_URL=$apiRoot" `
    "--dart-define=AUTH_E2E_EMAIL=$email" `
    "--dart-define=AUTH_E2E_PASSWORD=$newPassword"
  if ($LASTEXITCODE -ne 0) {
    throw 'El diagnóstico Flutter no superó la prueba contra la API real.'
  }

  & flutter test test/study_api_live_test.dart `
    "--dart-define=AUTH_E2E_API_BASE_URL=$apiRoot" `
    "--dart-define=AUTH_E2E_EMAIL=$email" `
    "--dart-define=AUTH_E2E_PASSWORD=$newPassword"
  if ($LASTEXITCODE -ne 0) {
    throw 'El contenido académico Flutter no superó la prueba contra la API real.'
  }
} finally {
  Pop-Location
}

Write-Host 'Flujo E2E móvil completado correctamente.'
