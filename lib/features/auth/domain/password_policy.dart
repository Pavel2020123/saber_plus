String? validateStrongPassword(String? value) {
  final password = value ?? '';
  if (password.length < 8 || password.length > 72) {
    return 'Usa entre 8 y 72 caracteres';
  }
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Incluye al menos una letra mayúscula';
  }
  if (!RegExp(r'\d').hasMatch(password)) {
    return 'Incluye al menos un número';
  }
  return null;
}
