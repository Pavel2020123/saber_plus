# SaberPlus Demo — sustentación local

**Prioridad del miércoles 28/oct:** seguir el [alcance del cliente](PRESENTACION_CLIENTE_2026_10_28.md).
La edición main_demo limita los juegos de Practicar a Cima, Guardián y Rescate.
No elimina los otros juegos de la app normal. Esta selección requiere recompilar;
la APK instalada antes de este cambio no la incluye todavía.

Versión separada para mostrar la aplicación sin contraseña. No es una cuenta
real ni una excepción al login del backend. No cambia el arranque normal.

## Qué mostrar

1. Abrir **SaberPlus Demo**: entra como estudiante demostrativo.
2. Estudiar → elegir una de las cinco áreas → tema → lección.
3. Leer la explicación, marcar completada y practicar sus dos preguntas.
4. Elegir respuestas y mostrar el resultado con explicación.
5. Explorar Practicar, juegos demostrativos y Progreso.

Incluye cinco temas/lecciones y diez preguntas originales de ejemplo:
regla de tres, idea principal, ecosistemas, ciudadanía y lectura en inglés.
La cantidad de preguntas anunciada por lección coincide con las dos disponibles.
El banco demo es pequeño; las prácticas largas pueden repetir preguntas.

Lecciones y prácticas de esta demo no necesitan conexión al servidor. Los
rankings, historiales y XP demostrativos no acreditan actividad real ni prueban
persistencia remota, permisos institucionales o emisión de certificados.
No presentar las pantallas de muestra como datos de estudiantes reales.
El estado demostrativo no garantiza conservar todos los avances tras cerrar.
Si se cierra sesión, usar «Explorar como estudiante» o «Explorar como profesor»
sin introducir correo ni contraseña. Al iniciar de nuevo esta edición entra
directamente como estudiante.

## Compilar APK independiente

Desde la raíz Flutter, PowerShell:

```powershell
C:\flutter_sdk\bin\flutter.bat build apk --debug --target lib/main_demo.dart --android-project-arg=saberplusDemoApk=true --dart-define=APP_ENV=dev --dart-define=DEMO_MODE=true
```

Comprobar antes de instalar: paquete `com.example.saber_plus.demo`, etiqueta
`SaberPlus Demo`. No reemplaza `com.example.saber_plus` ni `.i2validation`.
Salida de compilación: `build/app/outputs/flutter-apk/app-debug.apk`.
También se conservó una copia identificada: `build/app/outputs/flutter-apk/SaberPlus-Demo.apk`.
Es una APK de depuración para sustentación, no una versión para publicar en tienda.

El punto de entrada `lib/main_demo.dart` rechaza staging/producción y demo
desactivada. No incorpora credenciales ni llama al login de la API.
La app normal continúa usando `lib/main.dart` y su autenticación habitual.

## Verificaciones

- `test/presentation_demo_test.dart`: seis pruebas, configuración y preguntas
  calificables de las cinco áreas.
- Se repasan además los tests de sesión, catálogo, simulacro y navegación.
- Verificación del 26/oct: 56/56 pruebas dirigidas aprobadas y análisis Flutter
  sin incidencias. Se corrigió durante la preparación una comprobación nullable
  del test nuevo y se repitió la selección completa con éxito.
- No modifica backend, migraciones, OV-1 ni las pruebas H3 pendientes.
- APK debug compilada el 26/oct; etiqueta y paquete comprobados con aapt.
  Instalación USB finalizada con Success, sin desinstalar las otras ediciones.
  Falta la confirmación visual del propietario al abrirla en el celular.
