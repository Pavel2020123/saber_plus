# Anuncios, referidos, soporte y calculadora

La etapa 6G-F incorpora cuatro herramientas accesibles desde `Más`. Los anuncios de este documento son comunicados internos; no son espacios publicitarios de AdMob.

## Tablón de anuncios

La app consume las rutas autenticadas existentes:

- `GET /anuncios`
- `PATCH /anuncios/:id/leer`
- `PATCH /anuncios/leer-todos`

El estudiante recibe únicamente anuncios vigentes para su audiencia. Si está vinculado a una institución, también ve sus comunicados. El contrato móvil solo expone el contenido público, el origen `SABERPLUS` o `INSTITUCION` y el estado de lectura; no entrega identificadores internos del autor o de la institución.

La pantalla permite filtrar pendientes, marcar uno o todos como leídos y actualizar mediante gesto o botón. La demostración incluye dos comunicados editables en memoria.

## Referidos

El registro ya acepta un código opcional. La app consulta `GET /referidos/mobile` para mostrar el código propio y un conteo anónimo de registros. La invitación se copia como texto para compartirla por cualquier canal.

El contrato móvil no devuelve nombres, resultados académicos, saldo en pesos ni enlaces de la página web. El antiguo incentivo monetario estaba unido a pagos web y no debe presentarse en Android. El beneficio definitivo se definirá junto con Google Play Billing en la etapa 8; hasta entonces la interfaz lo comunica sin prometer dinero o acceso académico.

## Soporte

`GET /soporte` es público y devuelve el canal de WhatsApp configurado por administración. Flutter solo abre una URL si usa HTTPS, el dominio exacto `wa.me` y un número internacional válido. También permite copiar el número y recuerda que soporte resuelve asuntos técnicos o de cuenta, no ofrece tutorías.

En producción debe configurarse un número real desde la administración del backend. El valor de demostración no debe usarse como contacto comercial.

## Calculadora de puntaje

La calculadora es local, no guarda los valores y no necesita backend. Recibe cinco puntajes enteros de 0 a 100 y calcula el global de 0 a 500:

```text
(3LC + 3M + 3SC + 3CN + I) / 13 × 5
```

Lectura Crítica, Matemáticas, Sociales y Ciudadanas y Ciencias Naturales tienen peso 3; Inglés tiene peso 1. La herramienta no convierte cantidad de respuestas correctas a puntajes ICFES ni reemplaza el resultado oficial. Es independiente de la proyección automática del perfil, que usa el historial académico del estudiante.

## Puesta en marcha

Esta etapa reutiliza el esquema Prisma actual y no agrega migraciones. Para probar con una cuenta real se necesita el backend actualizado, un anuncio vigente o la configuración de soporte según el caso. AdMob, derechos sin anuncios y compras permanecen en la etapa 8 y requerirán las cuentas comerciales reales.
