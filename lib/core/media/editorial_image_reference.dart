/// A stable editorial reference, never an arbitrary URL carrying credentials.
class EditorialImageReference {
  const EditorialImageReference._(this.path);

  final String path;
  static final _pattern = RegExp(
    r'^/recursos/editoriales/[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static EditorialImageReference? tryParse(String value) =>
      _pattern.hasMatch(value)
      ? EditorialImageReference._(value.toLowerCase())
      : null;

  factory EditorialImageReference.parse(String value) =>
      tryParse(value) ??
      (throw const FormatException('Referencia editorial inválida.'));
}
