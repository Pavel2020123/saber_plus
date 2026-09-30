# Matriz C — Esquema y migraciones

Inventario completo del schema actual y SQL versionado. No acredita aplicación en Supabase. Las pruebas de PostgreSQL de esta ronda se bloquearon por binarios ausentes. El informe interpreta por dominio las restricciones y riesgos.

## enum Grado

Fuente: backend/prisma/schema.prisma:13

```prisma
enum Grado {
  DECIMO
  ONCE
}
```

## enum CalendarioTipo

Fuente: backend/prisma/schema.prisma:18

```prisma
enum CalendarioTipo {
  A
  B
}
```

## model CalendarioIcfes

Fuente: backend/prisma/schema.prisma:23

```prisma
model CalendarioIcfes {
  id            String         @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  anio          Int
  calendario    CalendarioTipo
  fechaExamen   DateTime       @db.Date
  activo        Boolean        @default(false)
  fechaCreacion DateTime       @default(now()) @db.Timestamp(6)

  @@unique([anio, calendario])
  @@index([activo, fechaExamen])
}
```

## model Clase

Fuente: backend/prisma/schema.prisma:35

```prisma
model Clase {
  id              String                @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  nombre          String                @db.VarChar(255)
  // Campo legado: la aplicación móvil ya no lo expone ni lo acepta.
  codigoIngreso   String                @unique @db.VarChar(50)
  grado           Grado
  institucionId   String                @db.Uuid
  Institucion     Institucion           @relation(fields: [institucionId], references: [id], onDelete: Cascade, onUpdate: NoAction, map: "fk_clase_institucion")
  ClaseEstudiante ClaseEstudiante[]
  prioridadesDocentes PrioridadDocente[]
  profesores      ClaseProfesor[]
  codigos         CodigoTemporalGrupo[]
}
```

## model PrioridadDocente

Fuente: backend/prisma/schema.prisma:51

```prisma
model PrioridadDocente {
  id               String    @id @db.Uuid
  claseId          String    @db.Uuid
  clase            Clase     @relation(fields: [claseId], references: [id], onDelete: Cascade)
  creadoPorId      String    @db.Uuid
  huellaSolicitud  String    @db.VarChar(64)
  area             AreaIcfes
  temaId           String
  temaNombre       String
  subtemaId        String?
  subtemaNombre    String?
  preguntaIds      String[]
  metaPreguntas    Int       @default(5)
  creadoEn         DateTime  @default(now()) @db.Timestamp(6)
  venceEn          DateTime  @db.Timestamp(6)
  retiradoEn       DateTime? @db.Timestamp(6)

  @@index([claseId, creadoEn, id])
  @@index([claseId, retiradoEn, venceEn])
}
```

## model ClaseEstudiante

Fuente: backend/prisma/schema.prisma:72

```prisma
model ClaseEstudiante {
  usuarioId           String               @db.Uuid
  claseId             String               @db.Uuid
  codigoTemporalId    String?              @db.Uuid
  aceptacionExplicita Boolean              @default(false)
  fechaIngreso        DateTime             @default(now()) @db.Timestamp(6)
  Clase               Clase                @relation(fields: [claseId], references: [id], onDelete: Cascade, onUpdate: NoAction, map: "fk_ce_clase")
  Usuario             Usuario              @relation(fields: [usuarioId], references: [id], onDelete: Cascade, onUpdate: NoAction, map: "fk_ce_usuario")
  codigoTemporal      CodigoTemporalGrupo? @relation(fields: [codigoTemporalId], references: [id], onDelete: SetNull)

  @@id([usuarioId, claseId])
  @@index([codigoTemporalId])
}
```

## model ClaseProfesor

Fuente: backend/prisma/schema.prisma:86

```prisma
model ClaseProfesor {
  claseId         String             @db.Uuid
  miembroId       String             @db.Uuid
  fechaAsignacion DateTime           @default(now()) @db.Timestamp(6)
  clase           Clase              @relation(fields: [claseId], references: [id], onDelete: Cascade)
  miembro         MiembroInstitucion @relation(fields: [miembroId], references: [id], onDelete: Cascade)

  @@id([claseId, miembroId])
  @@index([miembroId, fechaAsignacion])
}
```

## model CodigoTemporalGrupo

Fuente: backend/prisma/schema.prisma:97

```prisma
model CodigoTemporalGrupo {
  id              String             @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  claseId         String             @db.Uuid
  codigoHash      String             @unique @db.VarChar(64)
  sufijo          String             @db.VarChar(4)
  activo          Boolean            @default(true)
  usos            Int                @default(0)
  usosMaximos     Int
  fechaExpiracion DateTime           @db.Timestamp(6)
  fechaCreacion   DateTime           @default(now()) @db.Timestamp(6)
  creadoPorId     String             @db.Uuid
  clase           Clase              @relation(fields: [claseId], references: [id], onDelete: Cascade)
  creadoPor       MiembroInstitucion @relation(fields: [creadoPorId], references: [id], onDelete: Cascade)
  vinculaciones   ClaseEstudiante[]

  @@index([claseId, activo, fechaExpiracion])
  @@index([creadoPorId, fechaCreacion])
}
```

## model Institucion

Fuente: backend/prisma/schema.prisma:116

```prisma
model Institucion {
  estadoVerificacion   EstadoAltaInstitucion @default(PENDIENTE)
  transicionHasta       DateTime? @db.Timestamp(3)
  solicitudAlta         SolicitudAltaInstitucion?
  id                   String                        @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  nombre               String                        @db.VarChar(255)
  codigoUnico          String                        @unique @db.VarChar(50)
  planActual           String?                       @default("GRATIS") @db.VarChar(50)
  logoUrl              String?                       @db.VarChar(255)
  mensajeBienvenida    String?                       @db.Text
  imagenPortada        String?                       @db.VarChar(255)
  limiteGrado10        Int?
  limiteGrado11        Int?
  limiteGrupos         Int?
  limiteEstudiantes    Int?
  // Calendario ICFES que rige a este colegio (define contra qué fecha
  // de examen se calcula la vigencia del plan institucional). Punto 6.
  calendarioIcfes      CalendarioTipo?               @default(A)
  fechaVencimientoPlan DateTime?                     @db.Timestamp(6)
  Clase                Clase[]
  Usuario              Usuario[]
  anuncios             Anuncio[]
  miembros             MiembroInstitucion[]
  solicitudesIngreso   SolicitudIngresoInstitucion[]
  invitaciones         InvitacionInstitucion[]
  auditorias           AuditoriaInstitucion[]
}
```

## model Usuario

Fuente: backend/prisma/schema.prisma:144

```prisma
model Usuario {
  repasosDiferidos RepasoDiferido[]
  eventosRepaso EventoRepasoDiferido[]
  solicitudAltaInstitucion SolicitudAltaInstitucion?
  id                        String                        @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  nombre                    String                        @db.VarChar(255)
  correo                    String                        @unique @db.VarChar(255)
  contrasenaHash            String
  // Cuando el admin crea la cuenta manualmente con una contraseña
  // temporal (punto 12: institución vía panel de admin), esta bandera
  // queda en true para forzar que la cambie en su primer login. Se
  // apaga sola cuando el usuario la cambia por una propia.
  debeCambiarContrasena     Boolean?                      @default(false)
  rol                       RolUsuario?                   @default(ESTUDIANTE)
  xpTotal                   Int?                          @default(0)
  fechaCreacion             DateTime?                     @default(now()) @db.Timestamp(6)
  fechaVencimientoPlan      DateTime?                     @db.Timestamp(6)
  // Calendario ICFES del estudiante individual (A o B). Solo aplica
  // cuando no pertenece a institución; si pertenece, hereda el de su
  // colegio. Punto 6.
  calendarioIcfes           CalendarioTipo?               @default(A)
  // Verificación de correo (punto 7): evita que alguien reinicie la
  // prueba gratis de 3 días registrándose con correos falsos.
  correoVerificado          Boolean?                      @default(false)
  tokenVerificacion         String?                       @unique @db.VarChar(255)
  tokenVerificacionExpira   DateTime?                     @db.Timestamp(6)
  // Recuperación de contraseña (punto 8): token de un solo uso y vida
  // corta para que quien olvidó su contraseña elija una nueva sin
  // necesitar acceso previo a la cuenta.
  tokenRecuperacion         String?                       @unique @db.VarChar(255)
  tokenRecuperacionExpira   DateTime?                     @db.Timestamp(6)
  institucionId             String?                       @db.Uuid
  fotoPerfil                String?
  descripcion               String?
  tutorialEstudianteVersion Int                           @default(0)
  tutorialProfesorVersion   Int                           @default(0)
  // El grado personaliza contenido y estadísticas, pero no cambia el
  // producto ni el precio del acceso individual.
  grado                     Grado?
  ClaseEstudiante           ClaseEstudiante[]
  Institucion               Institucion?                  @relation(fields: [institucionId], references: [id], onUpdate: NoAction, map: "fk_institucion")
  resultados                ResultadoSimulacro[]
  intentosSimulacro         IntentoSimulacro[]
  historialRespuestas       HistorialRespuesta[]
  pomodorosRegistrados       PomodoroRegistrado[]
  diagnosticoInicial        DiagnosticoInicial?
  progresotemas             ProgresoTema[]
  PagoOrden                 PagoOrden[]
  codigoReferido            String?                       @unique @db.VarChar(12)
  saldoReferidosCop         Int                           @default(0)
  referidosEnviados         Referido[]                    @relation("Referidor")
  referidoRecibido          Referido?                     @relation("Referido")
  planesEstudio             PlanEstudioSemanal[]
  anunciosLeidos            AnuncioLectura[]
  anunciosCreados           Anuncio[]                     @relation("AutorAnuncio")
  batallasRetadas           Batalla[]                     @relation("RetadorBatalla")
  batallasComoRival         Batalla[]                     @relation("RivalBatalla")
  batallasGanadas           Batalla[]                     @relation("GanadorBatalla")
  participacionesBatalla    BatallaParticipante[]
  respuestasBatalla         BatallaRespuesta[]
  estadisticaBatalla        BatallaEstadistica?
  bloqueosBatallaCreados    BatallaBloqueo[]              @relation("BloqueadorBatalla")
  bloqueosBatallaRecibidos  BatallaBloqueo[]              @relation("BloqueadoBatalla")
  reportesBatallaCreados    BatallaReporte[]              @relation("ReportanteBatalla")
  reportesBatallaRecibidos  BatallaReporte[]              @relation("ReportadoBatalla")
  partidasTiraAflojaA       PartidaTiraAfloja[]           @relation("JugadorATiraAfloja")
  partidasTiraAflojaB       PartidaTiraAfloja[]           @relation("JugadorBTiraAfloja")
  partidasTiraAflojaGanadas PartidaTiraAfloja[]           @relation("GanadorTiraAfloja")
  respuestasTiraAfloja      TiraAflojaRespuesta[]
  intentosTriviaRush        IntentoTriviaRush[]
  intentosGuardian          IntentoGuardian[]
  intentosCima              IntentoCima[]
  intentosRescateEstrellas  IntentoRescateEstrellas[]
  intentosEscudoConocimiento IntentoEscudoConocimiento[]
  concesionesJuego          ConcesionRecompensaJuego[]
  cuadernoErrores           CuadernoError[]
  membresiaInstitucion      MiembroInstitucion?
  solicitudesInstitucion    SolicitudIngresoInstitucion[] @relation("SolicitanteInstitucion")
  solicitudesRevisadas      SolicitudIngresoInstitucion[] @relation("RevisorInstitucion")
  invitacionesCreadas       InvitacionInstitucion[]       @relation("CreadorInvitacionInstitucion")
  invitacionesAceptadas     InvitacionInstitucion[]       @relation("ReceptorInvitacionInstitucion")
  auditoriasCreadas         AuditoriaInstitucion[]        @relation("ActorAuditoriaInstitucion")
  auditoriasRecibidas       AuditoriaInstitucion[]        @relation("AfectadoAuditoriaInstitucion")
}
```

## enum RolUsuario

Fuente: backend/prisma/schema.prisma:229

```prisma
enum RolUsuario {
  ESTUDIANTE
  PROFESOR
  ADMIN
}
```

## enum EstadoAltaInstitucion

Fuente: backend/prisma/schema.prisma:235

```prisma
enum EstadoAltaInstitucion {
  PENDIENTE
  REQUIERE_INFORMACION
  APROBADA
  RECHAZADA
  SUSPENDIDA
  LEGADO_EN_REVISION
}
```

## model SolicitudAltaInstitucion

Fuente: backend/prisma/schema.prisma:244

```prisma
model SolicitudAltaInstitucion {
  id String @id @default(uuid()) @db.Uuid
  solicitanteId String? @unique @db.Uuid
  solicitante Usuario? @relation(fields: [solicitanteId], references: [id], onDelete: SetNull)
  institucionId String? @unique @db.Uuid
  institucion Institucion? @relation(fields: [institucionId], references: [id], onDelete: Restrict)
  nombre String @db.VarChar(120)
  nombreNormalizado String @db.VarChar(120)
  ciudad String @db.VarChar(120)
  ciudadNormalizada String @db.VarChar(120)
  correoInstitucional String @db.VarChar(254)
  contacto String @db.VarChar(120)
  referenciaUrl String? @db.VarChar(500)
  evidencia String @db.VarChar(2000)
  estado EstadoAltaInstitucion @default(PENDIENTE)
  revision Int @default(1)
  mensajeSolicitante String @default("") @db.VarChar(1000)
  historial Json @default("[]")
  creadoEn DateTime @default(now()) @db.Timestamp(3)
  actualizadoEn DateTime @default(now()) @updatedAt @db.Timestamp(3)

  @@index([estado, actualizadoEn])
  @@index([nombreNormalizado, ciudadNormalizada])
}
```

## enum RolMembresiaInstitucion

Fuente: backend/prisma/schema.prisma:269

```prisma
enum RolMembresiaInstitucion {
  PROPIETARIO
  ADMINISTRADOR
  PROFESOR
}
```

## enum EstadoSolicitudIngresoInstitucion

Fuente: backend/prisma/schema.prisma:275

```prisma
enum EstadoSolicitudIngresoInstitucion {
  PENDIENTE
  APROBADA
  RECHAZADA
  CANCELADA
}
```

## enum EstadoInvitacionInstitucion

Fuente: backend/prisma/schema.prisma:282

```prisma
enum EstadoInvitacionInstitucion {
  PENDIENTE
  ACEPTADA
  RECHAZADA
  CANCELADA
  EXPIRADA
}
```

## model MiembroInstitucion

Fuente: backend/prisma/schema.prisma:290

```prisma
model MiembroInstitucion {
  id                 String                  @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  institucionId      String                  @db.Uuid
  usuarioId          String                  @unique @db.Uuid
  rol                RolMembresiaInstitucion @default(PROFESOR)
  fechaCreacion      DateTime                @default(now()) @db.Timestamp(6)
  fechaActualizacion DateTime                @default(now()) @updatedAt @db.Timestamp(6)
  institucion        Institucion             @relation(fields: [institucionId], references: [id], onDelete: Cascade)
  usuario            Usuario                 @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  clasesAsignadas    ClaseProfesor[]
  codigosGrupo       CodigoTemporalGrupo[]

  @@unique([institucionId, usuarioId])
  @@index([institucionId, rol])
}
```

## model SolicitudIngresoInstitucion

Fuente: backend/prisma/schema.prisma:306

```prisma
model SolicitudIngresoInstitucion {
  id                 String                            @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  institucionId      String                            @db.Uuid
  solicitanteId      String                            @db.Uuid
  estado             EstadoSolicitudIngresoInstitucion @default(PENDIENTE)
  mensaje            String?                           @db.VarChar(500)
  revisadoPorId      String?                           @db.Uuid
  fechaCreacion      DateTime                          @default(now()) @db.Timestamp(6)
  fechaActualizacion DateTime                          @default(now()) @updatedAt @db.Timestamp(6)
  institucion        Institucion                       @relation(fields: [institucionId], references: [id], onDelete: Cascade)
  solicitante        Usuario                           @relation("SolicitanteInstitucion", fields: [solicitanteId], references: [id], onDelete: Cascade)
  revisadoPor        Usuario?                          @relation("RevisorInstitucion", fields: [revisadoPorId], references: [id], onDelete: SetNull)

  @@index([institucionId, estado, fechaCreacion])
  @@index([solicitanteId, estado, fechaCreacion])
}
```

## model InvitacionInstitucion

Fuente: backend/prisma/schema.prisma:323

```prisma
model InvitacionInstitucion {
  id                 String                      @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  institucionId      String                      @db.Uuid
  correo             String                      @db.VarChar(255)
  rol                RolMembresiaInstitucion     @default(PROFESOR)
  estado             EstadoInvitacionInstitucion @default(PENDIENTE)
  creadoPorId        String                      @db.Uuid
  aceptadoPorId      String?                     @db.Uuid
  fechaExpiracion    DateTime                    @db.Timestamp(6)
  fechaCreacion      DateTime                    @default(now()) @db.Timestamp(6)
  fechaActualizacion DateTime                    @default(now()) @updatedAt @db.Timestamp(6)
  institucion        Institucion                 @relation(fields: [institucionId], references: [id], onDelete: Cascade)
  creadoPor          Usuario                     @relation("CreadorInvitacionInstitucion", fields: [creadoPorId], references: [id], onDelete: Cascade)
  aceptadoPor        Usuario?                    @relation("ReceptorInvitacionInstitucion", fields: [aceptadoPorId], references: [id], onDelete: SetNull)

  @@index([institucionId, estado, fechaCreacion])
  @@index([correo, estado, fechaExpiracion])
}
```

## model AuditoriaInstitucion

Fuente: backend/prisma/schema.prisma:342

```prisma
model AuditoriaInstitucion {
  id            String      @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  institucionId String      @db.Uuid
  accion        String      @db.VarChar(60)
  actorId       String?     @db.Uuid
  afectadoId    String?     @db.Uuid
  detalle       Json?
  fechaCreacion DateTime    @default(now()) @db.Timestamp(6)
  institucion   Institucion @relation(fields: [institucionId], references: [id], onDelete: Cascade)
  actor         Usuario?    @relation("ActorAuditoriaInstitucion", fields: [actorId], references: [id], onDelete: SetNull)
  afectado      Usuario?    @relation("AfectadoAuditoriaInstitucion", fields: [afectadoId], references: [id], onDelete: SetNull)

  @@index([institucionId, fechaCreacion])
  @@index([actorId, fechaCreacion])
}
```

## enum LineaInteres

Fuente: backend/prisma/schema.prisma:360

```prisma
enum LineaInteres {
  ONCE
  BACHILLERATO
}
```

## model LeadVentas

Fuente: backend/prisma/schema.prisma:365

```prisma
model LeadVentas {
  id                     String       @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  nombreColegio          String       @db.VarChar(255)
  nombreContacto         String       @db.VarChar(255)
  correo                 String       @db.VarChar(255)
  telefono               String?      @db.VarChar(50)
  ciudad                 String?      @db.VarChar(100)
  linea                  LineaInteres
  plan                   String       @db.VarChar(50)
  numeroEstudiantesAprox Int?
  mensaje                String?      @db.Text
  atendido               Boolean      @default(false)
  fechaCreacion          DateTime     @default(now()) @db.Timestamp(6)

  @@index([atendido, fechaCreacion])
}
```

## model ConfiguracionSoporte

Fuente: backend/prisma/schema.prisma:382

```prisma
model ConfiguracionSoporte {
  id                 String   @id @default("principal") @db.VarChar(30)
  numeroWhatsapp     String?  @db.VarChar(15)
  mensajeWhatsapp    String   @default("Hola, necesito ayuda con SaberPlus.") @db.VarChar(300)
  activo             Boolean  @default(false)
  fechaActualizacion DateTime @default(now()) @updatedAt @db.Timestamp(6)
}
```

## enum TipoAnuncio

Fuente: backend/prisma/schema.prisma:390

```prisma
enum TipoAnuncio {
  INFORMACION
  IMPORTANTE
  EVENTO
}
```

## enum AudienciaAnuncio

Fuente: backend/prisma/schema.prisma:396

```prisma
enum AudienciaAnuncio {
  TODOS
  ESTUDIANTES
  PROFESORES
}
```

## model Anuncio

Fuente: backend/prisma/schema.prisma:402

```prisma
model Anuncio {
  id            String           @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  titulo        String           @db.VarChar(120)
  contenido     String           @db.Text
  tipo          TipoAnuncio      @default(INFORMACION)
  audiencia     AudienciaAnuncio @default(TODOS)
  fechaInicio   DateTime         @default(now()) @db.Timestamp(6)
  fechaFin      DateTime?        @db.Timestamp(6)
  activo        Boolean          @default(true)
  destacado     Boolean          @default(false)
  fechaCreacion DateTime         @default(now()) @db.Timestamp(6)
  fechaEdicion  DateTime         @default(now()) @updatedAt @db.Timestamp(6)
  institucionId String?          @db.Uuid
  creadoPorId   String?          @db.Uuid
  institucion   Institucion?     @relation(fields: [institucionId], references: [id], onDelete: Cascade)
  creadoPor     Usuario?         @relation("AutorAnuncio", fields: [creadoPorId], references: [id], onDelete: SetNull)
  lecturas      AnuncioLectura[]

  @@index([activo, fechaInicio, fechaFin])
  @@index([audiencia, destacado])
  @@index([institucionId, activo, fechaInicio])
  @@index([creadoPorId])
}
```

## model AnuncioLectura

Fuente: backend/prisma/schema.prisma:426

```prisma
model AnuncioLectura {
  anuncioId    String   @db.Uuid
  usuarioId    String   @db.Uuid
  fechaLectura DateTime @default(now()) @db.Timestamp(6)
  anuncio      Anuncio  @relation(fields: [anuncioId], references: [id], onDelete: Cascade)
  usuario      Usuario  @relation(fields: [usuarioId], references: [id], onDelete: Cascade)

  @@id([anuncioId, usuarioId])
  @@index([usuarioId, fechaLectura])
}
```

## enum EstadoPago

Fuente: backend/prisma/schema.prisma:439

```prisma
enum EstadoPago {
  PENDIENTE
  APROBADA
  RECHAZADA
  PENDIENTE_BANCO
  FALLIDA
}
```

## enum EstadoReferido

Fuente: backend/prisma/schema.prisma:447

```prisma
enum EstadoReferido {
  REGISTRADO
  RECOMPENSADO
}
```

## enum TipoPlan

Fuente: backend/prisma/schema.prisma:458

```prisma
enum TipoPlan {
  MENSUAL
  TEMPORADA_A
  TEMPORADA_B
}
```

## model PagoOrden

Fuente: backend/prisma/schema.prisma:464

```prisma
model PagoOrden {
  id                     String          @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  factura                String          @unique @db.VarChar(50)
  usuarioId              String          @db.Uuid
  Usuario                Usuario         @relation(fields: [usuarioId], references: [id], onDelete: Cascade, onUpdate: NoAction, map: "fk_pagoorden_usuario")
  grado                  Grado?
  tipoPlan               TipoPlan        @default(MENSUAL)
  calendarioIcfes        CalendarioTipo?
  fechaVencimientoAcceso DateTime?       @db.Timestamp(6)
  monto                  Int
  montoOriginal          Int?
  creditoReferidosUsado  Int             @default(0)
  moneda                 String          @default("COP") @db.VarChar(10)
  estado                 EstadoPago      @default(PENDIENTE)
  cuponId                String?         @db.Uuid
  Cupon                  Cupon?          @relation(fields: [cuponId], references: [id], onDelete: SetNull, onUpdate: NoAction, map: "fk_pagoorden_cupon")
  refPayco               String?         @db.VarChar(50)
  transaccionId          String?         @unique @db.VarChar(100)
  motivoRespuesta        String?         @db.Text
  fechaCreacion          DateTime        @default(now()) @db.Timestamp(6)
  fechaActualizacion     DateTime        @default(now()) @updatedAt @db.Timestamp(6)
  referidoRecompensado   Referido?

  @@index([usuarioId])
  @@index([cuponId])
}
```

## model Referido

Fuente: backend/prisma/schema.prisma:491

```prisma
model Referido {
  id              String         @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  referidorId     String         @db.Uuid
  referidoId      String         @unique @db.Uuid
  codigoUsado     String         @db.VarChar(12)
  estado          EstadoReferido @default(REGISTRADO)
  recompensaCop   Int            @default(0)
  ordenPagoId     String?        @unique @db.Uuid
  fechaRegistro   DateTime       @default(now()) @db.Timestamp(6)
  fechaRecompensa DateTime?      @db.Timestamp(6)
  referidor       Usuario        @relation("Referidor", fields: [referidorId], references: [id], onDelete: Cascade)
  referido        Usuario        @relation("Referido", fields: [referidoId], references: [id], onDelete: Cascade)
  ordenPago       PagoOrden?     @relation(fields: [ordenPagoId], references: [id], onDelete: SetNull)

  @@index([referidorId, estado])
}
```

## model Cupon

Fuente: backend/prisma/schema.prisma:508

```prisma
model Cupon {
  id                  String      @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  codigo              String      @unique @db.VarChar(50)
  titulo              String?     @db.VarChar(120)
  esAutomatica        Boolean     @default(false)
  porcentajeDescuento Int
  tipoPlan            TipoPlan?
  fechaExpiracion     DateTime    @db.Timestamp(6)
  usosMaximos         Int?
  usosActuales        Int         @default(0)
  activo              Boolean     @default(true)
  fechaCreacion       DateTime    @default(now()) @db.Timestamp(6)
  PagoOrden           PagoOrden[]

  @@index([esAutomatica, activo, fechaExpiracion], map: "Cupon_promocion_activa_idx")
}
```

## enum AreaIcfes

Fuente: backend/prisma/schema.prisma:527

```prisma
enum AreaIcfes {
  LECTURA_CRITICA
  MATEMATICAS
  SOCIALES_CIUDADANAS
  CIENCIAS_NATURALES
  INGLES
}
```

## enum TipoActividadPlan

Fuente: backend/prisma/schema.prisma:535

```prisma
enum TipoActividadPlan {
  ESTUDIO
  SIMULACRO
  DESCANSO
  EXAMEN
}
```

## enum Dificultad

Fuente: backend/prisma/schema.prisma:542

```prisma
enum Dificultad {
  BASICO
  MEDIO
  AVANZADO
}
```

## enum TipoInteractivo

Fuente: backend/prisma/schema.prisma:548

```prisma
enum TipoInteractivo {
  CLOZE
}
```

## enum EstadoContenido

Fuente: backend/prisma/schema.prisma:552

```prisma
enum EstadoContenido {
  BORRADOR
  EN_REVISION
  PUBLICADO
  ARCHIVADO
}
```

## model Tema

Fuente: backend/prisma/schema.prisma:559

```prisma
model Tema {
  id                 String          @id @default(uuid())
  nombre             String
  area               AreaIcfes
  estadoContenido    EstadoContenido @default(BORRADOR)
  fechaPublicacion   DateTime?       @db.Timestamp(6)
  fechaActualizacion DateTime        @default(now()) @updatedAt @db.Timestamp(6)
  subtemas           Subtema[]

  @@index([estadoContenido, area])
}
```

## model Subtema

Fuente: backend/prisma/schema.prisma:571

```prisma
model Subtema {
  id                    String                 @id @default(uuid())
  nombre                String
  temaId                String
  contenido             String?                @db.Text
  videoUrl              String?
  imagenUrl             String?
  tipoInteractivo       TipoInteractivo?
  datosInteractivo      Json?
  estadoContenido       EstadoContenido        @default(BORRADOR)
  fechaPublicacion      DateTime?              @db.Timestamp(6)
  fechaActualizacion    DateTime               @default(now()) @updatedAt @db.Timestamp(6)
  tema                  Tema                   @relation(fields: [temaId], references: [id], onDelete: Cascade)
  preguntas             Pregunta[]
  progresotemas         ProgresoTema[]
  actividadesPlan       PlanEstudioActividad[]
  basesAprendizaje      RelacionAprendizaje[]  @relation("DestinoAprendizaje")
  siguientesAprendizaje RelacionAprendizaje[]  @relation("BaseAprendizaje")

  @@index([estadoContenido, temaId])
}
```

## model MapaAprendizaje

Fuente: backend/prisma/schema.prisma:593

```prisma
model MapaAprendizaje {
  area           AreaIcfes             @id
  revision       Int                   @default(0)
  actualizadoEn  DateTime              @default(now()) @updatedAt @db.Timestamp(3)
  actualizadoPor String?
  relaciones     RelacionAprendizaje[]
}
```

## model RelacionAprendizaje

Fuente: backend/prisma/schema.prisma:601

```prisma
model RelacionAprendizaje {
  area      AreaIcfes
  previoId  String
  destinoId String
  mapa      MapaAprendizaje @relation(fields: [area], references: [area], onDelete: Cascade)
  previo    Subtema         @relation("BaseAprendizaje", fields: [previoId], references: [id], onDelete: Cascade)
  destino   Subtema         @relation("DestinoAprendizaje", fields: [destinoId], references: [id], onDelete: Cascade)

  @@id([previoId, destinoId])
  @@index([area, destinoId])
  @@index([destinoId])
}
```

## model Pregunta

Fuente: backend/prisma/schema.prisma:614

```prisma
model Pregunta {
  id                     String                  @id @default(uuid())
  enunciado              String                  @db.Text
  explicacion            String?                 @db.Text
  imagenUrl              String?
  dificultad             Dificultad              @default(MEDIO)
  porcentajeAciertos     Float                   @default(0.0)
  tiempoPromedioSegundos Int                     @default(0)
  subtemaId              String
  casoId                 String?
  ordenEnCaso            Int?
  huellaContenido        String?                 @db.VarChar(64)
  estadoContenido        EstadoContenido         @default(BORRADOR)
  fechaPublicacion       DateTime?               @db.Timestamp(6)
  fechaActualizacion     DateTime                @default(now()) @updatedAt @db.Timestamp(6)
  subtema                Subtema                 @relation(fields: [subtemaId], references: [id])
  caso                   CasoPregunta?           @relation(fields: [casoId], references: [id], onDelete: SetNull)
  respuestas             Respuesta[]
  historialRespuestas    HistorialRespuesta[]
  respuestasBatalla      BatallaRespuesta[]
  preguntasBatalla       BatallaPregunta[]
  preguntasTiraAfloja    TiraAflojaPregunta[]
  respuestasTiraAfloja   TiraAflojaRespuesta[]
  partidasTiraAfloja     PartidaTiraAfloja[]     @relation("PreguntaActualTiraAfloja")
  preguntasTriviaRush    TriviaRushPregunta[]
  respuestasTriviaRush   TriviaRushRespuesta[]
  intentosTriviaActual   IntentoTriviaRush[]     @relation("PreguntaActualTriviaRush")
  potenciadoresTrivia    TriviaRushPotenciador[]
  cuadernoErrores        CuadernoError[]

  @@index([casoId, ordenEnCaso])
  @@index([huellaContenido, estadoContenido])
  @@index([estadoContenido, subtemaId])
}
```

## model CasoPregunta

Fuente: backend/prisma/schema.prisma:649

```prisma
model CasoPregunta {
  id                 String          @id @default(uuid())
  titulo             String?
  contexto           String          @db.Text
  imagenUrl          String?
  area               AreaIcfes
  fechaCreacion      DateTime        @default(now())
  estadoContenido    EstadoContenido @default(BORRADOR)
  fechaPublicacion   DateTime?       @db.Timestamp(6)
  fechaActualizacion DateTime        @default(now()) @updatedAt @db.Timestamp(6)
  preguntas          Pregunta[]

  @@index([area, fechaCreacion])
  @@index([estadoContenido, area])
}
```

## model Respuesta

Fuente: backend/prisma/schema.prisma:665

```prisma
model Respuesta {
  id                    String                @id @default(uuid())
  texto                 String                @db.Text
  explicacion           String?               @db.Text
  esCorrecta            Boolean               @default(false)
  preguntaId            String
  pregunta              Pregunta              @relation(fields: [preguntaId], references: [id], onDelete: Cascade)
  seleccionesBatalla    BatallaRespuesta[]
  seleccionesTiraAfloja TiraAflojaRespuesta[]
  seleccionesTriviaRush TriviaRushRespuesta[]
}
```

## enum ModoBatalla

Fuente: backend/prisma/schema.prisma:679

```prisma
enum ModoBatalla {
  CARRERA_FANTASMA
  DUELO_RELAMPAGO
  SUPERVIVENCIA
}
```

## enum EstadoBatalla

Fuente: backend/prisma/schema.prisma:685

```prisma
enum EstadoBatalla {
  BUSCANDO
  PENDIENTE
  ACTIVA
  FINALIZADA
  EXPIRADA
  CANCELADA
}
```

## enum EstadoParticipanteBatalla

Fuente: backend/prisma/schema.prisma:694

```prisma
enum EstadoParticipanteBatalla {
  INVITADO
  LISTO
  EN_JUEGO
  FINALIZADO
}
```

## enum ResultadoParticipanteBatalla

Fuente: backend/prisma/schema.prisma:701

```prisma
enum ResultadoParticipanteBatalla {
  PENDIENTE
  GANADA
  PERDIDA
  EMPATE
}
```

## enum MotivoReporteBatalla

Fuente: backend/prisma/schema.prisma:708

```prisma
enum MotivoReporteBatalla {
  CONDUCTA_INAPROPIADA
  NOMBRE_INAPROPIADO
  TRAMPA
  OTRO
}
```

## enum EstadoReporteBatalla

Fuente: backend/prisma/schema.prisma:715

```prisma
enum EstadoReporteBatalla {
  RECIBIDO
  EN_REVISION
  RESUELTO
  DESCARTADO
}
```

## model Batalla

Fuente: backend/prisma/schema.prisma:722

```prisma
model Batalla {
  id                String                @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  modo              ModoBatalla
  estado            EstadoBatalla         @default(BUSCANDO)
  area              AreaIcfes?
  retadorId         String                @db.Uuid
  rivalId           String?               @db.Uuid
  ganadorId         String?               @db.Uuid
  codigoInvitacion  String?               @unique @db.VarChar(8)
  xpLiquidadoEn     DateTime?             @db.Timestamp(6)
  expiraEn          DateTime              @db.Timestamp(6)
  fechaCreacion     DateTime              @default(now()) @db.Timestamp(6)
  fechaActivacion   DateTime?             @db.Timestamp(6)
  fechaFinalizacion DateTime?             @db.Timestamp(6)
  retador           Usuario               @relation("RetadorBatalla", fields: [retadorId], references: [id], onDelete: Cascade)
  rival             Usuario?              @relation("RivalBatalla", fields: [rivalId], references: [id], onDelete: SetNull)
  ganador           Usuario?              @relation("GanadorBatalla", fields: [ganadorId], references: [id], onDelete: SetNull)
  participantes     BatallaParticipante[]
  preguntas         BatallaPregunta[]
  respuestas        BatallaRespuesta[]
  reportes          BatallaReporte[]

  @@index([estado, modo, area, expiraEn])
  @@index([retadorId, fechaCreacion])
  @@index([rivalId, fechaCreacion])
  @@index([ganadorId])
}
```

## model BatallaPregunta

Fuente: backend/prisma/schema.prisma:750

```prisma
model BatallaPregunta {
  batallaId     String   @db.Uuid
  preguntaId    String
  orden         Int
  opcionesOrden Json
  batalla       Batalla  @relation(fields: [batallaId], references: [id], onDelete: Cascade)
  pregunta      Pregunta @relation(fields: [preguntaId], references: [id], onDelete: Restrict)

  @@id([batallaId, preguntaId])
  @@unique([batallaId, orden])
  @@index([preguntaId])
}
```

## model BatallaParticipante

Fuente: backend/prisma/schema.prisma:763

```prisma
model BatallaParticipante {
  batallaId           String                       @db.Uuid
  usuarioId           String                       @db.Uuid
  estado              EstadoParticipanteBatalla    @default(LISTO)
  resultado           ResultadoParticipanteBatalla @default(PENDIENTE)
  iniciadoEn          DateTime?                    @db.Timestamp(6)
  finalizadoEn        DateTime?                    @db.Timestamp(6)
  respuestasCorrectas Int                          @default(0)
  tiempoTotalSegundos Int                          @default(0)
  vidasRestantes      Int?
  xpElegible          Boolean                      @default(true)
  xpGanado            Int                          @default(0)
  batalla             Batalla                      @relation(fields: [batallaId], references: [id], onDelete: Cascade)
  usuario             Usuario                      @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  respuestas          BatallaRespuesta[]           @relation("RespuestasParticipanteBatalla")

  @@id([batallaId, usuarioId])
  @@index([usuarioId, finalizadoEn])
  @@index([usuarioId, resultado, finalizadoEn])
}
```

## model BatallaRespuesta

Fuente: backend/prisma/schema.prisma:784

```prisma
model BatallaRespuesta {
  id                      String              @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  batallaId               String              @db.Uuid
  usuarioId               String              @db.Uuid
  preguntaId              String
  respuestaSeleccionadaId String
  orden                   Int
  esCorrecta              Boolean
  tiempoRespuestaSegundos Int
  respondidaEn            DateTime            @default(now()) @db.Timestamp(6)
  batalla                 Batalla             @relation(fields: [batallaId], references: [id], onDelete: Cascade)
  usuario                 Usuario             @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  pregunta                Pregunta            @relation(fields: [preguntaId], references: [id], onDelete: Restrict)
  respuestaSeleccionada   Respuesta           @relation(fields: [respuestaSeleccionadaId], references: [id], onDelete: Restrict)
  participante            BatallaParticipante @relation("RespuestasParticipanteBatalla", fields: [batallaId, usuarioId], references: [batallaId, usuarioId], onDelete: Cascade)

  @@unique([batallaId, usuarioId, preguntaId])
  @@unique([batallaId, usuarioId, orden])
  @@index([batallaId, usuarioId, respondidaEn])
  @@index([preguntaId])
}
```

## model BatallaEstadistica

Fuente: backend/prisma/schema.prisma:806

```prisma
model BatallaEstadistica {
  usuarioId            String   @id @db.Uuid
  batallasJugadas      Int      @default(0)
  victorias            Int      @default(0)
  derrotas             Int      @default(0)
  empates              Int      @default(0)
  rachaVictoriasActual Int      @default(0)
  mejorRachaVictorias  Int      @default(0)
  victoriasPerfectas   Int      @default(0)
  xpBatallas           Int      @default(0)
  fechaActualizacion   DateTime @default(now()) @updatedAt @db.Timestamp(6)
  usuario              Usuario  @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
}
```

## model BatallaBloqueo

Fuente: backend/prisma/schema.prisma:820

```prisma
model BatallaBloqueo {
  id            String   @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  bloqueadorId  String   @db.Uuid
  bloqueadoId   String   @db.Uuid
  fechaCreacion DateTime @default(now()) @db.Timestamp(6)
  bloqueador    Usuario  @relation("BloqueadorBatalla", fields: [bloqueadorId], references: [id], onDelete: Cascade)
  bloqueado     Usuario  @relation("BloqueadoBatalla", fields: [bloqueadoId], references: [id], onDelete: Cascade)

  @@unique([bloqueadorId, bloqueadoId])
  @@index([bloqueadoId, fechaCreacion])
}
```

## model BatallaReporte

Fuente: backend/prisma/schema.prisma:832

```prisma
model BatallaReporte {
  id            String               @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  batallaId     String               @db.Uuid
  reportanteId  String               @db.Uuid
  reportadoId   String               @db.Uuid
  motivo        MotivoReporteBatalla
  detalle       String?              @db.VarChar(500)
  estado        EstadoReporteBatalla @default(RECIBIDO)
  fechaCreacion DateTime             @default(now()) @db.Timestamp(6)
  batalla       Batalla              @relation(fields: [batallaId], references: [id], onDelete: Cascade)
  reportante    Usuario              @relation("ReportanteBatalla", fields: [reportanteId], references: [id], onDelete: Cascade)
  reportado     Usuario              @relation("ReportadoBatalla", fields: [reportadoId], references: [id], onDelete: Cascade)

  @@unique([batallaId, reportanteId])
  @@index([reportadoId, estado, fechaCreacion])
}
```

## enum EstadoPartidaTiraAfloja

Fuente: backend/prisma/schema.prisma:851

```prisma
enum EstadoPartidaTiraAfloja {
  BUSCANDO
  PREPARANDO
  ACTIVA
  FINALIZADA
  CANCELADA
  EXPIRADA
}
```

## enum ResultadoPartidaTiraAfloja

Fuente: backend/prisma/schema.prisma:860

```prisma
enum ResultadoPartidaTiraAfloja {
  JUGADOR_A
  JUGADOR_B
  EMPATE
  CANCELADA
}
```

## enum TipoEventoTiraAfloja

Fuente: backend/prisma/schema.prisma:867

```prisma
enum TipoEventoTiraAfloja {
  BUSQUEDA_INICIADA
  EMPAREJADA
  RONDA_INICIADA
  RONDA_RESUELTA
  FINALIZADA
  ABANDONO
  CANCELADA
}
```

## model PartidaTiraAfloja

Fuente: backend/prisma/schema.prisma:877

```prisma
model PartidaTiraAfloja {
  id                  String                      @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  estado              EstadoPartidaTiraAfloja     @default(BUSCANDO)
  resultado           ResultadoPartidaTiraAfloja?
  area                AreaIcfes?
  jugadorAId          String                      @db.Uuid
  jugadorBId          String?                     @db.Uuid
  ganadorId           String?                     @db.Uuid
  posicionCuerda      Int                         @default(0)
  rondaActual         Int                         @default(0)
  version             Int                         @default(0)
  versionReglas       Int                         @default(1)
  listoA              Boolean                     @default(false)
  listoB              Boolean                     @default(false)
  preguntaActualId    String?
  rondaIniciaEn       DateTime?                   @db.Timestamp(6)
  rondaVenceEn        DateTime?                   @db.Timestamp(6)
  expiraEn            DateTime                    @db.Timestamp(6)
  fechaCreacion       DateTime                    @default(now()) @db.Timestamp(6)
  fechaEmparejamiento DateTime?                   @db.Timestamp(6)
  fechaFinalizacion   DateTime?                   @db.Timestamp(6)
  jugadorA            Usuario                     @relation("JugadorATiraAfloja", fields: [jugadorAId], references: [id], onDelete: Cascade)
  jugadorB            Usuario?                    @relation("JugadorBTiraAfloja", fields: [jugadorBId], references: [id], onDelete: SetNull)
  ganador             Usuario?                    @relation("GanadorTiraAfloja", fields: [ganadorId], references: [id], onDelete: SetNull)
  preguntaActual      Pregunta?                   @relation("PreguntaActualTiraAfloja", fields: [preguntaActualId], references: [id], onDelete: SetNull)
  preguntas           TiraAflojaPregunta[]
  respuestas          TiraAflojaRespuesta[]
  eventos             TiraAflojaEvento[]

  @@index([estado, area, expiraEn])
  @@index([jugadorAId, estado])
  @@index([jugadorBId, estado])
  @@index([ganadorId])
}
```

## model TiraAflojaPregunta

Fuente: backend/prisma/schema.prisma:912

```prisma
model TiraAflojaPregunta {
  partidaId     String            @db.Uuid
  preguntaId    String
  orden         Int
  opcionesOrden Json
  partida       PartidaTiraAfloja @relation(fields: [partidaId], references: [id], onDelete: Cascade)
  pregunta      Pregunta          @relation(fields: [preguntaId], references: [id], onDelete: Restrict)

  @@id([partidaId, preguntaId])
  @@unique([partidaId, orden])
  @@index([preguntaId])
}
```

## model TiraAflojaRespuesta

Fuente: backend/prisma/schema.prisma:925

```prisma
model TiraAflojaRespuesta {
  id                      String            @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  partidaId               String            @db.Uuid
  ronda                   Int
  usuarioId               String            @db.Uuid
  preguntaId              String
  respuestaSeleccionadaId String
  esCorrecta              Boolean
  recibidaEn              DateTime          @default(now()) @db.Timestamp(6)
  claveIdempotencia       String            @unique @db.Uuid
  partida                 PartidaTiraAfloja @relation(fields: [partidaId], references: [id], onDelete: Cascade)
  usuario                 Usuario           @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  pregunta                Pregunta          @relation(fields: [preguntaId], references: [id], onDelete: Restrict)
  respuestaSeleccionada   Respuesta         @relation(fields: [respuestaSeleccionadaId], references: [id], onDelete: Restrict)

  @@unique([partidaId, ronda, usuarioId])
  @@index([partidaId, ronda, recibidaEn])
  @@index([usuarioId, recibidaEn])
  @@index([preguntaId])
}
```

## model TiraAflojaEvento

Fuente: backend/prisma/schema.prisma:946

```prisma
model TiraAflojaEvento {
  id        String               @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  partidaId String               @db.Uuid
  version   Int
  tipo      TipoEventoTiraAfloja
  datos     Json
  fecha     DateTime             @default(now()) @db.Timestamp(6)
  partida   PartidaTiraAfloja    @relation(fields: [partidaId], references: [id], onDelete: Cascade)

  @@unique([partidaId, version])
  @@index([partidaId, fecha])
}
```

## enum EstadoIntentoTriviaRush

Fuente: backend/prisma/schema.prisma:961

```prisma
enum EstadoIntentoTriviaRush {
  ACTIVO
  FINALIZADO
  EXPIRADO
  ABANDONADO
}
```

## enum TipoPotenciadorTriviaRush

Fuente: backend/prisma/schema.prisma:968

```prisma
enum TipoPotenciadorTriviaRush {
  TIEMPO_EXTRA
  CINCUENTA_CINCUENTA
  ESCUDO_COMBO
  SALTAR
  SEGUNDA_OPORTUNIDAD
}
```

## enum EstadoConcesionRecompensa

Fuente: backend/prisma/schema.prisma:976

```prisma
enum EstadoConcesionRecompensa {
  DISPONIBLE
  CONSUMIDA
  EXPIRADA
}
```

## model IntentoTriviaRush

Fuente: backend/prisma/schema.prisma:982

```prisma
model IntentoTriviaRush {
  id                       String                  @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  usuarioId                String                  @db.Uuid
  estado                   EstadoIntentoTriviaRush @default(ACTIVO)
  areas                    AreaIcfes[]
  duracionBaseSegundos     Int
  tiempoExtraSegundos      Int                     @default(0)
  versionReglas            Int                     @default(1)
  puntaje                  Int                     @default(0)
  comboActual              Int                     @default(0)
  mejorCombo               Int                     @default(0)
  respuestasCorrectas      Int                     @default(0)
  respuestasIncorrectas    Int                     @default(0)
  preguntasSaltadas        Int                     @default(0)
  indiceActual             Int                     @default(0)
  asistido                 Boolean                 @default(false)
  escudoComboActivo        Boolean                 @default(false)
  segundaOportunidadActiva Boolean                 @default(false)
  preguntaActualId         String?
  preguntaIniciaEn         DateTime?               @db.Timestamp(6)
  iniciadoEn               DateTime                @default(now()) @db.Timestamp(6)
  venceEn                  DateTime                @db.Timestamp(6)
  finalizadoEn             DateTime?               @db.Timestamp(6)
  usuario                  Usuario                 @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  preguntaActual           Pregunta?               @relation("PreguntaActualTriviaRush", fields: [preguntaActualId], references: [id], onDelete: SetNull)
  preguntas                TriviaRushPregunta[]
  respuestas               TriviaRushRespuesta[]
  potenciadores            TriviaRushPotenciador[]

  @@index([usuarioId, estado, iniciadoEn])
  @@index([estado, venceEn])
  @@index([preguntaActualId])
}
```

## model TriviaRushPregunta

Fuente: backend/prisma/schema.prisma:1016

```prisma
model TriviaRushPregunta {
  intentoId     String            @db.Uuid
  preguntaId    String
  orden         Int
  opcionesOrden Json
  intento       IntentoTriviaRush @relation(fields: [intentoId], references: [id], onDelete: Cascade)
  pregunta      Pregunta          @relation(fields: [preguntaId], references: [id], onDelete: Restrict)

  @@id([intentoId, preguntaId])
  @@unique([intentoId, orden])
  @@index([preguntaId])
}
```

## model TriviaRushRespuesta

Fuente: backend/prisma/schema.prisma:1029

```prisma
model TriviaRushRespuesta {
  id                      String            @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  intentoId               String            @db.Uuid
  preguntaId              String
  respuestaSeleccionadaId String?
  numeroIntento           Int
  esCorrecta              Boolean
  esFinal                 Boolean
  puntosOtorgados         Int               @default(0)
  comboResultante         Int
  tiempoRespuestaMs       Int
  claveIdempotencia       String            @unique @db.Uuid
  respondidaEn            DateTime          @default(now()) @db.Timestamp(6)
  intento                 IntentoTriviaRush @relation(fields: [intentoId], references: [id], onDelete: Cascade)
  pregunta                Pregunta          @relation(fields: [preguntaId], references: [id], onDelete: Restrict)
  respuestaSeleccionada   Respuesta?        @relation(fields: [respuestaSeleccionadaId], references: [id], onDelete: Restrict)

  @@unique([intentoId, preguntaId, numeroIntento])
  @@index([intentoId, esFinal, respondidaEn])
  @@index([preguntaId])
}
```

## model ConcesionRecompensaJuego

Fuente: backend/prisma/schema.prisma:1051

```prisma
model ConcesionRecompensaJuego {
  id                  String                    @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  usuarioId           String                    @db.Uuid
  proveedor           String                    @db.VarChar(30)
  referenciaProveedor String                    @unique @db.VarChar(180)
  estado              EstadoConcesionRecompensa @default(DISPONIBLE)
  expiraEn            DateTime                  @db.Timestamp(6)
  fechaCreacion       DateTime                  @default(now()) @db.Timestamp(6)
  consumidaEn         DateTime?                 @db.Timestamp(6)
  usuario             Usuario                   @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  consumoTrivia       TriviaRushPotenciador?

  @@index([usuarioId, estado, expiraEn])
}
```

## model TriviaRushPotenciador

Fuente: backend/prisma/schema.prisma:1066

```prisma
model TriviaRushPotenciador {
  id                 String                    @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  intentoId          String                    @db.Uuid
  preguntaId         String?
  tipo               TipoPotenciadorTriviaRush
  concesionId        String                    @unique @db.Uuid
  claveIdempotencia  String                    @unique @db.Uuid
  opcionesEliminadas Json?
  activadoEn         DateTime                  @default(now()) @db.Timestamp(6)
  intento            IntentoTriviaRush         @relation(fields: [intentoId], references: [id], onDelete: Cascade)
  pregunta           Pregunta?                 @relation(fields: [preguntaId], references: [id], onDelete: Restrict)
  concesion          ConcesionRecompensaJuego  @relation(fields: [concesionId], references: [id], onDelete: Restrict)

  @@index([intentoId, preguntaId, tipo])
}
```

## enum OrigenRespuesta

Fuente: backend/prisma/schema.prisma:1084

```prisma
enum OrigenRespuesta {
  SIMULACRO
  PERSONALIZADO
  PRACTICA
  DIAGNOSTICO
  BATALLA
  ADAPTATIVO
  TRIVIA_RUSH
}
```

## enum EstadoCuadernoError

Fuente: backend/prisma/schema.prisma:1094

```prisma
enum EstadoCuadernoError {
  PENDIENTE
  REPASANDO
  DOMINADO
}
```

## enum NivelDiagnostico

Fuente: backend/prisma/schema.prisma:1100

```prisma
enum NivelDiagnostico {
  POR_REFORZAR
  EN_PROCESO
  FORTALEZA
}
```

## model DiagnosticoInicial

Fuente: backend/prisma/schema.prisma:1106

```prisma
model DiagnosticoInicial {
  id                  String                     @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  usuarioId           String                     @unique @db.Uuid
  preguntaIds         Json
  iniciadoEn          DateTime                   @default(now()) @db.Timestamp(6)
  completadoEn        DateTime?                  @db.Timestamp(6)
  totalPreguntas      Int                        @default(0)
  respuestasCorrectas Int?
  porcentaje          Float?
  nivel               NivelDiagnostico?
  usuario             Usuario                    @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  resultadosPorArea   DiagnosticoResultadoArea[]
  planesEstudio       PlanEstudioSemanal[]

  @@index([completadoEn])
}
```

## model PlanEstudioSemanal

Fuente: backend/prisma/schema.prisma:1123

```prisma
model PlanEstudioSemanal {
  id                     String                 @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  usuarioId              String                 @db.Uuid
  diagnosticoId          String                 @db.Uuid
  calendarioIcfes        CalendarioTipo
  fechaExamen            DateTime               @db.Date
  inicioSemana           DateTime               @db.Date
  finSemana              DateTime               @db.Date
  diasRestantesAlGenerar Int
  sesionesObjetivo       Int
  minutosObjetivoSemanal Int
  fechaCreacion          DateTime               @default(now()) @db.Timestamp(6)
  usuario                Usuario                @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  diagnostico            DiagnosticoInicial     @relation(fields: [diagnosticoId], references: [id], onDelete: Cascade)
  actividades            PlanEstudioActividad[]

  @@unique([usuarioId, inicioSemana])
  @@index([diagnosticoId])
}
```

## model PlanEstudioActividad

Fuente: backend/prisma/schema.prisma:1143

```prisma
model PlanEstudioActividad {
  id        String             @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  planId    String             @db.Uuid
  subtemaId String?
  fecha     DateTime           @db.Date
  tipo      TipoActividadPlan
  area      AreaIcfes?
  titulo    String             @db.VarChar(180)
  detalle   String             @db.VarChar(300)
  minutos   Int                @default(0)
  orden     Int
  plan      PlanEstudioSemanal @relation(fields: [planId], references: [id], onDelete: Cascade)
  subtema   Subtema?           @relation(fields: [subtemaId], references: [id], onDelete: SetNull)

  @@unique([planId, fecha])
  @@index([subtemaId])
}
```

## model DiagnosticoResultadoArea

Fuente: backend/prisma/schema.prisma:1161

```prisma
model DiagnosticoResultadoArea {
  id                  String             @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  diagnosticoId       String             @db.Uuid
  area                AreaIcfes
  totalPreguntas      Int
  respuestasCorrectas Int
  porcentaje          Float
  nivel               NivelDiagnostico
  diagnostico         DiagnosticoInicial @relation(fields: [diagnosticoId], references: [id], onDelete: Cascade)

  @@unique([diagnosticoId, area])
  @@index([area, nivel])
}
```

## model ResultadoSimulacro

Fuente: backend/prisma/schema.prisma:1175

```prisma
model ResultadoSimulacro {
  id                  String    @id @default(uuid())
  usuarioId           String    @db.Uuid
  usuario             Usuario   @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  area                AreaIcfes
  totalPreguntas      Int
  respuestasCorrectas Int
  puntaje             Float // Porcentaje 0-100
  xpGanado            Int       @default(0)
  fechaRealizado      DateTime  @default(now())
}
```

## model IntentoSimulacro

Fuente: backend/prisma/schema.prisma:1187

```prisma
model IntentoSimulacro {
  id            String          @id @default(uuid()) @db.Uuid
  usuarioId     String          @db.Uuid
  usuario       Usuario         @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  origen        OrigenRespuesta
  area          AreaIcfes?
  preguntaIds   Json
  expira        DateTime        @db.Timestamp(6)
  consumidoEn   DateTime?       @db.Timestamp(6)
  fechaCreacion DateTime        @default(now()) @db.Timestamp(6)

  @@index([usuarioId, consumidoEn, expira])
}
```

## model PomodoroRegistrado

Fuente: backend/prisma/schema.prisma:1202

```prisma
model PomodoroRegistrado {
  usuarioId       String   @db.Uuid
  eventoId        String   @db.VarChar(80)
  duracionSegundos Int      @default(1500)
  finalizadoEn    DateTime @db.Timestamp(3)
  recibidoEn      DateTime @default(now()) @db.Timestamp(3)
  usuario         Usuario  @relation(fields: [usuarioId], references: [id], onDelete: Cascade)

  @@id([usuarioId, eventoId])
  @@unique([usuarioId, finalizadoEn])
}
```

## model HistorialRespuesta

Fuente: backend/prisma/schema.prisma:1214

```prisma
model HistorialRespuesta {
  id                      String          @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  sesionId                String          @db.Uuid
  usuarioId               String          @db.Uuid
  preguntaId              String
  respuestaSeleccionadaId String
  respuestaCorrectaId     String
  area                    AreaIcfes
  origen                  OrigenRespuesta
  esCorrecta              Boolean
  tiempoRespuestaSegundos Int?
  fechaRespuesta          DateTime        @default(now()) @db.Timestamp(6)
  usuario                 Usuario         @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  pregunta                Pregunta        @relation(fields: [preguntaId], references: [id], onDelete: Cascade)

  @@index([usuarioId, fechaRespuesta])
  @@index([usuarioId, esCorrecta, fechaRespuesta])
  @@index([usuarioId, area, fechaRespuesta])
  @@index([preguntaId])
  @@index([sesionId])
}
```

## model CuadernoError

Fuente: backend/prisma/schema.prisma:1236

```prisma
model CuadernoError {
  id                 String              @id @default(dbgenerated("uuid_generate_v4()")) @db.Uuid
  usuarioId          String              @db.Uuid
  preguntaId         String
  nota               String?             @db.Text
  estado             EstadoCuadernoError @default(PENDIENTE)
  dominadoEn         DateTime?           @db.Timestamp(6)
  fechaCreacion      DateTime            @default(now()) @db.Timestamp(6)
  fechaActualizacion DateTime            @default(now()) @updatedAt @db.Timestamp(6)
  usuario            Usuario             @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  pregunta           Pregunta            @relation(fields: [preguntaId], references: [id], onDelete: Cascade)

  @@unique([usuarioId, preguntaId])
  @@index([usuarioId, estado, fechaActualizacion])
}
```

## model IntentoGuardian

Fuente: backend/prisma/schema.prisma:1252

```prisma
model IntentoGuardian {
  id           String   @id @default(uuid()) @db.Uuid
  usuarioId    String   @db.Uuid
  usuario      Usuario  @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  area         AreaIcfes
  subtemaId    String?
  dificultad   Dificultad
  version      Int      @default(1)
  estado       String   @default("ACTIVO") @db.VarChar(20)
  // Snapshot privado: nunca se serializa directamente al cliente.
  preguntas    Json
  respuestas   Json     @default("[]")
  creadoEn     DateTime @default(now())
  venceEn      DateTime
  finalizadoEn DateTime?

  @@index([usuarioId, creadoEn])
}
```

## model IntentoCima

Fuente: backend/prisma/schema.prisma:1271

```prisma
model IntentoCima {
  id           String      @id @default(uuid()) @db.Uuid
  usuarioId    String      @db.Uuid
  usuario      Usuario     @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  area         AreaIcfes
  temaId       String?
  subtemaId    String?
  dificultad   Dificultad?
  version      Int         @default(1)
  estado       String      @default("ACTIVO") @db.VarChar(20)
  // Snapshot privado: la API nunca expone soluciones futuras.
  preguntas    Json
  respuestas   Json        @default("[]")
  creadoEn     DateTime    @default(now())
  venceEn      DateTime
  finalizadoEn DateTime?

  @@index([usuarioId, creadoEn])
}
```

## model IntentoRescateEstrellas

Fuente: backend/prisma/schema.prisma:1291

```prisma
model IntentoRescateEstrellas {
  id           String      @id @default(uuid()) @db.Uuid
  usuarioId    String      @db.Uuid
  usuario      Usuario     @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  area         AreaIcfes
  temaId       String?
  subtemaId    String?
  dificultad   Dificultad?
  version      Int         @default(1)
  estado       String      @default("ACTIVO") @db.VarChar(20)
  // Snapshot privado: la API nunca expone soluciones futuras.
  preguntas    Json
  respuestas   Json        @default("[]")
  creadoEn     DateTime    @default(now())
  venceEn      DateTime
  finalizadoEn DateTime?

  @@index([usuarioId, creadoEn])
}
```

## model IntentoEscudoConocimiento

Fuente: backend/prisma/schema.prisma:1313

```prisma
model IntentoEscudoConocimiento {
  id           String      @id @default(uuid()) @db.Uuid
  usuarioId    String      @db.Uuid
  usuario      Usuario     @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  area         AreaIcfes
  temaId       String?
  subtemaId    String?
  dificultad   Dificultad?
  version      Int         @default(1)
  estado       String      @default("ACTIVO") @db.VarChar(20)
  // Snapshot privado: la API nunca expone soluciones futuras.
  preguntas    Json
  respuestas   Json        @default("[]")
  creadoEn     DateTime    @default(now())
  venceEn      DateTime
  finalizadoEn DateTime?

  @@index([usuarioId, creadoEn])
}
```

## model RepasoDiferido

Fuente: backend/prisma/schema.prisma:1333

```prisma
model RepasoDiferido {
  usuarioId String @db.Uuid
  usuario Usuario @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  tarjetaId String @db.VarChar(200)
  contenidoVersion String @db.VarChar(40)
  paso Int
  revision Int
  revisadoEn DateTime @db.Timestamptz(3)
  venceEn DateTime @db.Timestamptz(3)
  @@id([usuarioId, contenidoVersion, tarjetaId])
}
```

## model EventoRepasoDiferido

Fuente: backend/prisma/schema.prisma:1345

```prisma
model EventoRepasoDiferido {
  usuarioId String @db.Uuid
  usuario Usuario @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  eventoId String @db.Uuid
  huella String @db.VarChar(64)
  resultado Json
  creadoEn DateTime @default(now()) @db.Timestamptz(3)
  @@id([usuarioId, eventoId])
}
```

## model ProgresoTema

Fuente: backend/prisma/schema.prisma:1355

```prisma
model ProgresoTema {
  id         String   @id @default(uuid())
  usuarioId  String   @db.Uuid
  subtemaId  String
  completado Boolean  @default(false)
  porcentaje Int      @default(0)
  fechaVisto DateTime @default(now())

  usuario Usuario @relation(fields: [usuarioId], references: [id], onDelete: Cascade)
  subtema Subtema @relation(fields: [subtemaId], references: [id], onDelete: Cascade)

  @@unique([usuarioId, subtemaId])
}
```

## Migraciones, en orden

### 20260101000000_init

Fuente: backend/prisma/migrations/20260101000000_init/migration.sql; SHA-256 1a2d5e34a4ce08f08b59c0f100a6d337d2ab16b8167c0c18dfa327ab0ab9250c.

```sql
-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "plpgsql" WITH SCHEMA "pg_catalog" VERSION "1.0";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "public" VERSION "1.1";

-- CreateEnum
CREATE TYPE "AreaIcfes" AS ENUM ('LECTURA_CRITICA', 'MATEMATICAS', 'SOCIALES_CIUDADANAS', 'CIENCIAS_NATURALES', 'INGLES');

-- CreateEnum
CREATE TYPE "Dificultad" AS ENUM ('BASICO', 'MEDIO', 'AVANZADO');

-- CreateEnum
CREATE TYPE "RolUsuario" AS ENUM ('ESTUDIANTE', 'PROFESOR', 'ADMIN');

-- CreateTable
CREATE TABLE "Clase" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "nombre" VARCHAR(255) NOT NULL,
    "codigoIngreso" VARCHAR(50) NOT NULL,
    "institucionId" UUID NOT NULL,

    CONSTRAINT "Clase_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ClaseEstudiante" (
    "usuarioId" UUID NOT NULL,
    "claseId" UUID NOT NULL,

    CONSTRAINT "ClaseEstudiante_pkey" PRIMARY KEY ("usuarioId","claseId")
);

-- CreateTable
CREATE TABLE "Institucion" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "nombre" VARCHAR(255) NOT NULL,
    "codigoUnico" VARCHAR(50) NOT NULL,
    "planActual" VARCHAR(50) DEFAULT 'GRATIS',

    CONSTRAINT "Institucion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Pregunta" (
    "id" TEXT NOT NULL,
    "enunciado" TEXT NOT NULL,
    "imagenUrl" TEXT,
    "dificultad" "Dificultad" NOT NULL DEFAULT 'MEDIO',
    "porcentajeAciertos" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "tiempoPromedioSegundos" INTEGER NOT NULL DEFAULT 0,
    "subtemaId" TEXT NOT NULL,

    CONSTRAINT "Pregunta_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProgresoTema" (
    "id" TEXT NOT NULL,
    "usuarioId" UUID NOT NULL,
    "subtemaId" TEXT NOT NULL,
    "completado" BOOLEAN NOT NULL DEFAULT false,
    "porcentaje" INTEGER NOT NULL DEFAULT 0,
    "fechaVisto" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ProgresoTema_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Respuesta" (
    "id" TEXT NOT NULL,
    "texto" TEXT NOT NULL,
    "esCorrecta" BOOLEAN NOT NULL DEFAULT false,
    "preguntaId" TEXT NOT NULL,

    CONSTRAINT "Respuesta_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ResultadoSimulacro" (
    "id" TEXT NOT NULL,
    "usuarioId" UUID NOT NULL,
    "area" "AreaIcfes" NOT NULL,
    "totalPreguntas" INTEGER NOT NULL,
    "respuestasCorrectas" INTEGER NOT NULL,
    "puntaje" DOUBLE PRECISION NOT NULL,
    "xpGanado" INTEGER NOT NULL DEFAULT 0,
    "fechaRealizado" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ResultadoSimulacro_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Subtema" (
    "id" TEXT NOT NULL,
    "nombre" TEXT NOT NULL,
    "temaId" TEXT NOT NULL,
    "contenido" TEXT,
    "imagenUrl" TEXT,
    "videoUrl" TEXT,

    CONSTRAINT "Subtema_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Tema" (
    "id" TEXT NOT NULL,
    "nombre" TEXT NOT NULL,
    "area" "AreaIcfes" NOT NULL,

    CONSTRAINT "Tema_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Usuario" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "nombre" VARCHAR(255) NOT NULL,
    "correo" VARCHAR(255) NOT NULL,
    "contrasenaHash" TEXT NOT NULL,
    "rol" "RolUsuario" DEFAULT 'ESTUDIANTE',
    "xpTotal" INTEGER DEFAULT 0,
    "fechaCreacion" TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP,
    "institucionId" UUID,
    "descripcion" TEXT,
    "fotoPerfil" TEXT,

    CONSTRAINT "Usuario_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Clase_codigoIngreso_key" ON "Clase"("codigoIngreso" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "Institucion_codigoUnico_key" ON "Institucion"("codigoUnico" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "ProgresoTema_usuarioId_subtemaId_key" ON "ProgresoTema"("usuarioId" ASC, "subtemaId" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "Usuario_correo_key" ON "Usuario"("correo" ASC);

-- AddForeignKey
ALTER TABLE "Clase" ADD CONSTRAINT "fk_clase_institucion" FOREIGN KEY ("institucionId") REFERENCES "Institucion"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "ClaseEstudiante" ADD CONSTRAINT "fk_ce_clase" FOREIGN KEY ("claseId") REFERENCES "Clase"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "ClaseEstudiante" ADD CONSTRAINT "fk_ce_usuario" FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "Pregunta" ADD CONSTRAINT "Pregunta_subtemaId_fkey" FOREIGN KEY ("subtemaId") REFERENCES "Subtema"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProgresoTema" ADD CONSTRAINT "ProgresoTema_subtemaId_fkey" FOREIGN KEY ("subtemaId") REFERENCES "Subtema"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProgresoTema" ADD CONSTRAINT "ProgresoTema_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Respuesta" ADD CONSTRAINT "Respuesta_preguntaId_fkey" FOREIGN KEY ("preguntaId") REFERENCES "Pregunta"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ResultadoSimulacro" ADD CONSTRAINT "ResultadoSimulacro_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Subtema" ADD CONSTRAINT "Subtema_temaId_fkey" FOREIGN KEY ("temaId") REFERENCES "Tema"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Usuario" ADD CONSTRAINT "fk_institucion" FOREIGN KEY ("institucionId") REFERENCES "Institucion"("id") ON DELETE SET NULL ON UPDATE NO ACTION;
```

### 20260627230748_agregar_subtema_interactivo

Fuente: backend/prisma/migrations/20260627230748_agregar_subtema_interactivo/migration.sql; SHA-256 4b0d92fb0320f2b6761d5144af98f29d6ffc45c7f30d6dcde2d42a4fbd1794bb.

```sql
-- CreateEnum
CREATE TYPE "TipoInteractivo" AS ENUM ('CLOZE');

-- AlterTable
ALTER TABLE "Subtema" ADD COLUMN     "datosInteractivo" JSONB,
ADD COLUMN     "tipoInteractivo" "TipoInteractivo";
```

### 20260715120000_add_institucion_branding

Fuente: backend/prisma/migrations/20260715120000_add_institucion_branding/migration.sql; SHA-256 a0b832c6120e5d07d60ce6b28fde8a2fed742a538fe4719aee8f5d8f9b6d4596.

```sql
-- Add institution branding fields to Institucion model
ALTER TABLE "Institucion"
ADD COLUMN "logoUrl" VARCHAR(255);

ALTER TABLE "Institucion"
ADD COLUMN "colorPrimario" VARCHAR(20);

ALTER TABLE "Institucion"
ADD COLUMN "colorSecundario" VARCHAR(20);

ALTER TABLE "Institucion"
ADD COLUMN "mensajeBienvenida" TEXT;

ALTER TABLE "Institucion"
ADD COLUMN "imagenPortada" VARCHAR(255);
```

### 20260719000000_add_cupos_por_grado

Fuente: backend/prisma/migrations/20260719000000_add_cupos_por_grado/migration.sql; SHA-256 5d107043bbf3b500e8cac3b86647628d9574f92fbd8f67bb61fdf541260e43ea.

```sql
-- Cupos independientes por grado (10 y 11) en la institución.
-- NULL = sin límite fijo (planes "Colegio", cotización directa).
ALTER TABLE "Institucion"
ADD COLUMN "limiteGrado10" INTEGER;

ALTER TABLE "Institucion"
ADD COLUMN "limiteGrado11" INTEGER;
```

### 20260720000000_add_grado_a_clase

Fuente: backend/prisma/migrations/20260720000000_add_grado_a_clase/migration.sql; SHA-256 10c4b61daf313f954953814efbc4856c6957526ddd663bf3561d861fe585bb6f.

```sql
-- Punto 3 del roadmap: etiquetar cada grupo (Clase) por grado, para poder
-- descontar del cupo correspondiente (limiteGrado10 / limiteGrado11).

CREATE TYPE "Grado" AS ENUM ('DECIMO', 'ONCE');

-- Se agrega con default 'ONCE' para no romper grupos ya existentes,
-- y luego se quita el default: de ahora en adelante el grado es obligatorio.
ALTER TABLE "Clase"
ADD COLUMN "grado" "Grado" NOT NULL DEFAULT 'ONCE';

ALTER TABLE "Clase"
ALTER COLUMN "grado" DROP DEFAULT;
```

### 20260721000000_add_plan_individual_estudiante

Fuente: backend/prisma/migrations/20260721000000_add_plan_individual_estudiante/migration.sql; SHA-256 c97016d76d7f0500d85e1ff7cdac42078275746ba6317ccda1e366c37cbbefff.

```sql
-- Punto 5 del roadmap: plan/suscripción del estudiante individual.
-- Guarda cuándo vence la prueba gratis (o el plan pagado, más adelante)
-- de un estudiante que NO pertenece a una institución.
ALTER TABLE "Usuario" ADD COLUMN "fechaVencimientoPlan" TIMESTAMP(6);
```

### 20260722034032_calendario_icfes

Fuente: backend/prisma/migrations/20260722034032_calendario_icfes/migration.sql; SHA-256 9109250601a58f23b58a333d123ac014121f83e25e967969c3d176281ae67518.

```sql
-- CreateEnum
CREATE TYPE "CalendarioTipo" AS ENUM ('A', 'B');

-- AlterTable
ALTER TABLE "Institucion" ADD COLUMN     "calendarioIcfes" "CalendarioTipo" DEFAULT 'A',
ADD COLUMN     "fechaVencimientoPlan" TIMESTAMP(6);

-- AlterTable
ALTER TABLE "Usuario" ADD COLUMN     "calendarioIcfes" "CalendarioTipo" DEFAULT 'A';

-- CreateTable
CREATE TABLE "CalendarioIcfes" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "anio" INTEGER NOT NULL,
    "calendario" "CalendarioTipo" NOT NULL,
    "fechaExamen" DATE NOT NULL,
    "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CalendarioIcfes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "CalendarioIcfes_anio_calendario_key" ON "CalendarioIcfes"("anio", "calendario");
```

### 20260722040847_verificacion_correo

Fuente: backend/prisma/migrations/20260722040847_verificacion_correo/migration.sql; SHA-256 1409888b516fa1c52c6426af5ca713d50c63994352850d160606dd2b65c8b846.

```sql
/*
  Warnings:

  - A unique constraint covering the columns `[tokenVerificacion]` on the table `Usuario` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "Usuario" ADD COLUMN     "correoVerificado" BOOLEAN DEFAULT false,
ADD COLUMN     "tokenVerificacion" VARCHAR(255),
ADD COLUMN     "tokenVerificacionExpira" TIMESTAMP(6);

-- CreateIndex
CREATE UNIQUE INDEX "Usuario_tokenVerificacion_key" ON "Usuario"("tokenVerificacion");
```

### 20260723033445_recuperacion_contrasena

Fuente: backend/prisma/migrations/20260723033445_recuperacion_contrasena/migration.sql; SHA-256 7ab688b71811928ea775a1ce2620a4fb1427556d6b96418c1f37e8c96e51f56f.

```sql
/*
  Warnings:

  - A unique constraint covering the columns `[tokenRecuperacion]` on the table `Usuario` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "Usuario" ADD COLUMN     "tokenRecuperacion" VARCHAR(255),
ADD COLUMN     "tokenRecuperacionExpira" TIMESTAMP(6);

-- CreateIndex
CREATE UNIQUE INDEX "Usuario_tokenRecuperacion_key" ON "Usuario"("tokenRecuperacion");
```

### 20260809000000_add_pagos_epayco

Fuente: backend/prisma/migrations/20260809000000_add_pagos_epayco/migration.sql; SHA-256 7d9396c8ca6df02f1e9da6d088c1207fc00bfdcdc8bd4109dad39188d75fb54d.

```sql
-- Punto 9 del roadmap: pasarela de pago (ePayco) para el estudiante
-- individual. Sin esto, el muro de pago de 3 días (punto 5) solo
-- bloquea, pero nadie puede pagar para reactivar su acceso.

-- Grado del estudiante individual: define el precio ($25.000 g10 /
-- $35.000 g11, según la tabla "Individual (Referencia)" del roadmap).
ALTER TABLE "Usuario" ADD COLUMN "grado" "Grado";

-- Estado de una orden/intento de pago con ePayco.
CREATE TYPE "EstadoPago" AS ENUM ('PENDIENTE', 'APROBADA', 'RECHAZADA', 'PENDIENTE_BANCO', 'FALLIDA');

CREATE TABLE "PagoOrden" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "factura" VARCHAR(50) NOT NULL,
    "usuarioId" UUID NOT NULL,
    "grado" "Grado" NOT NULL,
    "monto" INTEGER NOT NULL,
    "moneda" VARCHAR(10) NOT NULL DEFAULT 'COP',
    "estado" "EstadoPago" NOT NULL DEFAULT 'PENDIENTE',
    "refPayco" VARCHAR(50),
    "transaccionId" VARCHAR(100),
    "motivoRespuesta" TEXT,
    "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "fechaActualizacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PagoOrden_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "PagoOrden_factura_key" ON "PagoOrden"("factura");

CREATE INDEX "PagoOrden_usuarioId_idx" ON "PagoOrden"("usuarioId");

ALTER TABLE "PagoOrden" ADD CONSTRAINT "fk_pagoorden_usuario" FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE NO ACTION;
```

### 20260810000000_add_leads_ventas

Fuente: backend/prisma/migrations/20260810000000_add_leads_ventas/migration.sql; SHA-256 ae1b40ce026cf0a97ebf87868cf20e69130cabe31cd8c67bf6aaaa4429584a28.

```sql
-- CreateEnum
CREATE TYPE "LineaInteres" AS ENUM ('ONCE', 'BACHILLERATO');

-- CreateTable
CREATE TABLE "LeadVentas" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "nombreColegio" VARCHAR(255) NOT NULL,
    "nombreContacto" VARCHAR(255) NOT NULL,
    "correo" VARCHAR(255) NOT NULL,
    "telefono" VARCHAR(50),
    "ciudad" VARCHAR(100),
    "linea" "LineaInteres" NOT NULL,
    "plan" VARCHAR(50) NOT NULL,
    "numeroEstudiantesAprox" INTEGER,
    "mensaje" TEXT,
    "atendido" BOOLEAN NOT NULL DEFAULT false,
    "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "LeadVentas_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "LeadVentas_atendido_fechaCreacion_idx"
ON "LeadVentas"("atendido", "fechaCreacion");
```

### 20260816212418_add_tipo_plan_wompi

Fuente: backend/prisma/migrations/20260816212418_add_tipo_plan_wompi/migration.sql; SHA-256 b445a4c13d2355fe46b2ffd205e2771766be1f6f570097a75bcd23bbcc6b8515.

```sql
-- CreateEnum
CREATE TYPE "TipoPlan" AS ENUM ('MENSUAL', 'TEMPORADA_A', 'TEMPORADA_B');

-- AlterTable
ALTER TABLE "PagoOrden" ADD COLUMN     "tipoPlan" "TipoPlan" NOT NULL DEFAULT 'MENSUAL';
```

### 20260818013212_debe_cambiar_contrasena

Fuente: backend/prisma/migrations/20260818013212_debe_cambiar_contrasena/migration.sql; SHA-256 6e68772a0beac16762b4701e1aa9641c9ea04e0928a20d9d9062c4524f337639.

```sql
-- AlterTable
ALTER TABLE "Usuario" ADD COLUMN     "debeCambiarContrasena" BOOLEAN DEFAULT false;
```

### 20260818020000_add_cupones

Fuente: backend/prisma/migrations/20260818020000_add_cupones/migration.sql; SHA-256 06f1e03a3cde184d20a536a2e9e56c8c28c1020a1f4c3e93e51e1615c3bcaced.

```sql
-- Punto 13 del roadmap: cupones y promociones creados por el admin.
-- El admin define un % de descuento, a qué tipoPlan aplica (o a todos
-- si queda en null), hasta cuándo es válido y cuántas personas pueden
-- usarlo como máximo (usosMaximos null = sin límite de usos).

-- CreateTable
CREATE TABLE "Cupon" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "codigo" VARCHAR(50) NOT NULL,
    "porcentajeDescuento" INTEGER NOT NULL,
    "tipoPlan" "TipoPlan",
    "fechaExpiracion" TIMESTAMP(6) NOT NULL,
    "usosMaximos" INTEGER,
    "usosActuales" INTEGER NOT NULL DEFAULT 0,
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Cupon_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "Cupon_codigo_key" ON "Cupon"("codigo");

-- AlterTable: guardamos el precio de lista original y a qué cupón
-- quedó asociada la orden, para poder auditar el descuento aplicado.
ALTER TABLE "PagoOrden" ADD COLUMN     "montoOriginal" INTEGER;
ALTER TABLE "PagoOrden" ADD COLUMN     "cuponId" UUID;

CREATE INDEX "PagoOrden_cuponId_idx" ON "PagoOrden"("cuponId");

ALTER TABLE "PagoOrden" ADD CONSTRAINT "fk_pagoorden_cupon" FOREIGN KEY ("cuponId") REFERENCES "Cupon"("id") ON DELETE SET NULL ON UPDATE NO ACTION;
```

### 20260820160000_add_promociones_automaticas

Fuente: backend/prisma/migrations/20260820160000_add_promociones_automaticas/migration.sql; SHA-256 2629e7a5d284d041d3874c8c20896610bfbb396748ee941c6c806835104e2f57.

```sql
ALTER TABLE "Cupon"
ADD COLUMN IF NOT EXISTS "titulo" VARCHAR(120),
ADD COLUMN IF NOT EXISTS "esAutomatica" BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS "Cupon_promocion_activa_idx"
ON "Cupon" ("esAutomatica", "activo", "fechaExpiracion");
```

### 20260820210000_simplify_business_model

Fuente: backend/prisma/migrations/20260820210000_simplify_business_model/migration.sql; SHA-256 a592223310537376919b6f5f9f24066bae949b417df8c26b0cec153bf0d2b774.

```sql
ALTER TABLE "CalendarioIcfes"
ADD COLUMN IF NOT EXISTS "activo" BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE "Institucion"
ADD COLUMN IF NOT EXISTS "limiteEstudiantes" INTEGER;

UPDATE "Institucion"
SET "limiteEstudiantes" =
  COALESCE("limiteGrado10", 0) + COALESCE("limiteGrado11", 0)
WHERE "limiteEstudiantes" IS NULL
  AND ("limiteGrado10" IS NOT NULL OR "limiteGrado11" IS NOT NULL);

ALTER TABLE "PagoOrden"
ALTER COLUMN "grado" DROP NOT NULL;

ALTER TABLE "PagoOrden"
ADD COLUMN IF NOT EXISTS "calendarioIcfes" "CalendarioTipo",
ADD COLUMN IF NOT EXISTS "fechaVencimientoAcceso" TIMESTAMP(6);

WITH "candidata" AS (
  SELECT "id"
  FROM "CalendarioIcfes"
  ORDER BY
    ("fechaExamen" >= CURRENT_DATE) DESC,
    CASE WHEN "fechaExamen" >= CURRENT_DATE THEN "fechaExamen" END ASC,
    "fechaExamen" DESC
  LIMIT 1
)
UPDATE "CalendarioIcfes"
SET "activo" = true
WHERE "id" = (SELECT "id" FROM "candidata")
  AND NOT EXISTS (
    SELECT 1 FROM "CalendarioIcfes" WHERE "activo" = true
  );

CREATE INDEX IF NOT EXISTS "CalendarioIcfes_activo_fechaExamen_idx"
ON "CalendarioIcfes" ("activo", "fechaExamen");
```

### 20260820230000_add_explicaciones_preguntas

Fuente: backend/prisma/migrations/20260820230000_add_explicaciones_preguntas/migration.sql; SHA-256 a3c6be08d3658702a1aee07599932ef6e349f123493d6941edba66a71535f707.

```sql
ALTER TABLE "Pregunta"
ADD COLUMN IF NOT EXISTS "explicacion" TEXT;

ALTER TABLE "Respuesta"
ADD COLUMN IF NOT EXISTS "explicacion" TEXT;
```

### 20260820233000_add_casos_preguntas

Fuente: backend/prisma/migrations/20260820233000_add_casos_preguntas/migration.sql; SHA-256 123369feba633d2827e2a182ccad7b20ded1b18712872a7e36bdccc8b1c62161.

```sql
CREATE TABLE IF NOT EXISTS "CasoPregunta" (
  "id" TEXT NOT NULL,
  "titulo" TEXT,
  "contexto" TEXT NOT NULL,
  "imagenUrl" TEXT,
  "area" "AreaIcfes" NOT NULL,
  "fechaCreacion" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "CasoPregunta_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "Pregunta"
ADD COLUMN IF NOT EXISTS "casoId" TEXT,
ADD COLUMN IF NOT EXISTS "ordenEnCaso" INTEGER;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'Pregunta_casoId_fkey'
  ) THEN
    ALTER TABLE "Pregunta"
    ADD CONSTRAINT "Pregunta_casoId_fkey"
    FOREIGN KEY ("casoId") REFERENCES "CasoPregunta"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS "Pregunta_casoId_ordenEnCaso_idx"
ON "Pregunta"("casoId", "ordenEnCaso");

CREATE INDEX IF NOT EXISTS "CasoPregunta_area_fechaCreacion_idx"
ON "CasoPregunta"("area", "fechaCreacion");
```

### 20260821023000_add_historial_respuestas

Fuente: backend/prisma/migrations/20260821023000_add_historial_respuestas/migration.sql; SHA-256 57864fe33b1afc1b067975e19af8204aea59a27102dc0e8a47d6fd6fffb41618.

```sql
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'OrigenRespuesta') THEN
    CREATE TYPE "OrigenRespuesta" AS ENUM ('SIMULACRO', 'PERSONALIZADO', 'PRACTICA');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS "HistorialRespuesta" (
  "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
  "sesionId" UUID NOT NULL,
  "usuarioId" UUID NOT NULL,
  "preguntaId" TEXT NOT NULL,
  "respuestaSeleccionadaId" TEXT NOT NULL,
  "respuestaCorrectaId" TEXT NOT NULL,
  "area" "AreaIcfes" NOT NULL,
  "origen" "OrigenRespuesta" NOT NULL,
  "esCorrecta" BOOLEAN NOT NULL,
  "tiempoRespuestaSegundos" INTEGER,
  "fechaRespuesta" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "HistorialRespuesta_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "HistorialRespuesta_usuarioId_fkey"
    FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "HistorialRespuesta_preguntaId_fkey"
    FOREIGN KEY ("preguntaId") REFERENCES "Pregunta"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS "HistorialRespuesta_usuarioId_fechaRespuesta_idx"
ON "HistorialRespuesta"("usuarioId", "fechaRespuesta");

CREATE INDEX IF NOT EXISTS "HistorialRespuesta_usuarioId_esCorrecta_fechaRespuesta_idx"
ON "HistorialRespuesta"("usuarioId", "esCorrecta", "fechaRespuesta");

CREATE INDEX IF NOT EXISTS "HistorialRespuesta_usuarioId_area_fechaRespuesta_idx"
ON "HistorialRespuesta"("usuarioId", "area", "fechaRespuesta");

CREATE INDEX IF NOT EXISTS "HistorialRespuesta_preguntaId_idx"
ON "HistorialRespuesta"("preguntaId");

CREATE INDEX IF NOT EXISTS "HistorialRespuesta_sesionId_idx"
ON "HistorialRespuesta"("sesionId");
```

### 20260821043000_add_diagnostico_inicial

Fuente: backend/prisma/migrations/20260821043000_add_diagnostico_inicial/migration.sql; SHA-256 66f8854e738a5e9f21f98da7358f341608cfc37f9f84db13ea668f2cb35b3d72.

```sql
ALTER TYPE "OrigenRespuesta" ADD VALUE IF NOT EXISTS 'DIAGNOSTICO';

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'NivelDiagnostico') THEN
    CREATE TYPE "NivelDiagnostico" AS ENUM ('POR_REFORZAR', 'EN_PROCESO', 'FORTALEZA');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS "DiagnosticoInicial" (
  "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
  "usuarioId" UUID NOT NULL,
  "preguntaIds" JSONB NOT NULL,
  "iniciadoEn" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "completadoEn" TIMESTAMP(6),
  "totalPreguntas" INTEGER NOT NULL DEFAULT 0,
  "respuestasCorrectas" INTEGER,
  "porcentaje" DOUBLE PRECISION,
  "nivel" "NivelDiagnostico",
  CONSTRAINT "DiagnosticoInicial_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "DiagnosticoInicial_usuarioId_fkey"
    FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "DiagnosticoInicial_usuarioId_key"
ON "DiagnosticoInicial"("usuarioId");

CREATE INDEX IF NOT EXISTS "DiagnosticoInicial_completadoEn_idx"
ON "DiagnosticoInicial"("completadoEn");

CREATE TABLE IF NOT EXISTS "DiagnosticoResultadoArea" (
  "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
  "diagnosticoId" UUID NOT NULL,
  "area" "AreaIcfes" NOT NULL,
  "totalPreguntas" INTEGER NOT NULL,
  "respuestasCorrectas" INTEGER NOT NULL,
  "porcentaje" DOUBLE PRECISION NOT NULL,
  "nivel" "NivelDiagnostico" NOT NULL,
  CONSTRAINT "DiagnosticoResultadoArea_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "DiagnosticoResultadoArea_diagnosticoId_fkey"
    FOREIGN KEY ("diagnosticoId") REFERENCES "DiagnosticoInicial"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "DiagnosticoResultadoArea_diagnosticoId_area_key"
ON "DiagnosticoResultadoArea"("diagnosticoId", "area");

CREATE INDEX IF NOT EXISTS "DiagnosticoResultadoArea_area_nivel_idx"
ON "DiagnosticoResultadoArea"("area", "nivel");
```

### 20260821140000_add_sistema_referidos

Fuente: backend/prisma/migrations/20260821140000_add_sistema_referidos/migration.sql; SHA-256 ecc4820d478ee3402859738a471f1dce80552af2bc0c5093571ba495eff3d7c5.

```sql
-- Point 25: referral links, conversion rewards and checkout credit.
CREATE TYPE "EstadoReferido" AS ENUM ('REGISTRADO', 'RECOMPENSADO');

ALTER TABLE "Usuario"
ADD COLUMN "codigoReferido" VARCHAR(12),
ADD COLUMN "saldoReferidosCop" INTEGER NOT NULL DEFAULT 0;

ALTER TABLE "PagoOrden"
ADD COLUMN "creditoReferidosUsado" INTEGER NOT NULL DEFAULT 0;

CREATE TABLE "Referido" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "referidorId" UUID NOT NULL,
    "referidoId" UUID NOT NULL,
    "codigoUsado" VARCHAR(12) NOT NULL,
    "estado" "EstadoReferido" NOT NULL DEFAULT 'REGISTRADO',
    "recompensaCop" INTEGER NOT NULL DEFAULT 0,
    "ordenPagoId" UUID,
    "fechaRegistro" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "fechaRecompensa" TIMESTAMP(6),

    CONSTRAINT "Referido_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "Usuario_codigoReferido_key" ON "Usuario"("codigoReferido");
CREATE UNIQUE INDEX "Referido_referidoId_key" ON "Referido"("referidoId");
CREATE UNIQUE INDEX "Referido_ordenPagoId_key" ON "Referido"("ordenPagoId");
CREATE INDEX "Referido_referidorId_estado_idx" ON "Referido"("referidorId", "estado");

ALTER TABLE "Referido"
ADD CONSTRAINT "Referido_referidorId_fkey"
FOREIGN KEY ("referidorId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "Referido"
ADD CONSTRAINT "Referido_referidoId_fkey"
FOREIGN KEY ("referidoId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "Referido"
ADD CONSTRAINT "Referido_ordenPagoId_fkey"
FOREIGN KEY ("ordenPagoId") REFERENCES "PagoOrden"("id") ON DELETE SET NULL ON UPDATE CASCADE;
```

### 20260821180000_add_configuracion_soporte

Fuente: backend/prisma/migrations/20260821180000_add_configuracion_soporte/migration.sql; SHA-256 bf59671eda3c41ee7048c50dad657d53e1bc764c3ff4a9a63862e0b89621428a.

```sql
-- Point 27: editable WhatsApp support configuration.
CREATE TABLE "ConfiguracionSoporte" (
    "id" VARCHAR(30) NOT NULL DEFAULT 'principal',
    "numeroWhatsapp" VARCHAR(15),
    "mensajeWhatsapp" VARCHAR(300) NOT NULL DEFAULT 'Hola, necesito ayuda con SaberPlus.',
    "activo" BOOLEAN NOT NULL DEFAULT false,
    "fechaActualizacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ConfiguracionSoporte_pkey" PRIMARY KEY ("id")
);

INSERT INTO "ConfiguracionSoporte" ("id") VALUES ('principal');
```

### 20260821210000_add_plan_estudio_semanal

Fuente: backend/prisma/migrations/20260821210000_add_plan_estudio_semanal/migration.sql; SHA-256 54eb689b7c2018dcb8d4bf76f6c178923f4ef218872178453a8adce3e84443d0.

```sql
-- Point 28: stable weekly study plans driven by the initial diagnostic and exam date.
CREATE TYPE "TipoActividadPlan" AS ENUM ('ESTUDIO', 'SIMULACRO', 'DESCANSO', 'EXAMEN');

CREATE TABLE "PlanEstudioSemanal" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "usuarioId" UUID NOT NULL,
    "diagnosticoId" UUID NOT NULL,
    "calendarioIcfes" "CalendarioTipo" NOT NULL,
    "fechaExamen" DATE NOT NULL,
    "inicioSemana" DATE NOT NULL,
    "finSemana" DATE NOT NULL,
    "diasRestantesAlGenerar" INTEGER NOT NULL,
    "sesionesObjetivo" INTEGER NOT NULL,
    "minutosObjetivoSemanal" INTEGER NOT NULL,
    "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PlanEstudioSemanal_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "PlanEstudioActividad" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "planId" UUID NOT NULL,
    "subtemaId" TEXT,
    "fecha" DATE NOT NULL,
    "tipo" "TipoActividadPlan" NOT NULL,
    "area" "AreaIcfes",
    "titulo" VARCHAR(180) NOT NULL,
    "detalle" VARCHAR(300) NOT NULL,
    "minutos" INTEGER NOT NULL DEFAULT 0,
    "orden" INTEGER NOT NULL,

    CONSTRAINT "PlanEstudioActividad_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "PlanEstudioSemanal_usuarioId_inicioSemana_key" ON "PlanEstudioSemanal"("usuarioId", "inicioSemana");
CREATE INDEX "PlanEstudioSemanal_diagnosticoId_idx" ON "PlanEstudioSemanal"("diagnosticoId");
CREATE UNIQUE INDEX "PlanEstudioActividad_planId_fecha_key" ON "PlanEstudioActividad"("planId", "fecha");
CREATE INDEX "PlanEstudioActividad_subtemaId_idx" ON "PlanEstudioActividad"("subtemaId");

ALTER TABLE "PlanEstudioSemanal" ADD CONSTRAINT "PlanEstudioSemanal_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PlanEstudioSemanal" ADD CONSTRAINT "PlanEstudioSemanal_diagnosticoId_fkey" FOREIGN KEY ("diagnosticoId") REFERENCES "DiagnosticoInicial"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PlanEstudioActividad" ADD CONSTRAINT "PlanEstudioActividad_planId_fkey" FOREIGN KEY ("planId") REFERENCES "PlanEstudioSemanal"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PlanEstudioActividad" ADD CONSTRAINT "PlanEstudioActividad_subtemaId_fkey" FOREIGN KEY ("subtemaId") REFERENCES "Subtema"("id") ON DELETE SET NULL ON UPDATE CASCADE;
```

### 20260821220000_add_tutorial_primer_ingreso

Fuente: backend/prisma/migrations/20260821220000_add_tutorial_primer_ingreso/migration.sql; SHA-256 20f39c279bb1ff115b7e2dd2b4da27370925e70978ac0c40ed85aac8eeafc36d.

```sql
-- Point 29: remember the onboarding version seen by each user and role.
ALTER TABLE "Usuario"
ADD COLUMN "tutorialEstudianteVersion" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN "tutorialProfesorVersion" INTEGER NOT NULL DEFAULT 0;
```

### 20260821230000_add_tablon_anuncios

Fuente: backend/prisma/migrations/20260821230000_add_tablon_anuncios/migration.sql; SHA-256 b4f401f41dc4bc29a7b3b56ff92668134c8f0bd4ee4056af44d4502a5026601f.

```sql
-- Point 31: in-app announcements segmented by audience with per-user read state.
CREATE TYPE "TipoAnuncio" AS ENUM ('INFORMACION', 'IMPORTANTE', 'EVENTO');
CREATE TYPE "AudienciaAnuncio" AS ENUM ('TODOS', 'ESTUDIANTES', 'PROFESORES');

CREATE TABLE "Anuncio" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "titulo" VARCHAR(120) NOT NULL,
    "contenido" TEXT NOT NULL,
    "tipo" "TipoAnuncio" NOT NULL DEFAULT 'INFORMACION',
    "audiencia" "AudienciaAnuncio" NOT NULL DEFAULT 'TODOS',
    "fechaInicio" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "fechaFin" TIMESTAMP(6),
    "activo" BOOLEAN NOT NULL DEFAULT true,
    "destacado" BOOLEAN NOT NULL DEFAULT false,
    "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "fechaEdicion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Anuncio_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "AnuncioLectura" (
    "anuncioId" UUID NOT NULL,
    "usuarioId" UUID NOT NULL,
    "fechaLectura" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "AnuncioLectura_pkey" PRIMARY KEY ("anuncioId", "usuarioId")
);

CREATE INDEX "Anuncio_activo_fechaInicio_fechaFin_idx"
ON "Anuncio"("activo", "fechaInicio", "fechaFin");
CREATE INDEX "Anuncio_audiencia_destacado_idx"
ON "Anuncio"("audiencia", "destacado");
CREATE INDEX "AnuncioLectura_usuarioId_fechaLectura_idx"
ON "AnuncioLectura"("usuarioId", "fechaLectura");

ALTER TABLE "AnuncioLectura"
ADD CONSTRAINT "AnuncioLectura_anuncioId_fkey"
FOREIGN KEY ("anuncioId") REFERENCES "Anuncio"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "AnuncioLectura"
ADD CONSTRAINT "AnuncioLectura_usuarioId_fkey"
FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;
```

### 20260822190000_add_anuncios_institucionales

Fuente: backend/prisma/migrations/20260822190000_add_anuncios_institucionales/migration.sql; SHA-256 6ce9d2c864623bee8bc5f6f97860117c5c929e41c5d85867daee52c0ff3418bb.

```sql
ALTER TABLE "Anuncio"
ADD COLUMN "institucionId" UUID,
ADD COLUMN "creadoPorId" UUID;

ALTER TABLE "Anuncio"
ADD CONSTRAINT "Anuncio_institucionId_fkey"
FOREIGN KEY ("institucionId") REFERENCES "Institucion"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "Anuncio"
ADD CONSTRAINT "Anuncio_creadoPorId_fkey"
FOREIGN KEY ("creadoPorId") REFERENCES "Usuario"("id")
ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX "Anuncio_institucionId_activo_fechaInicio_idx"
ON "Anuncio"("institucionId", "activo", "fechaInicio");

CREATE INDEX "Anuncio_creadoPorId_idx" ON "Anuncio"("creadoPorId");
```

### 20260822193000_remove_institution_colors

Fuente: backend/prisma/migrations/20260822193000_remove_institution_colors/migration.sql; SHA-256 b1306b2d65820dbf15f494962d58f0994ff2753f2a276aeb7c6f119c9c597d39.

```sql
ALTER TABLE "Institucion"
DROP COLUMN "colorPrimario",
DROP COLUMN "colorSecundario";
```

### 20260824123000_intentos_simulacro_y_transaccion_unica

Fuente: backend/prisma/migrations/20260824123000_intentos_simulacro_y_transaccion_unica/migration.sql; SHA-256 7ecb544b47aee812d22e7c2e9d2b304547881375688e84e98112301d6ecc762a.

```sql
CREATE TABLE "IntentoSimulacro" (
    "id" UUID NOT NULL,
    "usuarioId" UUID NOT NULL,
    "origen" "OrigenRespuesta" NOT NULL,
    "area" "AreaIcfes",
    "preguntaIds" JSONB NOT NULL,
    "expira" TIMESTAMP(6) NOT NULL,
    "consumidoEn" TIMESTAMP(6),
    "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "IntentoSimulacro_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "IntentoSimulacro_usuarioId_consumidoEn_expira_idx"
ON "IntentoSimulacro"("usuarioId", "consumidoEn", "expira");

CREATE UNIQUE INDEX "PagoOrden_transaccionId_key"
ON "PagoOrden"("transaccionId");

ALTER TABLE "IntentoSimulacro"
ADD CONSTRAINT "IntentoSimulacro_usuarioId_fkey"
FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
```

### 20260825120000_add_batallas_asincronas

Fuente: backend/prisma/migrations/20260825120000_add_batallas_asincronas/migration.sql; SHA-256 05cf5d325ea7396772b2e7d2e3094471af8b0faa5387edcd27d0a5cfa8f0623f.

```sql
-- CreateEnum
CREATE TYPE "ModoBatalla" AS ENUM ('CARRERA_FANTASMA', 'DUELO_RELAMPAGO', 'SUPERVIVENCIA');

-- CreateEnum
CREATE TYPE "EstadoBatalla" AS ENUM ('BUSCANDO', 'PENDIENTE', 'ACTIVA', 'FINALIZADA', 'EXPIRADA', 'CANCELADA');

-- CreateEnum
CREATE TYPE "EstadoParticipanteBatalla" AS ENUM ('INVITADO', 'LISTO', 'EN_JUEGO', 'FINALIZADO');

-- CreateEnum
CREATE TYPE "ResultadoParticipanteBatalla" AS ENUM ('PENDIENTE', 'GANADA', 'PERDIDA', 'EMPATE');

-- AlterEnum
ALTER TYPE "OrigenRespuesta" ADD VALUE 'BATALLA';

-- CreateTable
CREATE TABLE "Batalla" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "modo" "ModoBatalla" NOT NULL,
    "estado" "EstadoBatalla" NOT NULL DEFAULT 'BUSCANDO',
    "area" "AreaIcfes",
    "retadorId" UUID NOT NULL,
    "rivalId" UUID,
    "ganadorId" UUID,
    "xpLiquidadoEn" TIMESTAMP(6),
    "expiraEn" TIMESTAMP(6) NOT NULL,
    "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "fechaActivacion" TIMESTAMP(6),
    "fechaFinalizacion" TIMESTAMP(6),

    CONSTRAINT "Batalla_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BatallaPregunta" (
    "batallaId" UUID NOT NULL,
    "preguntaId" TEXT NOT NULL,
    "orden" INTEGER NOT NULL,
    "opcionesOrden" JSONB NOT NULL,

    CONSTRAINT "BatallaPregunta_pkey" PRIMARY KEY ("batallaId", "preguntaId")
);

-- CreateTable
CREATE TABLE "BatallaParticipante" (
    "batallaId" UUID NOT NULL,
    "usuarioId" UUID NOT NULL,
    "estado" "EstadoParticipanteBatalla" NOT NULL DEFAULT 'LISTO',
    "resultado" "ResultadoParticipanteBatalla" NOT NULL DEFAULT 'PENDIENTE',
    "iniciadoEn" TIMESTAMP(6),
    "finalizadoEn" TIMESTAMP(6),
    "respuestasCorrectas" INTEGER NOT NULL DEFAULT 0,
    "tiempoTotalSegundos" INTEGER NOT NULL DEFAULT 0,
    "vidasRestantes" INTEGER,
    "xpElegible" BOOLEAN NOT NULL DEFAULT true,
    "xpGanado" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "BatallaParticipante_pkey" PRIMARY KEY ("batallaId", "usuarioId")
);

-- CreateTable
CREATE TABLE "BatallaRespuesta" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "batallaId" UUID NOT NULL,
    "usuarioId" UUID NOT NULL,
    "preguntaId" TEXT NOT NULL,
    "respuestaSeleccionadaId" TEXT NOT NULL,
    "orden" INTEGER NOT NULL,
    "esCorrecta" BOOLEAN NOT NULL,
    "tiempoRespuestaSegundos" INTEGER NOT NULL,
    "respondidaEn" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "BatallaRespuesta_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BatallaEstadistica" (
    "usuarioId" UUID NOT NULL,
    "batallasJugadas" INTEGER NOT NULL DEFAULT 0,
    "victorias" INTEGER NOT NULL DEFAULT 0,
    "derrotas" INTEGER NOT NULL DEFAULT 0,
    "empates" INTEGER NOT NULL DEFAULT 0,
    "rachaVictoriasActual" INTEGER NOT NULL DEFAULT 0,
    "mejorRachaVictorias" INTEGER NOT NULL DEFAULT 0,
    "victoriasPerfectas" INTEGER NOT NULL DEFAULT 0,
    "xpBatallas" INTEGER NOT NULL DEFAULT 0,
    "fechaActualizacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "BatallaEstadistica_pkey" PRIMARY KEY ("usuarioId")
);

-- CreateIndex
CREATE INDEX "Batalla_estado_modo_area_expiraEn_idx" ON "Batalla"("estado", "modo", "area", "expiraEn");
CREATE INDEX "Batalla_retadorId_fechaCreacion_idx" ON "Batalla"("retadorId", "fechaCreacion");
CREATE INDEX "Batalla_rivalId_fechaCreacion_idx" ON "Batalla"("rivalId", "fechaCreacion");
CREATE INDEX "Batalla_ganadorId_idx" ON "Batalla"("ganadorId");
CREATE UNIQUE INDEX "BatallaPregunta_batallaId_orden_key" ON "BatallaPregunta"("batallaId", "orden");
CREATE INDEX "BatallaPregunta_preguntaId_idx" ON "BatallaPregunta"("preguntaId");
CREATE INDEX "BatallaParticipante_usuarioId_finalizadoEn_idx" ON "BatallaParticipante"("usuarioId", "finalizadoEn");
CREATE INDEX "BatallaParticipante_usuarioId_resultado_finalizadoEn_idx" ON "BatallaParticipante"("usuarioId", "resultado", "finalizadoEn");
CREATE UNIQUE INDEX "BatallaRespuesta_batallaId_usuarioId_preguntaId_key" ON "BatallaRespuesta"("batallaId", "usuarioId", "preguntaId");
CREATE UNIQUE INDEX "BatallaRespuesta_batallaId_usuarioId_orden_key" ON "BatallaRespuesta"("batallaId", "usuarioId", "orden");
CREATE INDEX "BatallaRespuesta_batallaId_usuarioId_respondidaEn_idx" ON "BatallaRespuesta"("batallaId", "usuarioId", "respondidaEn");
CREATE INDEX "BatallaRespuesta_preguntaId_idx" ON "BatallaRespuesta"("preguntaId");

-- AddForeignKey
ALTER TABLE "Batalla" ADD CONSTRAINT "Batalla_retadorId_fkey" FOREIGN KEY ("retadorId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Batalla" ADD CONSTRAINT "Batalla_rivalId_fkey" FOREIGN KEY ("rivalId") REFERENCES "Usuario"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Batalla" ADD CONSTRAINT "Batalla_ganadorId_fkey" FOREIGN KEY ("ganadorId") REFERENCES "Usuario"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "BatallaPregunta" ADD CONSTRAINT "BatallaPregunta_batallaId_fkey" FOREIGN KEY ("batallaId") REFERENCES "Batalla"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "BatallaPregunta" ADD CONSTRAINT "BatallaPregunta_preguntaId_fkey" FOREIGN KEY ("preguntaId") REFERENCES "Pregunta"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "BatallaParticipante" ADD CONSTRAINT "BatallaParticipante_batallaId_fkey" FOREIGN KEY ("batallaId") REFERENCES "Batalla"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "BatallaParticipante" ADD CONSTRAINT "BatallaParticipante_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "BatallaRespuesta" ADD CONSTRAINT "BatallaRespuesta_batallaId_fkey" FOREIGN KEY ("batallaId") REFERENCES "Batalla"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "BatallaRespuesta" ADD CONSTRAINT "BatallaRespuesta_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "BatallaRespuesta" ADD CONSTRAINT "BatallaRespuesta_batallaId_usuarioId_fkey" FOREIGN KEY ("batallaId", "usuarioId") REFERENCES "BatallaParticipante"("batallaId", "usuarioId") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "BatallaRespuesta" ADD CONSTRAINT "BatallaRespuesta_preguntaId_fkey" FOREIGN KEY ("preguntaId") REFERENCES "Pregunta"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "BatallaRespuesta" ADD CONSTRAINT "BatallaRespuesta_respuestaSeleccionadaId_fkey" FOREIGN KEY ("respuestaSeleccionadaId") REFERENCES "Respuesta"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "BatallaEstadistica" ADD CONSTRAINT "BatallaEstadistica_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;
```

### 20260826110000_add_cuaderno_errores

Fuente: backend/prisma/migrations/20260826110000_add_cuaderno_errores/migration.sql; SHA-256 a5eb6adb253902cbdccae421c7aee1414ba88ad7bdb010b721c7e505b58246d5.

```sql
CREATE TYPE "EstadoCuadernoError" AS ENUM ('PENDIENTE', 'REPASANDO', 'DOMINADO');

CREATE TABLE "CuadernoError" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "usuarioId" UUID NOT NULL,
    "preguntaId" TEXT NOT NULL,
    "nota" TEXT,
    "estado" "EstadoCuadernoError" NOT NULL DEFAULT 'PENDIENTE',
    "dominadoEn" TIMESTAMP(6),
    "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "fechaActualizacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CuadernoError_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "CuadernoError_usuarioId_preguntaId_key"
ON "CuadernoError"("usuarioId", "preguntaId");

CREATE INDEX "CuadernoError_usuarioId_estado_fechaActualizacion_idx"
ON "CuadernoError"("usuarioId", "estado", "fechaActualizacion");

ALTER TABLE "CuadernoError"
ADD CONSTRAINT "CuadernoError_usuarioId_fkey"
FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "CuadernoError"
ADD CONSTRAINT "CuadernoError_preguntaId_fkey"
FOREIGN KEY ("preguntaId") REFERENCES "Pregunta"("id")
ON DELETE CASCADE ON UPDATE CASCADE;
```

### 20260826140000_add_origen_adaptativo

Fuente: backend/prisma/migrations/20260826140000_add_origen_adaptativo/migration.sql; SHA-256 570555204e6b17fc86c062e03eb80a3334722369225f26b1bc27ff7b44af8b1b.

```sql
ALTER TYPE "OrigenRespuesta" ADD VALUE 'ADAPTATIVO';
```

### 20260831120000_add_tira_afloja_tiempo_real

Fuente: backend/prisma/migrations/20260831120000_add_tira_afloja_tiempo_real/migration.sql; SHA-256 9cd12cd0e4ac58020c9288a1f3b58045d28b8bfb15f399e61ac7e6df11dc05c3.

```sql
-- CreateEnum
CREATE TYPE "EstadoPartidaTiraAfloja" AS ENUM ('BUSCANDO', 'PREPARANDO', 'ACTIVA', 'FINALIZADA', 'CANCELADA', 'EXPIRADA');

-- CreateEnum
CREATE TYPE "ResultadoPartidaTiraAfloja" AS ENUM ('JUGADOR_A', 'JUGADOR_B', 'EMPATE', 'CANCELADA');

-- CreateEnum
CREATE TYPE "TipoEventoTiraAfloja" AS ENUM ('BUSQUEDA_INICIADA', 'EMPAREJADA', 'RONDA_INICIADA', 'RONDA_RESUELTA', 'FINALIZADA', 'ABANDONO', 'CANCELADA');

-- CreateTable
CREATE TABLE "PartidaTiraAfloja" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "estado" "EstadoPartidaTiraAfloja" NOT NULL DEFAULT 'BUSCANDO',
    "resultado" "ResultadoPartidaTiraAfloja",
    "area" "AreaIcfes",
    "jugadorAId" UUID NOT NULL,
    "jugadorBId" UUID,
    "ganadorId" UUID,
    "posicionCuerda" INTEGER NOT NULL DEFAULT 0,
    "rondaActual" INTEGER NOT NULL DEFAULT 0,
    "version" INTEGER NOT NULL DEFAULT 0,
    "versionReglas" INTEGER NOT NULL DEFAULT 1,
    "listoA" BOOLEAN NOT NULL DEFAULT false,
    "listoB" BOOLEAN NOT NULL DEFAULT false,
    "preguntaActualId" TEXT,
    "rondaIniciaEn" TIMESTAMP(6),
    "rondaVenceEn" TIMESTAMP(6),
    "expiraEn" TIMESTAMP(6) NOT NULL,
    "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "fechaEmparejamiento" TIMESTAMP(6),
    "fechaFinalizacion" TIMESTAMP(6),

    CONSTRAINT "PartidaTiraAfloja_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TiraAflojaPregunta" (
    "partidaId" UUID NOT NULL,
    "preguntaId" TEXT NOT NULL,
    "orden" INTEGER NOT NULL,
    "opcionesOrden" JSONB NOT NULL,

    CONSTRAINT "TiraAflojaPregunta_pkey" PRIMARY KEY ("partidaId", "preguntaId")
);

-- CreateTable
CREATE TABLE "TiraAflojaRespuesta" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "partidaId" UUID NOT NULL,
    "ronda" INTEGER NOT NULL,
    "usuarioId" UUID NOT NULL,
    "preguntaId" TEXT NOT NULL,
    "respuestaSeleccionadaId" TEXT NOT NULL,
    "esCorrecta" BOOLEAN NOT NULL,
    "recibidaEn" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "claveIdempotencia" UUID NOT NULL,

    CONSTRAINT "TiraAflojaRespuesta_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TiraAflojaEvento" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "partidaId" UUID NOT NULL,
    "version" INTEGER NOT NULL,
    "tipo" "TipoEventoTiraAfloja" NOT NULL,
    "datos" JSONB NOT NULL,
    "fecha" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TiraAflojaEvento_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "PartidaTiraAfloja_estado_area_expiraEn_idx" ON "PartidaTiraAfloja"("estado", "area", "expiraEn");
CREATE INDEX "PartidaTiraAfloja_jugadorAId_estado_idx" ON "PartidaTiraAfloja"("jugadorAId", "estado");
CREATE INDEX "PartidaTiraAfloja_jugadorBId_estado_idx" ON "PartidaTiraAfloja"("jugadorBId", "estado");
CREATE INDEX "PartidaTiraAfloja_ganadorId_idx" ON "PartidaTiraAfloja"("ganadorId");
CREATE UNIQUE INDEX "TiraAflojaPregunta_partidaId_orden_key" ON "TiraAflojaPregunta"("partidaId", "orden");
CREATE INDEX "TiraAflojaPregunta_preguntaId_idx" ON "TiraAflojaPregunta"("preguntaId");
CREATE UNIQUE INDEX "TiraAflojaRespuesta_claveIdempotencia_key" ON "TiraAflojaRespuesta"("claveIdempotencia");
CREATE UNIQUE INDEX "TiraAflojaRespuesta_partidaId_ronda_usuarioId_key" ON "TiraAflojaRespuesta"("partidaId", "ronda", "usuarioId");
CREATE INDEX "TiraAflojaRespuesta_partidaId_ronda_recibidaEn_idx" ON "TiraAflojaRespuesta"("partidaId", "ronda", "recibidaEn");
CREATE INDEX "TiraAflojaRespuesta_usuarioId_recibidaEn_idx" ON "TiraAflojaRespuesta"("usuarioId", "recibidaEn");
CREATE INDEX "TiraAflojaRespuesta_preguntaId_idx" ON "TiraAflojaRespuesta"("preguntaId");
CREATE UNIQUE INDEX "TiraAflojaEvento_partidaId_version_key" ON "TiraAflojaEvento"("partidaId", "version");
CREATE INDEX "TiraAflojaEvento_partidaId_fecha_idx" ON "TiraAflojaEvento"("partidaId", "fecha");

-- AddForeignKey
ALTER TABLE "PartidaTiraAfloja" ADD CONSTRAINT "PartidaTiraAfloja_jugadorAId_fkey" FOREIGN KEY ("jugadorAId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PartidaTiraAfloja" ADD CONSTRAINT "PartidaTiraAfloja_jugadorBId_fkey" FOREIGN KEY ("jugadorBId") REFERENCES "Usuario"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "PartidaTiraAfloja" ADD CONSTRAINT "PartidaTiraAfloja_ganadorId_fkey" FOREIGN KEY ("ganadorId") REFERENCES "Usuario"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "PartidaTiraAfloja" ADD CONSTRAINT "PartidaTiraAfloja_preguntaActualId_fkey" FOREIGN KEY ("preguntaActualId") REFERENCES "Pregunta"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "TiraAflojaPregunta" ADD CONSTRAINT "TiraAflojaPregunta_partidaId_fkey" FOREIGN KEY ("partidaId") REFERENCES "PartidaTiraAfloja"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "TiraAflojaPregunta" ADD CONSTRAINT "TiraAflojaPregunta_preguntaId_fkey" FOREIGN KEY ("preguntaId") REFERENCES "Pregunta"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "TiraAflojaRespuesta" ADD CONSTRAINT "TiraAflojaRespuesta_partidaId_fkey" FOREIGN KEY ("partidaId") REFERENCES "PartidaTiraAfloja"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "TiraAflojaRespuesta" ADD CONSTRAINT "TiraAflojaRespuesta_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "TiraAflojaRespuesta" ADD CONSTRAINT "TiraAflojaRespuesta_preguntaId_fkey" FOREIGN KEY ("preguntaId") REFERENCES "Pregunta"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "TiraAflojaRespuesta" ADD CONSTRAINT "TiraAflojaRespuesta_respuestaSeleccionadaId_fkey" FOREIGN KEY ("respuestaSeleccionadaId") REFERENCES "Respuesta"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "TiraAflojaEvento" ADD CONSTRAINT "TiraAflojaEvento_partidaId_fkey" FOREIGN KEY ("partidaId") REFERENCES "PartidaTiraAfloja"("id") ON DELETE CASCADE ON UPDATE CASCADE;
```

### 20260831183000_add_trivia_rush_autoritativo

Fuente: backend/prisma/migrations/20260831183000_add_trivia_rush_autoritativo/migration.sql; SHA-256 b63b89a3171d3cfa256412a07857de23c1834735745fb2bfe123b40329475cda.

```sql
-- AlterEnum
ALTER TYPE "OrigenRespuesta" ADD VALUE 'TRIVIA_RUSH';

-- CreateEnum
CREATE TYPE "EstadoIntentoTriviaRush" AS ENUM ('ACTIVO', 'FINALIZADO', 'EXPIRADO', 'ABANDONADO');

-- CreateEnum
CREATE TYPE "TipoPotenciadorTriviaRush" AS ENUM ('TIEMPO_EXTRA', 'CINCUENTA_CINCUENTA', 'ESCUDO_COMBO', 'SALTAR', 'SEGUNDA_OPORTUNIDAD');

-- CreateEnum
CREATE TYPE "EstadoConcesionRecompensa" AS ENUM ('DISPONIBLE', 'CONSUMIDA', 'EXPIRADA');

-- CreateTable
CREATE TABLE "IntentoTriviaRush" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "usuarioId" UUID NOT NULL,
    "estado" "EstadoIntentoTriviaRush" NOT NULL DEFAULT 'ACTIVO',
    "areas" "AreaIcfes"[],
    "duracionBaseSegundos" INTEGER NOT NULL,
    "tiempoExtraSegundos" INTEGER NOT NULL DEFAULT 0,
    "versionReglas" INTEGER NOT NULL DEFAULT 1,
    "puntaje" INTEGER NOT NULL DEFAULT 0,
    "comboActual" INTEGER NOT NULL DEFAULT 0,
    "mejorCombo" INTEGER NOT NULL DEFAULT 0,
    "respuestasCorrectas" INTEGER NOT NULL DEFAULT 0,
    "respuestasIncorrectas" INTEGER NOT NULL DEFAULT 0,
    "preguntasSaltadas" INTEGER NOT NULL DEFAULT 0,
    "indiceActual" INTEGER NOT NULL DEFAULT 0,
    "asistido" BOOLEAN NOT NULL DEFAULT false,
    "escudoComboActivo" BOOLEAN NOT NULL DEFAULT false,
    "segundaOportunidadActiva" BOOLEAN NOT NULL DEFAULT false,
    "preguntaActualId" TEXT,
    "preguntaIniciaEn" TIMESTAMP(6),
    "iniciadoEn" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "venceEn" TIMESTAMP(6) NOT NULL,
    "finalizadoEn" TIMESTAMP(6),

    CONSTRAINT "IntentoTriviaRush_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TriviaRushPregunta" (
    "intentoId" UUID NOT NULL,
    "preguntaId" TEXT NOT NULL,
    "orden" INTEGER NOT NULL,
    "opcionesOrden" JSONB NOT NULL,

    CONSTRAINT "TriviaRushPregunta_pkey" PRIMARY KEY ("intentoId", "preguntaId")
);

-- CreateTable
CREATE TABLE "TriviaRushRespuesta" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "intentoId" UUID NOT NULL,
    "preguntaId" TEXT NOT NULL,
    "respuestaSeleccionadaId" TEXT,
    "numeroIntento" INTEGER NOT NULL,
    "esCorrecta" BOOLEAN NOT NULL,
    "esFinal" BOOLEAN NOT NULL,
    "puntosOtorgados" INTEGER NOT NULL DEFAULT 0,
    "comboResultante" INTEGER NOT NULL,
    "tiempoRespuestaMs" INTEGER NOT NULL,
    "claveIdempotencia" UUID NOT NULL,
    "respondidaEn" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TriviaRushRespuesta_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ConcesionRecompensaJuego" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "usuarioId" UUID NOT NULL,
    "proveedor" VARCHAR(30) NOT NULL,
    "referenciaProveedor" VARCHAR(180) NOT NULL,
    "estado" "EstadoConcesionRecompensa" NOT NULL DEFAULT 'DISPONIBLE',
    "expiraEn" TIMESTAMP(6) NOT NULL,
    "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "consumidaEn" TIMESTAMP(6),

    CONSTRAINT "ConcesionRecompensaJuego_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TriviaRushPotenciador" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "intentoId" UUID NOT NULL,
    "preguntaId" TEXT,
    "tipo" "TipoPotenciadorTriviaRush" NOT NULL,
    "concesionId" UUID NOT NULL,
    "claveIdempotencia" UUID NOT NULL,
    "opcionesEliminadas" JSONB,
    "activadoEn" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TriviaRushPotenciador_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "IntentoTriviaRush_usuarioId_estado_iniciadoEn_idx" ON "IntentoTriviaRush"("usuarioId", "estado", "iniciadoEn");
CREATE INDEX "IntentoTriviaRush_estado_venceEn_idx" ON "IntentoTriviaRush"("estado", "venceEn");
CREATE INDEX "IntentoTriviaRush_preguntaActualId_idx" ON "IntentoTriviaRush"("preguntaActualId");
CREATE UNIQUE INDEX "TriviaRushPregunta_intentoId_orden_key" ON "TriviaRushPregunta"("intentoId", "orden");
CREATE INDEX "TriviaRushPregunta_preguntaId_idx" ON "TriviaRushPregunta"("preguntaId");
CREATE UNIQUE INDEX "TriviaRushRespuesta_claveIdempotencia_key" ON "TriviaRushRespuesta"("claveIdempotencia");
CREATE UNIQUE INDEX "TriviaRushRespuesta_intentoId_preguntaId_numeroIntento_key" ON "TriviaRushRespuesta"("intentoId", "preguntaId", "numeroIntento");
CREATE INDEX "TriviaRushRespuesta_intentoId_esFinal_respondidaEn_idx" ON "TriviaRushRespuesta"("intentoId", "esFinal", "respondidaEn");
CREATE INDEX "TriviaRushRespuesta_preguntaId_idx" ON "TriviaRushRespuesta"("preguntaId");
CREATE UNIQUE INDEX "ConcesionRecompensaJuego_referenciaProveedor_key" ON "ConcesionRecompensaJuego"("referenciaProveedor");
CREATE INDEX "ConcesionRecompensaJuego_usuarioId_estado_expiraEn_idx" ON "ConcesionRecompensaJuego"("usuarioId", "estado", "expiraEn");
CREATE UNIQUE INDEX "TriviaRushPotenciador_concesionId_key" ON "TriviaRushPotenciador"("concesionId");
CREATE UNIQUE INDEX "TriviaRushPotenciador_claveIdempotencia_key" ON "TriviaRushPotenciador"("claveIdempotencia");
CREATE INDEX "TriviaRushPotenciador_intentoId_preguntaId_tipo_idx" ON "TriviaRushPotenciador"("intentoId", "preguntaId", "tipo");

-- AddForeignKey
ALTER TABLE "IntentoTriviaRush" ADD CONSTRAINT "IntentoTriviaRush_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "IntentoTriviaRush" ADD CONSTRAINT "IntentoTriviaRush_preguntaActualId_fkey" FOREIGN KEY ("preguntaActualId") REFERENCES "Pregunta"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "TriviaRushPregunta" ADD CONSTRAINT "TriviaRushPregunta_intentoId_fkey" FOREIGN KEY ("intentoId") REFERENCES "IntentoTriviaRush"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "TriviaRushPregunta" ADD CONSTRAINT "TriviaRushPregunta_preguntaId_fkey" FOREIGN KEY ("preguntaId") REFERENCES "Pregunta"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "TriviaRushRespuesta" ADD CONSTRAINT "TriviaRushRespuesta_intentoId_fkey" FOREIGN KEY ("intentoId") REFERENCES "IntentoTriviaRush"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "TriviaRushRespuesta" ADD CONSTRAINT "TriviaRushRespuesta_preguntaId_fkey" FOREIGN KEY ("preguntaId") REFERENCES "Pregunta"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "TriviaRushRespuesta" ADD CONSTRAINT "TriviaRushRespuesta_respuestaSeleccionadaId_fkey" FOREIGN KEY ("respuestaSeleccionadaId") REFERENCES "Respuesta"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ConcesionRecompensaJuego" ADD CONSTRAINT "ConcesionRecompensaJuego_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "TriviaRushPotenciador" ADD CONSTRAINT "TriviaRushPotenciador_intentoId_fkey" FOREIGN KEY ("intentoId") REFERENCES "IntentoTriviaRush"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "TriviaRushPotenciador" ADD CONSTRAINT "TriviaRushPotenciador_preguntaId_fkey" FOREIGN KEY ("preguntaId") REFERENCES "Pregunta"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "TriviaRushPotenciador" ADD CONSTRAINT "TriviaRushPotenciador_concesionId_fkey" FOREIGN KEY ("concesionId") REFERENCES "ConcesionRecompensaJuego"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
```

### 20260831213000_harden_batallas_asincronas

Fuente: backend/prisma/migrations/20260831213000_harden_batallas_asincronas/migration.sql; SHA-256 3d4027e152a94d3db0f42bd6269da6ce5e7cc3bbdeabb903548584e35ae8a02b.

```sql
-- CreateEnum
CREATE TYPE "MotivoReporteBatalla" AS ENUM ('CONDUCTA_INAPROPIADA', 'NOMBRE_INAPROPIADO', 'TRAMPA', 'OTRO');

-- CreateEnum
CREATE TYPE "EstadoReporteBatalla" AS ENUM ('RECIBIDO', 'EN_REVISION', 'RESUELTO', 'DESCARTADO');

-- AlterTable
ALTER TABLE "Batalla" ADD COLUMN "codigoInvitacion" VARCHAR(8);

-- CreateTable
CREATE TABLE "BatallaBloqueo" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "bloqueadorId" UUID NOT NULL,
    "bloqueadoId" UUID NOT NULL,
    "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "BatallaBloqueo_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BatallaReporte" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "batallaId" UUID NOT NULL,
    "reportanteId" UUID NOT NULL,
    "reportadoId" UUID NOT NULL,
    "motivo" "MotivoReporteBatalla" NOT NULL,
    "detalle" VARCHAR(500),
    "estado" "EstadoReporteBatalla" NOT NULL DEFAULT 'RECIBIDO',
    "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "BatallaReporte_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Batalla_codigoInvitacion_key" ON "Batalla"("codigoInvitacion");
CREATE UNIQUE INDEX "BatallaBloqueo_bloqueadorId_bloqueadoId_key" ON "BatallaBloqueo"("bloqueadorId", "bloqueadoId");
CREATE INDEX "BatallaBloqueo_bloqueadoId_fechaCreacion_idx" ON "BatallaBloqueo"("bloqueadoId", "fechaCreacion");
CREATE UNIQUE INDEX "BatallaReporte_batallaId_reportanteId_key" ON "BatallaReporte"("batallaId", "reportanteId");
CREATE INDEX "BatallaReporte_reportadoId_estado_fechaCreacion_idx" ON "BatallaReporte"("reportadoId", "estado", "fechaCreacion");

-- AddForeignKey
ALTER TABLE "BatallaBloqueo" ADD CONSTRAINT "BatallaBloqueo_bloqueadorId_fkey" FOREIGN KEY ("bloqueadorId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "BatallaBloqueo" ADD CONSTRAINT "BatallaBloqueo_bloqueadoId_fkey" FOREIGN KEY ("bloqueadoId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "BatallaReporte" ADD CONSTRAINT "BatallaReporte_batallaId_fkey" FOREIGN KEY ("batallaId") REFERENCES "Batalla"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "BatallaReporte" ADD CONSTRAINT "BatallaReporte_reportanteId_fkey" FOREIGN KEY ("reportanteId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "BatallaReporte" ADD CONSTRAINT "BatallaReporte_reportadoId_fkey" FOREIGN KEY ("reportadoId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;
```

### 20260831233000_teacher_institution_membership

Fuente: backend/prisma/migrations/20260831233000_teacher_institution_membership/migration.sql; SHA-256 19bbbcbfaa3ebc3ea49bd34ce3942783504e51a762246100a961efff2e59c47d.

```sql
-- CreateEnum
CREATE TYPE "RolMembresiaInstitucion" AS ENUM ('PROPIETARIO', 'ADMINISTRADOR', 'PROFESOR');

-- CreateEnum
CREATE TYPE "EstadoSolicitudIngresoInstitucion" AS ENUM ('PENDIENTE', 'APROBADA', 'RECHAZADA', 'CANCELADA');

-- CreateTable
CREATE TABLE "MiembroInstitucion" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "institucionId" UUID NOT NULL,
    "usuarioId" UUID NOT NULL,
    "rol" "RolMembresiaInstitucion" NOT NULL DEFAULT 'PROFESOR',
    "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "fechaActualizacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MiembroInstitucion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SolicitudIngresoInstitucion" (
    "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "institucionId" UUID NOT NULL,
    "solicitanteId" UUID NOT NULL,
    "estado" "EstadoSolicitudIngresoInstitucion" NOT NULL DEFAULT 'PENDIENTE',
    "mensaje" VARCHAR(500),
    "revisadoPorId" UUID,
    "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "fechaActualizacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SolicitudIngresoInstitucion_pkey" PRIMARY KEY ("id")
);

-- Backfill memberships for existing teachers and platform administrators.
WITH miembros_existentes AS (
    SELECT
        u."id" AS "usuarioId",
        u."institucionId",
        u."rol",
        ROW_NUMBER() OVER (
            PARTITION BY u."institucionId"
            ORDER BY u."fechaCreacion" ASC NULLS LAST, u."id" ASC
        ) AS posicion
    FROM "Usuario" u
    WHERE u."institucionId" IS NOT NULL
      AND u."rol" IN ('PROFESOR', 'ADMIN')
)
INSERT INTO "MiembroInstitucion" ("institucionId", "usuarioId", "rol")
SELECT
    "institucionId",
    "usuarioId",
    CASE
        WHEN posicion = 1 THEN 'PROPIETARIO'::"RolMembresiaInstitucion"
        WHEN "rol" = 'ADMIN' THEN 'ADMINISTRADOR'::"RolMembresiaInstitucion"
        ELSE 'PROFESOR'::"RolMembresiaInstitucion"
    END
FROM miembros_existentes;

-- CreateIndex
CREATE UNIQUE INDEX "MiembroInstitucion_usuarioId_key" ON "MiembroInstitucion"("usuarioId");
CREATE UNIQUE INDEX "MiembroInstitucion_institucionId_usuarioId_key" ON "MiembroInstitucion"("institucionId", "usuarioId");
CREATE INDEX "MiembroInstitucion_institucionId_rol_idx" ON "MiembroInstitucion"("institucionId", "rol");
CREATE INDEX "SolicitudIngresoInstitucion_institucionId_estado_fechaCreacion_idx" ON "SolicitudIngresoInstitucion"("institucionId", "estado", "fechaCreacion");
CREATE INDEX "SolicitudIngresoInstitucion_solicitanteId_estado_fechaCreacion_idx" ON "SolicitudIngresoInstitucion"("solicitanteId", "estado", "fechaCreacion");
CREATE UNIQUE INDEX "SolicitudIngresoInstitucion_solicitante_pendiente_key" ON "SolicitudIngresoInstitucion"("solicitanteId") WHERE "estado" = 'PENDIENTE';

-- AddForeignKey
ALTER TABLE "MiembroInstitucion" ADD CONSTRAINT "MiembroInstitucion_institucionId_fkey" FOREIGN KEY ("institucionId") REFERENCES "Institucion"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "MiembroInstitucion" ADD CONSTRAINT "MiembroInstitucion_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SolicitudIngresoInstitucion" ADD CONSTRAINT "SolicitudIngresoInstitucion_institucionId_fkey" FOREIGN KEY ("institucionId") REFERENCES "Institucion"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SolicitudIngresoInstitucion" ADD CONSTRAINT "SolicitudIngresoInstitucion_solicitanteId_fkey" FOREIGN KEY ("solicitanteId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "SolicitudIngresoInstitucion" ADD CONSTRAINT "SolicitudIngresoInstitucion_revisadoPorId_fkey" FOREIGN KEY ("revisadoPorId") REFERENCES "Usuario"("id") ON DELETE SET NULL ON UPDATE CASCADE;
```

### 20260901063000_institution_administration

Fuente: backend/prisma/migrations/20260901063000_institution_administration/migration.sql; SHA-256 30e1e7f48c3ff76f7b561883c50a47dff28769a408c7a3d465fda720bd3c7a53.

```sql
CREATE TYPE "EstadoInvitacionInstitucion" AS ENUM (
  'PENDIENTE',
  'ACEPTADA',
  'RECHAZADA',
  'CANCELADA',
  'EXPIRADA'
);

CREATE TABLE "InvitacionInstitucion" (
  "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
  "institucionId" UUID NOT NULL,
  "correo" VARCHAR(255) NOT NULL,
  "rol" "RolMembresiaInstitucion" NOT NULL DEFAULT 'PROFESOR',
  "estado" "EstadoInvitacionInstitucion" NOT NULL DEFAULT 'PENDIENTE',
  "creadoPorId" UUID NOT NULL,
  "aceptadoPorId" UUID,
  "fechaExpiracion" TIMESTAMP(6) NOT NULL,
  "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "fechaActualizacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "InvitacionInstitucion_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "AuditoriaInstitucion" (
  "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
  "institucionId" UUID NOT NULL,
  "accion" VARCHAR(60) NOT NULL,
  "actorId" UUID,
  "afectadoId" UUID,
  "detalle" JSONB,
  "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "AuditoriaInstitucion_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "InvitacionInstitucion_institucion_estado_fecha_idx"
  ON "InvitacionInstitucion"("institucionId", "estado", "fechaCreacion");
CREATE INDEX "InvitacionInstitucion_correo_estado_expiracion_idx"
  ON "InvitacionInstitucion"("correo", "estado", "fechaExpiracion");
CREATE UNIQUE INDEX "InvitacionInstitucion_pendiente_por_correo_key"
  ON "InvitacionInstitucion"("institucionId", LOWER("correo"))
  WHERE "estado" = 'PENDIENTE';
CREATE UNIQUE INDEX "MiembroInstitucion_un_propietario_key"
  ON "MiembroInstitucion"("institucionId")
  WHERE "rol" = 'PROPIETARIO';
CREATE INDEX "AuditoriaInstitucion_institucion_fecha_idx"
  ON "AuditoriaInstitucion"("institucionId", "fechaCreacion");
CREATE INDEX "AuditoriaInstitucion_actor_fecha_idx"
  ON "AuditoriaInstitucion"("actorId", "fechaCreacion");

ALTER TABLE "InvitacionInstitucion"
  ADD CONSTRAINT "InvitacionInstitucion_institucionId_fkey"
  FOREIGN KEY ("institucionId") REFERENCES "Institucion"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "InvitacionInstitucion"
  ADD CONSTRAINT "InvitacionInstitucion_creadoPorId_fkey"
  FOREIGN KEY ("creadoPorId") REFERENCES "Usuario"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "InvitacionInstitucion"
  ADD CONSTRAINT "InvitacionInstitucion_aceptadoPorId_fkey"
  FOREIGN KEY ("aceptadoPorId") REFERENCES "Usuario"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "AuditoriaInstitucion"
  ADD CONSTRAINT "AuditoriaInstitucion_institucionId_fkey"
  FOREIGN KEY ("institucionId") REFERENCES "Institucion"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "AuditoriaInstitucion"
  ADD CONSTRAINT "AuditoriaInstitucion_actorId_fkey"
  FOREIGN KEY ("actorId") REFERENCES "Usuario"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "AuditoriaInstitucion"
  ADD CONSTRAINT "AuditoriaInstitucion_afectadoId_fkey"
  FOREIGN KEY ("afectadoId") REFERENCES "Usuario"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;
```

### 20260901143000_temporary_group_codes

Fuente: backend/prisma/migrations/20260901143000_temporary_group_codes/migration.sql; SHA-256 b534fb6a9ce130864f8142b405433f7782d7aafe51d2e43a74e00abc1d31168d.

```sql
ALTER TABLE "ClaseEstudiante"
  ADD COLUMN "codigoTemporalId" UUID,
  ADD COLUMN "aceptacionExplicita" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "fechaIngreso" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE TABLE "ClaseProfesor" (
  "claseId" UUID NOT NULL,
  "miembroId" UUID NOT NULL,
  "fechaAsignacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "ClaseProfesor_pkey" PRIMARY KEY ("claseId", "miembroId")
);

CREATE TABLE "CodigoTemporalGrupo" (
  "id" UUID NOT NULL DEFAULT uuid_generate_v4(),
  "claseId" UUID NOT NULL,
  "codigoHash" VARCHAR(64) NOT NULL,
  "sufijo" VARCHAR(4) NOT NULL,
  "activo" BOOLEAN NOT NULL DEFAULT true,
  "usos" INTEGER NOT NULL DEFAULT 0,
  "usosMaximos" INTEGER NOT NULL,
  "fechaExpiracion" TIMESTAMP(6) NOT NULL,
  "fechaCreacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "creadoPorId" UUID NOT NULL,

  CONSTRAINT "CodigoTemporalGrupo_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "CodigoTemporalGrupo_usos_check"
    CHECK ("usos" >= 0 AND "usosMaximos" >= 1 AND "usos" <= "usosMaximos")
);

CREATE UNIQUE INDEX "CodigoTemporalGrupo_codigoHash_key"
  ON "CodigoTemporalGrupo"("codigoHash");
CREATE INDEX "CodigoTemporalGrupo_clase_activo_expira_idx"
  ON "CodigoTemporalGrupo"("claseId", "activo", "fechaExpiracion");
CREATE INDEX "CodigoTemporalGrupo_creador_fecha_idx"
  ON "CodigoTemporalGrupo"("creadoPorId", "fechaCreacion");
CREATE INDEX "ClaseProfesor_miembro_fecha_idx"
  ON "ClaseProfesor"("miembroId", "fechaAsignacion");
CREATE INDEX "ClaseEstudiante_codigoTemporalId_idx"
  ON "ClaseEstudiante"("codigoTemporalId");

ALTER TABLE "ClaseProfesor"
  ADD CONSTRAINT "ClaseProfesor_claseId_fkey"
  FOREIGN KEY ("claseId") REFERENCES "Clase"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ClaseProfesor"
  ADD CONSTRAINT "ClaseProfesor_miembroId_fkey"
  FOREIGN KEY ("miembroId") REFERENCES "MiembroInstitucion"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CodigoTemporalGrupo"
  ADD CONSTRAINT "CodigoTemporalGrupo_claseId_fkey"
  FOREIGN KEY ("claseId") REFERENCES "Clase"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CodigoTemporalGrupo"
  ADD CONSTRAINT "CodigoTemporalGrupo_creadoPorId_fkey"
  FOREIGN KEY ("creadoPorId") REFERENCES "MiembroInstitucion"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ClaseEstudiante"
  ADD CONSTRAINT "ClaseEstudiante_codigoTemporalId_fkey"
  FOREIGN KEY ("codigoTemporalId") REFERENCES "CodigoTemporalGrupo"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;

-- Los grupos existentes quedan administrables por su propietario institucional.
INSERT INTO "ClaseProfesor" ("claseId", "miembroId")
SELECT clase."id", miembro."id"
FROM "Clase" AS clase
JOIN "MiembroInstitucion" AS miembro
  ON miembro."institucionId" = clase."institucionId"
 AND miembro."rol" = 'PROPIETARIO'
ON CONFLICT DO NOTHING;
```

### 20260901193000_teacher_free_plan_limits

Fuente: backend/prisma/migrations/20260901193000_teacher_free_plan_limits/migration.sql; SHA-256 5a20e1f4a07faa811113b427258aad4ae1a59d55c7c9cd17f5981a2b4c152975.

```sql
ALTER TABLE "Institucion"
ADD COLUMN "limiteGrupos" INTEGER;

UPDATE "Institucion"
SET "limiteGrupos" = CASE
  WHEN UPPER(COALESCE("planActual", 'GRATIS')) = 'GRATIS' THEN 1
  ELSE 5
END
WHERE "limiteGrupos" IS NULL;

UPDATE "Institucion"
SET "limiteEstudiantes" = CASE
  WHEN UPPER(COALESCE("planActual", 'GRATIS')) = 'GRATIS' THEN 40
  ELSE 200
END
WHERE "limiteEstudiantes" IS NOT NULL
  AND "limiteEstudiantes" < 1;

ALTER TABLE "Institucion"
ADD CONSTRAINT "Institucion_limiteGrupos_check"
CHECK ("limiteGrupos" IS NULL OR "limiteGrupos" >= 1);

ALTER TABLE "Institucion"
ADD CONSTRAINT "Institucion_limiteEstudiantes_check"
CHECK ("limiteEstudiantes" IS NULL OR "limiteEstudiantes" >= 1);
```

### 20260905013000_content_lifecycle

Fuente: backend/prisma/migrations/20260905013000_content_lifecycle/migration.sql; SHA-256 d7218a1351a3dfda77a855ca82ccd8d6c4e5e44efdd89667fa58b265c2850741.

```sql
CREATE TYPE "EstadoContenido" AS ENUM (
  'BORRADOR',
  'EN_REVISION',
  'PUBLICADO',
  'ARCHIVADO'
);

ALTER TABLE "Tema"
ADD COLUMN "estadoContenido" "EstadoContenido" NOT NULL DEFAULT 'BORRADOR',
ADD COLUMN "fechaPublicacion" TIMESTAMP(6),
ADD COLUMN "fechaActualizacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE "Subtema"
ADD COLUMN "estadoContenido" "EstadoContenido" NOT NULL DEFAULT 'BORRADOR',
ADD COLUMN "fechaPublicacion" TIMESTAMP(6),
ADD COLUMN "fechaActualizacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE "Pregunta"
ADD COLUMN "estadoContenido" "EstadoContenido" NOT NULL DEFAULT 'BORRADOR',
ADD COLUMN "fechaPublicacion" TIMESTAMP(6),
ADD COLUMN "fechaActualizacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE "CasoPregunta"
ADD COLUMN "estadoContenido" "EstadoContenido" NOT NULL DEFAULT 'BORRADOR',
ADD COLUMN "fechaPublicacion" TIMESTAMP(6),
ADD COLUMN "fechaActualizacion" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- El contenido previo requiere revisión explícita antes de publicarse en la app.
UPDATE "Tema" SET "estadoContenido" = 'ARCHIVADO';
UPDATE "Subtema" SET "estadoContenido" = 'ARCHIVADO';
UPDATE "Pregunta" SET "estadoContenido" = 'ARCHIVADO';
UPDATE "CasoPregunta" SET "estadoContenido" = 'ARCHIVADO';

CREATE INDEX "Tema_estadoContenido_area_idx"
ON "Tema"("estadoContenido", "area");

CREATE INDEX "Subtema_estadoContenido_temaId_idx"
ON "Subtema"("estadoContenido", "temaId");

CREATE INDEX "Pregunta_estadoContenido_subtemaId_idx"
ON "Pregunta"("estadoContenido", "subtemaId");

CREATE INDEX "CasoPregunta_estadoContenido_area_idx"
ON "CasoPregunta"("estadoContenido", "area");
```

### 20260905043000_question_content_fingerprint

Fuente: backend/prisma/migrations/20260905043000_question_content_fingerprint/migration.sql; SHA-256 9dfba1b94753d3c39912ea36185a8a3115d5e5ec52dacd52191ff25244dc9bde.

```sql
ALTER TABLE "Pregunta"
ADD COLUMN "huellaContenido" VARCHAR(64);

CREATE INDEX "Pregunta_huellaContenido_estadoContenido_idx"
ON "Pregunta"("huellaContenido", "estadoContenido");
```

### 20260905180000_guardian_challenge

Fuente: backend/prisma/migrations/20260905180000_guardian_challenge/migration.sql; SHA-256 6da68d53f13f8e0604c09df167e12133a82d9179459c103665bb88d2335bc37b.

```sql
CREATE TABLE "IntentoGuardian" (
  "id" UUID NOT NULL,
  "usuarioId" UUID NOT NULL,
  "area" "AreaIcfes" NOT NULL,
  "subtemaId" TEXT,
  "dificultad" "Dificultad" NOT NULL,
  "version" INTEGER NOT NULL DEFAULT 1,
  "estado" VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
  "preguntas" JSONB NOT NULL,
  "respuestas" JSONB NOT NULL DEFAULT '[]',
  "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "venceEn" TIMESTAMP(3) NOT NULL,
  "finalizadoEn" TIMESTAMP(3),
  CONSTRAINT "IntentoGuardian_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "IntentoGuardian_estado_check" CHECK ("estado" IN ('ACTIVO', 'VICTORIA', 'DERROTA', 'ABANDONADO', 'EXPIRADO')),
  CONSTRAINT "IntentoGuardian_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "IntentoGuardian_usuarioId_creadoEn_idx" ON "IntentoGuardian"("usuarioId", "creadoEn");
CREATE UNIQUE INDEX "IntentoGuardian_un_activo" ON "IntentoGuardian"("usuarioId") WHERE "estado" = 'ACTIVO';
-- Solo la API accede a snapshots con respuestas correctas.
ALTER TABLE "IntentoGuardian" ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON TABLE "IntentoGuardian" FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    REVOKE ALL ON TABLE "IntentoGuardian" FROM authenticated;
  END IF;
END $$;
```

### 20260913090000_teacher_priorities

Fuente: backend/prisma/migrations/20260913090000_teacher_priorities/migration.sql; SHA-256 f26b61d8235f8d52667622eace970423444818feba9d82b42ae098ab68be751d.

```sql
CREATE TABLE "PrioridadDocente" (
    "id" UUID NOT NULL,
    "claseId" UUID NOT NULL,
    "creadoPorId" UUID NOT NULL,
    "huellaSolicitud" VARCHAR(64) NOT NULL,
    "area" "AreaIcfes" NOT NULL,
    "temaId" TEXT NOT NULL,
    "temaNombre" TEXT NOT NULL,
    "subtemaId" TEXT,
    "subtemaNombre" TEXT,
    "preguntaIds" TEXT[] NOT NULL,
    "metaPreguntas" INTEGER NOT NULL DEFAULT 5,
    "creadoEn" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "venceEn" TIMESTAMP(6) NOT NULL,
    "retiradoEn" TIMESTAMP(6),
    CONSTRAINT "PrioridadDocente_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "PrioridadDocente_claseId_fkey" FOREIGN KEY ("claseId") REFERENCES "Clase"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "PrioridadDocente_meta_check" CHECK ("metaPreguntas" = 5 AND cardinality("preguntaIds") BETWEEN 5 AND 2000),
    CONSTRAINT "PrioridadDocente_plazo_check" CHECK ("venceEn" > "creadoEn" AND "venceEn" <= "creadoEn" + INTERVAL '30 days'),
    CONSTRAINT "PrioridadDocente_retiro_check" CHECK ("retiradoEn" IS NULL OR "retiradoEn" >= "creadoEn")
);
CREATE INDEX "PrioridadDocente_claseId_creadoEn_id_idx" ON "PrioridadDocente"("claseId", "creadoEn", "id");
CREATE INDEX "PrioridadDocente_claseId_retiradoEn_venceEn_idx" ON "PrioridadDocente"("claseId", "retiradoEn", "venceEn");

-- Solo el backend accede a esta tabla. Sin políticas públicas de Supabase.
ALTER TABLE "PrioridadDocente" ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON TABLE "PrioridadDocente" FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    REVOKE ALL ON TABLE "PrioridadDocente" FROM authenticated;
  END IF;
END $$;
```

### 20260914090000_study_time_pomodoros

Fuente: backend/prisma/migrations/20260914090000_study_time_pomodoros/migration.sql; SHA-256 5082d0ecc8a14d6191b106ff4c043e05e3926f6698c257358185fe1858a9b758.

```sql
CREATE TABLE "PomodoroRegistrado" (
    "usuarioId" UUID NOT NULL,
    "eventoId" VARCHAR(80) NOT NULL,
    "duracionSegundos" INTEGER NOT NULL DEFAULT 1500,
    "finalizadoEn" TIMESTAMP(3) NOT NULL,
    "recibidoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PomodoroRegistrado_pkey" PRIMARY KEY ("usuarioId", "eventoId"),
    CONSTRAINT "PomodoroRegistrado_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "PomodoroRegistrado_duracion_check" CHECK ("duracionSegundos" = 1500),
    CONSTRAINT "PomodoroRegistrado_evento_check" CHECK ("eventoId" ~ '^pomodoro:([0-9]{13,20}|[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})$')
);
CREATE UNIQUE INDEX "PomodoroRegistrado_usuarioId_finalizadoEn_key" ON "PomodoroRegistrado"("usuarioId", "finalizadoEn");
ALTER TABLE "PomodoroRegistrado" ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON TABLE "PomodoroRegistrado" FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    REVOKE ALL ON TABLE "PomodoroRegistrado" FROM authenticated;
  END IF;
END $$;
```

### 20260917130000_institution_approval

Fuente: backend/prisma/migrations/20260917130000_institution_approval/migration.sql; SHA-256 c19cc6aeaea0d6b4d3eecbbba1d1a94a4259c8de522d1ab475b9b46f0dc77df1.

```sql
CREATE TYPE "EstadoAltaInstitucion" AS ENUM ('PENDIENTE', 'REQUIERE_INFORMACION', 'APROBADA', 'RECHAZADA', 'SUSPENDIDA', 'LEGADO_EN_REVISION');
ALTER TABLE "Institucion" ADD COLUMN "estadoVerificacion" "EstadoAltaInstitucion" NOT NULL DEFAULT 'PENDIENTE', ADD COLUMN "transicionHasta" TIMESTAMP(3);
-- Solo las instituciones que ya existen reciben una transición visible de 30 días.
-- No equivale a una aprobación. Revisar la fecha de despliegue antes de aplicar.
UPDATE "Institucion" SET "estadoVerificacion" = 'LEGADO_EN_REVISION', "transicionHasta" = CURRENT_TIMESTAMP + INTERVAL '30 days';
CREATE TABLE "SolicitudAltaInstitucion" (
  "id" UUID NOT NULL,
  "solicitanteId" UUID,
  "institucionId" UUID,
  "nombre" VARCHAR(120) NOT NULL,
  "nombreNormalizado" VARCHAR(120) NOT NULL,
  "ciudad" VARCHAR(120) NOT NULL,
  "ciudadNormalizada" VARCHAR(120) NOT NULL,
  "correoInstitucional" VARCHAR(254) NOT NULL,
  "contacto" VARCHAR(120) NOT NULL,
  "referenciaUrl" VARCHAR(500),
  "evidencia" VARCHAR(2000) NOT NULL,
  "estado" "EstadoAltaInstitucion" NOT NULL DEFAULT 'PENDIENTE',
  "revision" INTEGER NOT NULL DEFAULT 1,
  "mensajeSolicitante" VARCHAR(1000) NOT NULL DEFAULT '',
  "historial" JSONB NOT NULL DEFAULT '[]',
  "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "actualizadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "SolicitudAltaInstitucion_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "SolicitudAltaInstitucion_revision_check" CHECK ("revision" > 0),
  CONSTRAINT "SolicitudAltaInstitucion_solicitanteId_fkey" FOREIGN KEY ("solicitanteId") REFERENCES "Usuario"("id") ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT "SolicitudAltaInstitucion_institucionId_fkey" FOREIGN KEY ("institucionId") REFERENCES "Institucion"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "SolicitudAltaInstitucion_solicitanteId_key" ON "SolicitudAltaInstitucion"("solicitanteId");
CREATE UNIQUE INDEX "SolicitudAltaInstitucion_institucionId_key" ON "SolicitudAltaInstitucion"("institucionId");
CREATE INDEX "SolicitudAltaInstitucion_estado_actualizadoEn_idx" ON "SolicitudAltaInstitucion"("estado", "actualizadoEn");
CREATE INDEX "SolicitudAltaInstitucion_nombreNormalizado_ciudadNormalizada_idx" ON "SolicitudAltaInstitucion"("nombreNormalizado", "ciudadNormalizada");
INSERT INTO "SolicitudAltaInstitucion" ("id", "solicitanteId", "institucionId", "nombre", "nombreNormalizado", "ciudad", "ciudadNormalizada", "correoInstitucional", "contacto", "evidencia", "estado", "mensajeSolicitante")
SELECT gen_random_uuid(), propietario."usuarioId", i."id", left(i."nombre",120), lower(translate(regexp_replace(trim(left(i."nombre",120)), '\s+', ' ', 'g'), 'ÁÉÍÓÚÜÑáéíóúüñ', 'AEIOUUNaeiouun')), '', '', '', '', 'Institución anterior al flujo de verificación. Requiere revisión de ADMIN.', 'LEGADO_EN_REVISION', 'Tu institución tiene una revisión pendiente. Contacta al equipo de SaberPlus antes de finalizar el plazo de transición.'
FROM "Institucion" i
LEFT JOIN LATERAL (SELECT m."usuarioId" FROM "MiembroInstitucion" m WHERE m."institucionId" = i."id" AND m."rol" = 'PROPIETARIO' ORDER BY m."usuarioId" LIMIT 1) propietario ON true;
```

### 20260918090000_institution_approval_privacy

Fuente: backend/prisma/migrations/20260918090000_institution_approval_privacy/migration.sql; SHA-256 580540b3a080fde04f358d2a9ff6231487b96fc56f6ec0aa31de7134b9a44924.

```sql
-- La evidencia institucional y las notas ADMIN se consultan solo por NestJS.
-- No modificar la migración anterior: puede haberse aplicado en otro ambiente.
ALTER TABLE "SolicitudAltaInstitucion" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "SolicitudAltaInstitucion" FROM PUBLIC;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON TABLE "SolicitudAltaInstitucion" FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    REVOKE ALL ON TABLE "SolicitudAltaInstitucion" FROM authenticated;
  END IF;
END $$;
-- Sin políticas para clientes directos. No revocar al propietario Prisma:
-- la API aplica los permisos de profesor/ADMIN y conserva acceso de propietario.
```

### 20260918140000_summit_challenge

Fuente: backend/prisma/migrations/20260918140000_summit_challenge/migration.sql; SHA-256 0d579776de73395eb9d3434e51ce669f2d4ead4912456fbc2e9cffa3edbd64c4.

```sql
CREATE TABLE "IntentoCima" (
  "id" UUID NOT NULL,
  "usuarioId" UUID NOT NULL,
  "area" "AreaIcfes" NOT NULL,
  "temaId" TEXT,
  "subtemaId" TEXT,
  "dificultad" "Dificultad",
  "version" INTEGER NOT NULL DEFAULT 1,
  "estado" VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
  "preguntas" JSONB NOT NULL,
  "respuestas" JSONB NOT NULL DEFAULT '[]',
  "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "venceEn" TIMESTAMP(3) NOT NULL,
  "finalizadoEn" TIMESTAMP(3),
  CONSTRAINT "IntentoCima_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "IntentoCima_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "IntentoCima_version_check" CHECK ("version" = 1),
  CONSTRAINT "IntentoCima_estado_check" CHECK ("estado" IN ('ACTIVO', 'VICTORIA', 'AGOTADO', 'ABANDONADO', 'EXPIRADO')),
  CONSTRAINT "IntentoCima_preguntas_check" CHECK (jsonb_typeof("preguntas") = 'array' AND jsonb_array_length("preguntas") = 12),
  CONSTRAINT "IntentoCima_respuestas_check" CHECK (jsonb_typeof("respuestas") = 'array' AND jsonb_array_length("respuestas") <= 12),
  CONSTRAINT "IntentoCima_fechas_check" CHECK ("venceEn" > "creadoEn" AND ("estado" = 'ACTIVO') = ("finalizadoEn" IS NULL))
);
CREATE INDEX "IntentoCima_usuarioId_creadoEn_idx" ON "IntentoCima"("usuarioId", "creadoEn");
CREATE UNIQUE INDEX "IntentoCima_un_activo" ON "IntentoCima"("usuarioId") WHERE "estado" = 'ACTIVO';
-- Solo el backend accede a snapshots y soluciones. Sin políticas para clientes.
ALTER TABLE "IntentoCima" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "IntentoCima" FROM PUBLIC;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON TABLE "IntentoCima" FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    REVOKE ALL ON TABLE "IntentoCima" FROM authenticated;
  END IF;
END $$;
```

### 20260923160000_star_rescue

Fuente: backend/prisma/migrations/20260923160000_star_rescue/migration.sql; SHA-256 63647ef4fdcfa62ff62a89dda6fa9414ac3c3a38a958acce0b183190fe196008.

```sql
CREATE TABLE "IntentoRescateEstrellas" (
  "id" UUID NOT NULL,
  "usuarioId" UUID NOT NULL,
  "area" "AreaIcfes" NOT NULL,
  "temaId" TEXT,
  "subtemaId" TEXT,
  "dificultad" "Dificultad",
  "version" INTEGER NOT NULL DEFAULT 1,
  "estado" VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
  "preguntas" JSONB NOT NULL,
  "respuestas" JSONB NOT NULL DEFAULT '[]',
  "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "venceEn" TIMESTAMP(3) NOT NULL,
  "finalizadoEn" TIMESTAMP(3),
  CONSTRAINT "IntentoRescateEstrellas_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "IntentoRescateEstrellas_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "IntentoRescateEstrellas_version_check" CHECK ("version" = 1),
  CONSTRAINT "IntentoRescateEstrellas_estado_check" CHECK ("estado" IN ('ACTIVO', 'VICTORIA', 'AGOTADO', 'ABANDONADO', 'EXPIRADO')),
  CONSTRAINT "IntentoRescateEstrellas_preguntas_check" CHECK (jsonb_typeof("preguntas") = 'array' AND jsonb_array_length("preguntas") = 10),
  CONSTRAINT "IntentoRescateEstrellas_respuestas_check" CHECK (jsonb_typeof("respuestas") = 'array' AND jsonb_array_length("respuestas") <= 10),
  CONSTRAINT "IntentoRescateEstrellas_fechas_check" CHECK ("venceEn" > "creadoEn" AND ("estado" = 'ACTIVO') = ("finalizadoEn" IS NULL))
);
CREATE INDEX "IntentoRescateEstrellas_usuarioId_creadoEn_idx" ON "IntentoRescateEstrellas"("usuarioId", "creadoEn");
CREATE UNIQUE INDEX "IntentoRescateEstrellas_un_activo" ON "IntentoRescateEstrellas"("usuarioId") WHERE "estado" = 'ACTIVO';
-- Solo el backend accede a snapshots y soluciones. Sin políticas para clientes.
ALTER TABLE "IntentoRescateEstrellas" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "IntentoRescateEstrellas" FROM PUBLIC;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON TABLE "IntentoRescateEstrellas" FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    REVOKE ALL ON TABLE "IntentoRescateEstrellas" FROM authenticated;
  END IF;
END $$;
```

### 20260924160000_knowledge_shield

Fuente: backend/prisma/migrations/20260924160000_knowledge_shield/migration.sql; SHA-256 13c7e40555c977ee3b53f21ba8759fac57bf4ca5e3a3f41f330795d9f576624c.

```sql
CREATE TABLE "IntentoEscudoConocimiento" (
  "id" UUID NOT NULL,
  "usuarioId" UUID NOT NULL,
  "area" "AreaIcfes" NOT NULL,
  "temaId" TEXT,
  "subtemaId" TEXT,
  "dificultad" "Dificultad",
  "version" INTEGER NOT NULL DEFAULT 1,
  "estado" VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
  "preguntas" JSONB NOT NULL,
  "respuestas" JSONB NOT NULL DEFAULT '[]',
  "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "venceEn" TIMESTAMP(3) NOT NULL,
  "finalizadoEn" TIMESTAMP(3),
  CONSTRAINT "IntentoEscudoConocimiento_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "IntentoEscudoConocimiento_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "IntentoEscudoConocimiento_version_check" CHECK ("version" = 1),
  CONSTRAINT "IntentoEscudoConocimiento_estado_check" CHECK ("estado" IN ('ACTIVO', 'VICTORIA', 'DERROTA', 'ABANDONADO', 'EXPIRADO')),
  CONSTRAINT "IntentoEscudoConocimiento_preguntas_check" CHECK (jsonb_typeof("preguntas") = 'array' AND jsonb_array_length("preguntas") = 12),
  CONSTRAINT "IntentoEscudoConocimiento_respuestas_check" CHECK (jsonb_typeof("respuestas") = 'array' AND jsonb_array_length("respuestas") <= 12),
  CONSTRAINT "IntentoEscudoConocimiento_fechas_check" CHECK ("venceEn" > "creadoEn" AND ("estado" = 'ACTIVO') = ("finalizadoEn" IS NULL))
);
CREATE INDEX "IntentoEscudoConocimiento_usuarioId_creadoEn_idx" ON "IntentoEscudoConocimiento"("usuarioId", "creadoEn");
CREATE UNIQUE INDEX "IntentoEscudoConocimiento_un_activo" ON "IntentoEscudoConocimiento"("usuarioId") WHERE "estado" = 'ACTIVO';
-- Solo el backend accede a snapshots y soluciones. Sin políticas para clientes.
ALTER TABLE "IntentoEscudoConocimiento" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "IntentoEscudoConocimiento" FROM PUBLIC;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON TABLE "IntentoEscudoConocimiento" FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    REVOKE ALL ON TABLE "IntentoEscudoConocimiento" FROM authenticated;
  END IF;
END $$;
```

### 20260927120000_learning_map

Fuente: backend/prisma/migrations/20260927120000_learning_map/migration.sql; SHA-256 54adc8d4507e3a10a22a46b052da07a0f2a41cf8056bda3869579576e83323c2.

```sql
-- Orientación académica, sin progreso, notas, permisos de lección ni XP.
CREATE TABLE "MapaAprendizaje" (
  "area" "AreaIcfes" NOT NULL PRIMARY KEY,
  "revision" INTEGER NOT NULL DEFAULT 0 CHECK ("revision" >= 0),
  "actualizadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "actualizadoPor" TEXT
);
CREATE TABLE "RelacionAprendizaje" (
  "area" "AreaIcfes" NOT NULL,
  "previoId" TEXT NOT NULL,
  "destinoId" TEXT NOT NULL,
  CONSTRAINT "RelacionAprendizaje_pkey" PRIMARY KEY ("previoId", "destinoId"),
  CONSTRAINT "RelacionAprendizaje_no_self" CHECK ("previoId" <> "destinoId"),
  CONSTRAINT "RelacionAprendizaje_area_fkey" FOREIGN KEY ("area") REFERENCES "MapaAprendizaje"("area") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "RelacionAprendizaje_previoId_fkey" FOREIGN KEY ("previoId") REFERENCES "Subtema"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "RelacionAprendizaje_destinoId_fkey" FOREIGN KEY ("destinoId") REFERENCES "Subtema"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "RelacionAprendizaje_area_destinoId_idx" ON "RelacionAprendizaje"("area", "destinoId");
CREATE INDEX "RelacionAprendizaje_destinoId_idx" ON "RelacionAprendizaje"("destinoId");
-- El API aplica misma área, límite y aciclicidad bajo bloqueo transaccional.
-- Las referencias se limpian al eliminar un subtema permitido; no eliminan contenido.
ALTER TABLE "MapaAprendizaje" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "RelacionAprendizaje" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "MapaAprendizaje", "RelacionAprendizaje" FROM PUBLIC;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON TABLE "MapaAprendizaje", "RelacionAprendizaje" FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    REVOKE ALL ON TABLE "MapaAprendizaje", "RelacionAprendizaje" FROM authenticated;
  END IF;
END $$;
```

### 20260927180000_deferred_review

Fuente: backend/prisma/migrations/20260927180000_deferred_review/migration.sql; SHA-256 c836ce5e5ceeb64247b9e1a08f601ba23849cf94e02d4c5da21050406bbbd641.

```sql
CREATE TABLE "RepasoDiferido" (
  "usuarioId" UUID NOT NULL REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  "tarjetaId" VARCHAR(200) NOT NULL,
  "contenidoVersion" VARCHAR(40) NOT NULL,
  "paso" INTEGER NOT NULL CHECK ("paso" BETWEEN 0 AND 4),
  "revision" INTEGER NOT NULL CHECK ("revision" > 0),
  "revisadoEn" TIMESTAMPTZ(3) NOT NULL,
  "venceEn" TIMESTAMPTZ(3) NOT NULL,
  PRIMARY KEY ("usuarioId", "contenidoVersion", "tarjetaId"),
  CHECK ("venceEn" > "revisadoEn")
);
CREATE TABLE "EventoRepasoDiferido" (
  "usuarioId" UUID NOT NULL REFERENCES "Usuario"("id") ON DELETE CASCADE ON UPDATE CASCADE,
  "eventoId" UUID NOT NULL,
  "huella" VARCHAR(64) NOT NULL,
  "resultado" JSONB NOT NULL,
  "creadoEn" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY ("usuarioId", "eventoId")
);
ALTER TABLE "RepasoDiferido" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "EventoRepasoDiferido" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON "RepasoDiferido", "EventoRepasoDiferido" FROM PUBLIC;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON "RepasoDiferido", "EventoRepasoDiferido" FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    REVOKE ALL ON "RepasoDiferido", "EventoRepasoDiferido" FROM authenticated;
  END IF;
END $$;
```
