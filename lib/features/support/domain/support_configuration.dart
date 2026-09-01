class SupportConfiguration {
  const SupportConfiguration({
    required this.isActive,
    required this.message,
    this.whatsappNumber,
    this.whatsappUrl,
  });

  final bool isActive;
  final String? whatsappNumber;
  final String message;
  final String? whatsappUrl;

  Uri? get trustedWhatsappUri {
    if (!isActive || whatsappUrl == null) return null;
    final uri = Uri.tryParse(whatsappUrl!);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.toLowerCase() != 'wa.me' ||
        uri.pathSegments.length != 1 ||
        !RegExp(r'^[1-9]\d{9,14}$').hasMatch(uri.pathSegments.single)) {
      return null;
    }
    return uri;
  }

  factory SupportConfiguration.fromJson(Map<String, dynamic> json) =>
      SupportConfiguration(
        isActive: json['activo'] as bool? ?? false,
        whatsappNumber: json['numeroWhatsapp'] as String?,
        message:
            json['mensajeWhatsapp'] as String? ??
            'Hola, necesito ayuda con SaberPlus.',
        whatsappUrl: json['whatsappUrl'] as String?,
      );
}
