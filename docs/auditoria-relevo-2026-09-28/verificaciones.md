# Verificaciones locales del relevo

Snapshot de ejecución 28–29 de septiembre de 2026. Comandos de backend desde raíz del repositorio salvo nota. Usar Node24.14.1/npm11.11.0; en esta ronda se invocó npm-cli.js con el node.exe portátil para evitar diferencias del PATH. No se modificó el npm global.

| Comando | Resultado |
|---|---|
| npm install --package-lock-only --prefix backend | Generó dos entradas y ruido peer; se retuvieron solo las dos entradas necesarias |
| npm ci --include=dev --prefix backend | Exit0;825 añadidos/826 auditados |
| npm run build --prefix backend | Exit0; Prisma5.22 genera cliente y Nest compila |
| npm test --prefix backend -- --runInBand | Exit0;84 suites,847 pruebas |
| node node_modules/eslint/bin/eslint.js '{src,apps,libs,test}/**/*.ts' --format json --output-file … | Desde backend, sin autofix; exit1,111 errores/11 advertencias |
| npm audit --omit=dev --prefix backend --json | Exit1;4high/3moderate/0critical |
| node --test tool/test_editorial_postgres.test.mjs | Desde backend;11 pruebas pasan |
| node tool/test_editorial_postgres.mjs --deferred-review | Desde backend; falla ENOENT initdb.exe antes de DB |
| flutter pub get | Copia limpia HEAD; reproduce lock local preexistente |
| flutter analyze --no-pub | Copia limpia; sin issues |
| flutter test --no-pub | Copia limpia;631 pasan,4 omitidas por entorno live |
| flutter build apk --debug --no-pub | Falla confianza TLS Java/Gradle; no se cambió configuración |
| npm run check / npm test | En admin;22 módulos y88 pruebas pasan |
| node docs/auditoria-relevo-2026-09-28/repro-seguridad.cjs ../SaberPlus-Backend/backend | Tres reproducciones pasan; no usa DB/cuentas reales |

El runner PostgreSQL revisado usa directorio temporal con nonce/marca, loopback y credenciales aleatorias SCRAM; consume migraciones de HEAD y una lista expresa de pendientes, sin cargar .env. Antes de limpiar valida ruta/nonce y exige parada confirmada de su propio proceso. No se saltó ninguna comprobación para conseguir verde.

`npm audit` se conserva en audit-produccion.json. `lint-resumen.json` elimina el contenido fuente y conserva ubicación/regla/gravedad. Las salidas resumidas de build/Jest/ci están en ejecucion-resumen.json junto con SHA-256 de los logs originales. Los originales temporales pueden desaparecer al limpiar Windows; no son artefactos versionados del proyecto. No se copiaron variables privadas ni credenciales.

## Diff mínimo del lockfile backend

Se añade a continuación el diff Git exacto capturado después de validar npm ci. No hay cambios a package.json ni versiones existentes.

```diff
diff --git a/backend/package-lock.json b/backend/package-lock.json
index 6381174..b15dcfd 100644
--- a/backend/package-lock.json
+++ b/backend/package-lock.json
@@ -773,6 +773,31 @@
         "@jridgewell/sourcemap-codec": "^1.4.10"
       }
     },
+    "node_modules/@emnapi/core": {
+      "version": "1.11.3",
+      "resolved": "https://registry.npmjs.org/@emnapi/core/-/core-1.11.3.tgz",
+      "integrity": "sha512-zLpS5asjEb7lq8jYLq37N6XKaE41DIexlY1rF/z4/tIl3wo13Sqm28fRyfIsKZD+NZ8mM5RoKkpW/rBcuoSZSg==",
+      "dev": true,
+      "license": "MIT",
+      "optional": true,
+      "peer": true,
+      "dependencies": {
+        "@emnapi/wasi-threads": "1.2.3",
+        "tslib": "^2.4.0"
+      }
+    },
+    "node_modules/@emnapi/runtime": {
+      "version": "1.11.3",
+      "resolved": "https://registry.npmjs.org/@emnapi/runtime/-/runtime-1.11.3.tgz",
+      "integrity": "sha512-Xz4Tpyki7XyrpbUK1jR1AhdAdaXyhhY4lZ3neLodmhpuWfy2PAQN5B46sAiU4liOXGLkHypn/qU+jvfWSCYYLA==",
+      "dev": true,
+      "license": "MIT",
+      "optional": true,
+      "peer": true,
+      "dependencies": {
+        "tslib": "^2.4.0"
+      }
+    },
     "node_modules/@emnapi/wasi-threads": {
       "version": "1.2.3",
       "resolved": "https://registry.npmjs.org/@emnapi/wasi-threads/-/wasi-threads-1.2.3.tgz",
```

## Diff preexistente de Flutter (preservado)

Versiones y hashes exactos; no generado por esta auditoría en el repositorio de trabajo.

```diff
diff --git a/pubspec.lock b/pubspec.lock
index 5352ddf..638f45d 100644
--- a/pubspec.lock
+++ b/pubspec.lock
@@ -181,10 +181,10 @@ packages:
     dependency: transitive
     description:
       name: clock
-      sha256: e51d50bca3217c9a9fa2b41a30e4a38971133f5f9ec7a3d57bae095007f1d28e
+      sha256: fddb70d9b5277016c77a80201021d40a2247104d9f4aa7bab7157b7e3f05b84b
       url: "https://pub.dev"
     source: hosted
-    version: "1.1.3"
+    version: "1.1.2"
   collection:
     dependency: transitive
     description:
@@ -513,10 +513,10 @@ packages:
     dependency: transitive
     description:
       name: intl
-      sha256: "1ca20c894b1717686a2319b8548763d812bc0aabdac580420a44c5178c57a867"
+      sha256: "3df61194eb431efc39c4ceba583b95633a403f46c9fd341e550ce0bfa50e9aa5"
       url: "https://pub.dev"
     source: hosted
-    version: "0.20.3"
+    version: "0.20.2"
   io:
     dependency: transitive
     description:
@@ -625,10 +625,10 @@ packages:
     dependency: transitive
     description:
       name: matcher
-      sha256: "31bd099b47c10cd1aeb55146a2d46ce0277630ecef3f7dae54ad7873f36696cd"
+      sha256: dc0b7dc7651697ea4ff3e69ef44b0407ea32c487a39fff6a4004fa585e901861
       url: "https://pub.dev"
     source: hosted
-    version: "0.12.20"
+    version: "0.12.19"
   material_color_utilities:
     dependency: transitive
     description:
@@ -649,10 +649,10 @@ packages:
     dependency: transitive
     description:
       name: meta
-      sha256: "307249ce4ff29d58a18e97f6345f539382eb9c9c29ecda628900f31de0443dd9"
+      sha256: "1741988757a65eb6b36abe716829688cf01910bbf91c34354ff7ec1c3de2b349"
       url: "https://pub.dev"
     source: hosted
-    version: "1.19.0"
+    version: "1.18.0"
   mime:
     dependency: transitive
     description:
@@ -942,10 +942,10 @@ packages:
     dependency: transitive
     description:
       name: stack_trace
-      sha256: "277654b3034d17ac6f9f1cb5595db011b1d5d41e8806866db28e0abaa101c490"
+      sha256: "8b27215b45d22309b5cddda1aa2b19bdfec9df0e765f2de506401c071d38d1b1"
       url: "https://pub.dev"
     source: hosted
-    version: "1.12.2"
+    version: "1.12.1"
   state_notifier:
     dependency: transitive
     description:
@@ -998,10 +998,10 @@ packages:
     dependency: transitive
     description:
       name: test_api
-      sha256: "2a122cbe059f8b610d3a5415f42e255b6c17b1f21eee1d960f31080237fb4f11"
+      sha256: "949a932224383300f01be9221c39180316445ecb8e7547f70a41a35bf421fb9e"
       url: "https://pub.dev"
     source: hosted
-    version: "0.7.12"
+    version: "0.7.11"
   timezone:
     dependency: "direct main"
     description:
@@ -1094,10 +1094,10 @@ packages:
     dependency: transitive
     description:
       name: vector_math
-      sha256: f36f9f3be64c6198714492bb455c11056e33e2f85d9a0b676a48301e44fdcf47
+      sha256: d530bd74fea330e6e364cda7a85019c434070188383e1cd8d9777ee586914c5b
       url: "https://pub.dev"
     source: hosted
-    version: "2.4.2"
+    version: "2.2.0"
   vm_service:
     dependency: transitive
     description:
```
