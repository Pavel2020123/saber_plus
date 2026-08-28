import 'environment.dart';

String resolveResourceUrl(AppConfig config, String value) {
  final uri = Uri.tryParse(value);
  if (uri?.hasScheme ?? false) return value;
  final clean = value.replaceFirst(RegExp(r'^/+'), '');
  if (clean.startsWith('uploads/')) return '${config.apiBaseUrl}/$clean';
  if (clean.startsWith('imagenes/')) return '${config.contentRoot}/$clean';
  return '${config.contentRoot}/imagenes/$clean';
}
