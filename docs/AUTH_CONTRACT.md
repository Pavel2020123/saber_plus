# Contrato móvil esperado para autenticación

La app consume `API_BASE_URL`, cuyo valor debe terminar en `/v1`. Este documento fija el contrato que falta validar contra el backend real.

## Formato de error

```json
{
  "code": "invalid_credentials",
  "message": "Correo o contraseña incorrectos.",
  "details": null,
  "traceId": "req-123"
}
```

Los mensajes no deben revelar si un correo existe durante recuperación o reenvío.

## Login

`POST /auth/login`

```json
{
  "email": "estudiante@ejemplo.com",
  "password": "contraseña"
}
```

Respuesta:

```json
{
  "accessToken": "token-corto",
  "refreshToken": "token-opaco-rotativo",
  "user": {
    "id": "uuid",
    "firstName": "Santiago",
    "email": "estudiante@ejemplo.com",
    "role": "student",
    "emailVerified": true,
    "mustChangePassword": false
  }
}
```

`role` debe ser `student`, `teacher` o `admin`. El access token se mantiene en memoria; el refresh token se guarda cifrado en el dispositivo.

## Registro

`POST /auth/registro`

Campos: `firstName`, `lastName`, `email`, `password`, `grade`, `referralCode`, `acceptedPolicyVersion` y `guardianConsent`.

Respuesta:

```json
{
  "email": "estudiante@ejemplo.com",
  "verificationRequired": true
}
```

El backend debe registrar evidencia versionada del consentimiento; un booleano del cliente no constituye por sí solo esa evidencia.

## Sesión

- `POST /auth/refresh`: recibe `refreshToken` y devuelve la misma estructura del login con un refresh token nuevo.
- `POST /auth/logout`: recibe `refreshToken`, revoca la sesión y puede llamarse sin access token.
- `GET /auth/perfil`: devuelve el objeto `user` usando Bearer token.
- `PATCH /auth/cambiar-contrasena-inicial`: recibe `password` usando Bearer token.

La rotación debe detectar reutilización, revocar la familia comprometida y mantener sesiones separadas por dispositivo.

## Verificación y recuperación

- `POST /auth/verificar-correo` con `token`.
- `POST /auth/reenviar-verificacion` con `email`.
- `POST /auth/solicitar-recuperacion` con `email`.
- `POST /auth/restablecer-contrasena` con `token` y `password`.

Deep links implementados:

- `saberplus://auth/verify-email?token=...`
- `saberplus://auth/reset-password?token=...`

El dominio HTTPS para App Links y Universal Links sigue pendiente porque no está definido en este repositorio.
