# Contrato real de autenticación

Contrato auditado el 27 de agosto de 2026 contra el backend NestJS del repositorio `Pavel2020123/Icfes_Vida` (commit `1e1f80a`). La app usa `API_BASE_URL` sin el sufijo `/v1`; en el emulador Android el valor local es `http://10.0.2.2:3000`.

## Endpoints y cuerpos

| Acción | Método y ruta | Cuerpo |
| --- | --- | --- |
| Registro | `POST /auth/registro` | `nombre`, `correo`, `contrasena`, `codigoReferido?` |
| Login | `POST /auth/login` | `correo`, `contrasena` |
| Verificar correo | `POST /auth/verificar-correo` | `token` |
| Reenviar verificación | `POST /auth/reenviar-verificacion` | `correo` |
| Solicitar recuperación | `POST /auth/solicitar-recuperacion` | `correo` |
| Restablecer contraseña | `POST /auth/restablecer-contrasena` | `token`, `nuevaContrasena` |
| Consultar perfil | `GET /auth/perfil` | Bearer JWT |
| Cambiar contraseña inicial | `PATCH /auth/cambiar-contrasena-inicial` | `nuevaContrasena` y Bearer JWT |

La contraseña nueva debe tener entre 8 y 72 caracteres, al menos una mayúscula y un número. El login admite desde 6 caracteres para conservar compatibilidad con cuentas existentes.

## Respuestas principales

El login devuelve:

```json
{
  "mensaje": "Inicio de sesión exitoso",
  "accessToken": "jwt",
  "usuario": {
    "id": "uuid",
    "nombre": "Santiago Pérez",
    "correo": "estudiante@ejemplo.com",
    "rol": "ESTUDIANTE",
    "xpTotal": 0,
    "institucionId": null,
    "debeCambiarContrasena": false
  }
}
```

Los roles aceptados son `ESTUDIANTE`, `PROFESOR` y `ADMIN`. Después del login la app consulta `/auth/perfil` para obtener el estado completo de correo y contraseña inicial.

El registro devuelve `mensaje` y `usuarioId`. Como no devuelve el correo, la app conserva el correo enviado para mostrar la pantalla de verificación.

## Sesión y errores

El backend emite un JWT con duración de 8 horas. No expone refresh token, logout remoto ni revocación por dispositivo. Por eso la app:

- almacena el access token cifrado con Keychain/EncryptedSharedPreferences;
- valida la sesión guardada consultando `/auth/perfil` al arrancar;
- borra el token local si la validación falla;
- cierra la sesión solamente en el dispositivo.

NestJS puede devolver `statusCode`, `error` y `message`; algunos guards usan `codigo` y `mensaje`. La app interpreta ambos formatos y también listas de mensajes de validación.

## Limitaciones pendientes del backend

- El registro no acepta ni persiste grado, versión de términos o consentimiento del acudiente. El `ValidationPipe` rechaza campos adicionales, por lo que Flutter no debe enviarlos hasta ampliar el DTO y el modelo del servidor.
- Los correos generan enlaces hacia `FRONTEND_URL`; los deep links `saberplus://auth/...` ya existen en la app, pero el backend todavía no los entrega en sus correos.
- No existe OpenAPI versionado, refresh rotation, sesiones por dispositivo ni revocación remota.
- Para probar contra un servidor externo falta definir su URL HTTPS en `API_BASE_URL`.
