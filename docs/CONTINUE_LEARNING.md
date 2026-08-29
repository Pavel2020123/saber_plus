# Continúa donde quedaste

Inicio muestra un acceso directo a la última lección visitada por el estudiante. La tarjeta aparece después de abrir una lección por primera vez y permite regresar a ella con un solo toque.

## Persistencia

La ubicación se guarda en Drift/SQLite con los datos mínimos necesarios:

- Identificador del estudiante.
- Área, tema y subtema.
- Títulos visibles del tema y la lección.
- Fecha de la última apertura.

Solo se conserva una ubicación por estudiante. Al abrir otra lección, la entrada anterior se reemplaza. Las cuentas que utilizan el mismo dispositivo permanecen separadas.

La migración local 4 agrega `learning_resume_entries` sin eliminar las descargas, operaciones pendientes ni favoritos creados en versiones anteriores.

## Relación con las prácticas

Esta entrega recuerda la última lección, no una sesión ya calificada. Los intentos activos continúan usando el borrador cifrado existente; al volver a la lección y entrar de nuevo a la práctica correspondiente, Flutter recupera el mismo intento cuando todavía es válido.

## Límite actual

El backend registra porcentajes de progreso y fechas de actividad, pero no publica una ruta móvil que identifique la última pantalla visitada. Por eso, la ubicación se conserva únicamente en el dispositivo y no reaparece al instalar la aplicación en otro teléfono.

Si el backend incorpora este contrato más adelante, deberá guardar identificadores académicos y tipo de actividad, no una URL arbitraria enviada por el cliente.
