// utils.dart

int calcularDiasHabilesTranscurridos(DateTime fechaInicio, DateTime fechaFin) {
  int diasHabiles = 0;
  DateTime currentDate = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);

  while (currentDate.isBefore(fechaFin) || currentDate.isAtSameMomentAs(fechaFin)) {
    if (currentDate.weekday != DateTime.saturday && currentDate.weekday != DateTime.sunday) {
      diasHabiles++;
    }
    currentDate = currentDate.add(const Duration(days: 1));
  }
  return diasHabiles;
}

int calcularDiasHabilesRestantes(DateTime fechaCreacion, int plazoDiasHabiles) {
  DateTime fechaActual = DateTime.now();
  int diasHabilesTranscurridos = calcularDiasHabilesTranscurridos(fechaCreacion, fechaActual);

  if (diasHabilesTranscurridos >= plazoDiasHabiles) {
    return 0;
  }

  int diasRestantes = plazoDiasHabiles - diasHabilesTranscurridos;
  return diasRestantes;
}