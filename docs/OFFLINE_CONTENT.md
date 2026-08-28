# Contenido sin conexión

Alcance implementado en la Etapa 5D para Android y iOS.

## Qué se guarda

- El estudiante puede descargar el PDF autenticado de un tema desde `GET /simulacros/temas/:temaId/pdf`.
- El archivo se conserva dentro del directorio de documentos privado de la aplicación, no en una carpeta temporal.
- Drift/SQLite registra el usuario, tema, área, ruta, tamaño y fecha de cada descarga.
- Una clave compuesta por usuario y tema evita duplicados. Repetir una descarga actualiza el archivo y sus metadatos.

La pantalla **Estudiar > Descargas** permite abrir archivos sin conexión, consultar el espacio total, eliminar un tema o liberar todas las descargas de la cuenta activa.

## Separación y limpieza

Cada usuario tiene registros y directorio propios. Cerrar sesión no elimina automáticamente los PDF, pero otra cuenta no los ve ni los administra. Si un archivo fue eliminado fuera de la aplicación, su registro huérfano se descarta al intentar abrirlo.

Las eliminaciones operan sobre rutas exactas previamente registradas. La limpieza total recorre los archivos de la cuenta activa y no borra directorios amplios de forma recursiva.

## Límites deliberados

- Primero se necesita conexión y una sesión real para descargar el PDF.
- Los videos y enlaces externos no se descargan.
- El envío diferido de progreso, notas o intentos no forma parte de esta entrega. Las operaciones seguras y los conflictos se tratarán en la siguiente etapa.
- La API sigue siendo la fuente de verdad del contenido y los resultados.

Este almacenamiento local es complementario al backend. Si PostgreSQL se aloja en Supabase, la app continuará accediendo a los datos remotos mediante la API NestJS y conservará Drift para funcionar sin conexión.
