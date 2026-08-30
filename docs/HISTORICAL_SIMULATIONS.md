# Banco autorizado de simulacros por año

La Etapa 6D-C agrega el catálogo móvil y el contrato protegido para ediciones de años anteriores. La aplicación no incluye cuadernillos oficiales ni preguntas de terceros porque todavía no se ha entregado contenido con derechos de uso verificados.

## Experiencia móvil

El estudiante entra por `Practicar > Simulacros por año` y puede:

- filtrar por año y estado;
- consultar título, proveedor, disponibilidad y descripción;
- abrir el detalle de fuente y derechos;
- iniciar AM o PM únicamente cuando la edición tenga 150 preguntas y autorización verificable.

Los estados admitidos son:

- `DISPONIBLE`: contenido completo, protegido y con derechos registrados;
- `PROXIMAMENTE`: edición anunciada, pero todavía no habilitada;
- `RESTRINGIDO`: no existe autorización suficiente para mostrar preguntas.

Una edición marcada como disponible se rechaza si no tiene exactamente 150 preguntas o si faltan titular y referencia de derechos. Los elementos bloqueados contienen solamente metadatos y nunca descargan enunciados u opciones.

## Contrato propuesto para el backend

### Catálogo

`GET /simulacros/historicos`

```json
{
  "actualizadoEn": "2026-08-30T12:00:00.000Z",
  "ediciones": [
    {
      "id": "uuid",
      "anio": 2024,
      "titulo": "Edición propia 2024",
      "descripcion": "Prueba archivada de SaberPlus.",
      "proveedor": "SaberPlus",
      "totalPreguntas": 150,
      "estado": "DISPONIBLE",
      "derechos": {
        "tipo": "PROPIO",
        "titular": "SaberPlus",
        "referencia": "SP-OWN-2024"
      }
    }
  ]
}
```

Los tipos de derechos aceptados son `PROPIO`, `LICENCIA` y `REUTILIZABLE`.

### Abrir jornada

`GET /simulacros/historicos/:edicionId/iniciar?jornada=AM|PM`

- exige JWT, plan vigente y sesión de dispositivo activa;
- entrega exactamente 75 preguntas de las cinco áreas;
- conserva los casos compartidos completos dentro de la distribución preparada por el backend;
- no entrega respuestas correctas ni explicaciones;
- crea un intento independiente por edición, estudiante y jornada.

### Calificar jornada

`POST /simulacros/historicos/:edicionId/calificar`

```json
{
  "intentoId": "uuid",
  "jornada": "AM",
  "respuestas": [
    {
      "preguntaId": "uuid",
      "respuestaId": "uuid",
      "tiempoRespuestaSegundos": 22
    }
  ]
}
```

Flutter reutiliza el temporizador, borrador cifrado, registro de salidas, protección contra doble envío, resultado y revisión del simulacro avanzado.

## Cómo cargar ediciones después

La carga no se hará desde la app del estudiante. El panel administrativo o una importación controlada deberá:

1. confirmar que el contenido es propio, licenciado o legalmente reutilizable;
2. registrar titular, tipo y referencia documental de la autorización;
3. importar preguntas, opciones, casos, imágenes y clasificación académica;
4. validar 75 preguntas AM, 75 PM y presencia de las cinco áreas;
5. revisar que ningún endpoint público exponga respuestas correctas;
6. publicar la edición cambiando su estado a `DISPONIBLE`.

El archivo de autorización debe conservarse fuera de Flutter en almacenamiento administrativo seguro. El catálogo solo recibe su referencia, no contratos o documentos privados.

## Demostración

El modo demostrativo muestra ediciones 2025 y 2024 bloqueadas para probar filtros, navegación y estados. No contiene preguntas históricas y no afirma que exista autorización oficial.
