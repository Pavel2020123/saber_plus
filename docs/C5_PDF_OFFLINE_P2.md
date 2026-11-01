# C5 PDF P2 — recorrido integrado local completado

31/oct/2026. Después de [P1](C5_PDF_OFFLINE.md), se probaron descarga, apertura y denegación de una nueva copia tras revocación en el Android USB. Solo SaberPlus Pruebas y sesión sintética local autorizada; sin producción, push ni merge a main.

## Resultados

- Backend HTTP/PostgreSQL: **95/95**, 78 migraciones temporales, cero fallos/omitidas, recursos de esa suite eliminados por el runner. [Acta backend](<../../../SaberPlus-Backend/backend/docs/C5_PDF_OFFLINE_P2.md>).
- Descarga desde la app y apertura en Files de Google: imagen azul 400×200 y texto visibles, proporción conservada, aviso de copia descargada legible.
- Revocación ADMIN con recibo verificado. Copia previa abierta sin conexión: permitido para PDF exportable, no equivale a caché privada autorizada.
- Eliminación desde Descargas de **solo el PDF sintético de 4,1 KB** para probar una descarga nueva: una a cero descargas. Ningún documento real eliminado. Se conservan capturas; la nueva copia no puede regenerarse mientras su imagen esté revocada, como corresponde.
- Nueva descarga bloqueada. Se detectó mensaje genérico y se corrigió en las dos rutas PDF mediante `studyPdfError`, sin cambiar contratos de errores de otros endpoints ni revelar motivos de ADMIN.
- Flutter: **14/14** pruebas dirigidas (`study_pdf_error`, `offline_content_repository`, `remote_study_repository`), análisis limpio; hot reload y captura posterior al arreglo. DTD sin errores nuevos.
- Baseline H3 tras consultas: XP 0→0, respuestas 5→5, referencias 10→10 y filas CuadernoError 0→0.

## Evidencia real

[Carpeta de capturas](evidence/c5-pdf-p2/): `android-open.png`, `offline-copy-after-revoke.png`, `new-download-denied.png` (mensaje anterior) y `new-download-denied-fixed.png` (resultado corregido). No presentar la captura previa como resultado final.

Se usó una API adicional AppModule actual en 43188 sobre la base temporal propia, con secreto JWT independiente; el reverse del teléfono se cambió durante la prueba. No se desplegó sobre la API original de la sesión. La APK y limpieza finales se registran al terminar.

## Cierre de APK y sesión

Build debug completado en 70,5 s. `aapt` confirmó identificador `com.example.saber_plus.i2validation` y etiqueta SaberPlus Pruebas; ADB `install -r`: Success. Después de reinstalar se repitió el intento denegado y apareció el mensaje corregido: [captura](evidence/c5-pdf-p2/new-download-denied-installed.png). La corrección no depende del hot reload. La app normal no se sustituyó.

Al terminar se cerró sesión en la app de pruebas, se detuvo únicamente la API adicional 43188 y se restauró el reverse 43187→43187. La API original de la sesión no se actualizó ni se detuvo: conserva su caducidad del runner. La pantalla queda en acceso; no interpretar un token de la API adicional como credencial válida para la original. Para seguir probando P2/P3, montar una instancia con el backend actual, no asumir que la API antigua sirve este incremento. Los fixtures de la base son temporales; no hay despliegue.

## Siguiente entrega recomendada

**P3-A contrato antes de persistir bytes privados**: manifiesto de referencias/versiones, alcance por cuenta, invalidación por logout/cambio de usuario, condiciones de disponibilidad sin red y revalidación al reconectar. Después P3-B backend y P3-C Flutter con ensayos de red/cierre/cuentas. No decidir retención o accesos históricos por aproximación. El PDF ya exportado permanece fuera de la revocación remota.

P2 es cierre local acotado, no de todo PDF/offline/C5 ni de producción. Las ampliaciones de catálogo/extremos visuales y otros dispositivos permanecen en regresión/beta.
