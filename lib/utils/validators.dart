class Validators {
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Ingrese una contraseña';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Al menos una mayúscula';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Al menos un número';
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Al menos un carácter especial';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Ingrese un email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }
}
