# LIC-0 — decisiones institucionales

Continuación 2/nov: [LIC-1A, núcleo de vigencia y cupos](<../../../SaberPlus-Backend/backend/docs/LIC_1_NUCLEO_VIGENCIA.md>) implementado sin activación: 3 suites/50 pruebas dirigidas, lint y compilación aprobados. No conecta licencias a API/app/BD ni cierra LIC-1.

2/nov/2026. Diseño documental, no implementación ni despliegue. La fuente funcional única está en [contrato LIC-0 del backend](<../../../SaberPlus-Backend/backend/docs/LIC_0_CONTRATO_INSTITUCIONAL.md>).

Acuerdos: licencia de la institución con propietario transferible; fechas acordadas; cupos reutilizables; propietario separado de docentes; un responsable por grupo; gestión web institucional; acceso histórico al vencer. Distinguir cuentas personales vinculadas con aceptación de cuentas gestionadas. Estas últimas no compran mensualidad ni se trasladan por autoservicio. Preservar días de acceso personal pagados sin prometer pausar la facturación Google Play.

Los usuarios con forma `juanito@ispecan.com` son identificadores institucionales, no correo real. Definir namespace/colisiones antes de cambiar login/importador; recuperación mediante contactos reales o responsables autorizados. Reset docente solo en su ámbito, claves temporales de una entrega y cambio obligatorio, sin guardar contraseñas legibles ni suplantación.

Confirmado por el propietario: SaberPlus aprueba el sufijo solicitado por cada colegio; docentes/propietarios institucionales no restablecen contraseñas de cuentas personales vinculadas; una renovación anticipada continúa desde el final actual y, tras vencimiento, desde una nueva fecha acordada. Las decisiones principales quedan aprobadas, pero faltan detalles técnicos de periodos, reducción/superposición, intentos en curso y login antes de sus respectivas implementaciones. Precios, publicidad/becas, billing individual y traslado de progreso posteriores no se implementan en este bloque. Ver matriz, casos de aceptación y pendientes en la fuente única. No modificar el prototipo independiente de cuadernillos para implementar licencias de la app.

Preparación visual: repositorio solicitado `nextlevelbuilder/ui-ux-pro-max-skill`, revisión fijada a `3a13158ff1f32156cbe144108de48eda2ecaed9a`, licencia MIT. Es orientación de diseño, no tema web ni framework obligatorio. La instalación local se verifica aparte; no supone que una skill ya esté cargada en la sesión ni que se haya construido una web docente.
