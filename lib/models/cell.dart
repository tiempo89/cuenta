class Cell {
  String value = '';
  String formula = '';

  Cell({this.value = '', this.formula = ''});

  double? get numericValue {
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  void updateValue(String newValue) {
    value = newValue;
    formula =
        ''; // Reinicia la fórmula cuando se actualiza directamente el valor
  }

  void updateFormula(String newFormula) {
    formula = newFormula;
    // Aquí se evaluará la fórmula y se actualizará el valor
    // Esto se implementará más adelante con la lógica de análisis de fórmulas
  }
}
