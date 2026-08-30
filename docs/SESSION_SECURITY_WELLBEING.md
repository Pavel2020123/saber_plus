# Sesión por dispositivo, integridad y descansos

La Etapa 6D-B prepara el cliente móvil para una sesión activa por cuenta, registra interrupciones durante el simulacro avanzado y agrega pausas saludables durante el estudio normal.

## Identidad de la instalación

En el primer uso, Flutter genera 24 bytes aleatorios y conserva su representación segura de 32 caracteres en Keychain o EncryptedSharedPreferences. Este valor:

- identifica únicamente la instalación de SaberPlus;
- no usa IMEI, número telefónico, dirección MAC, nombre del equipo ni publicidad;
- se envía como `X-Device-Id` en el login y en todas las solicitudes a la API;
- permanece estable hasta que se elimina la información segura de la aplicación.

También se envía `X-SaberPlus-Client: mobile`. El identificador no es una contraseña y nunca sustituye la validación del JWT.

## Contrato pendiente para un único dispositivo

Flutter ya reconoce los códigos `SESSION_REPLACED`, `DEVICE_SESSION_CONFLICT`, `SINGLE_DEVICE_SESSION`, `SESION_REEMPLAZADA` y `SESION_OTRO_DISPOSITIVO`. Cuando una solicitud autenticada recibe uno de ellos, la app elimina el token local, cierra la sesión y explica que la cuenta se abrió en otro dispositivo.

La restricción real no puede implementarse solo en Flutter. El backend debe:

1. crear una sesión de servidor vinculada al usuario, al `X-Device-Id` y a un identificador de sesión incluido en el JWT;
2. al iniciar sesión en una instalación nueva, revocar la sesión activa anterior;
3. validar que la sesión siga activa en cada endpoint protegido;
4. devolver `401` con uno de los códigos anteriores al dispositivo reemplazado;
5. ofrecer cierre remoto, refresh rotation y auditoría sin almacenar el identificador en texto plano cuando no sea necesario.

Ocultar botones o comparar identificadores únicamente en Flutter no sería una protección válida, porque un cliente modificado podría omitir esa verificación.

## Integridad del simulacro AM/PM

Durante una jornada AM o PM, pasar la aplicación a segundo plano:

- no detiene el temporizador;
- incrementa una sola vez el contador por cada salida;
- guarda el contador dentro del borrador cifrado para conservarlo al reanudar;
- informa al estudiante al regresar.

La app no reprueba automáticamente el intento. Una llamada, una alerta del sistema o una herramienta de accesibilidad pueden producir la misma señal. Para convertirla en una regla institucional, el backend deberá recibir y firmar los eventos, definir tolerancias y permitir revisión o apelación.

## Descanso saludable de tres minutos

Después de 50 minutos activos dentro de una lección o práctica normal aparece el mensaje:

> ¿Y si descansas? Ve, camina, toma agua, despeja la mente y vuelve en tres minutos.

El estudiante puede iniciar un contador de `03:00` o elegir “Ahora no”. La pausa también permite volver antes, porque es una ayuda de bienestar y no un bloqueo disciplinario.

El contador de estudio se pausa mientras el diálogo está abierto y el tiempo en segundo plano no se considera concentración activa. La sugerencia no aparece dentro de simulacros cronometrados AM/PM ni por área, para no consumir injustamente el tiempo protegido del intento.
