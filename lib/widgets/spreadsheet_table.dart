// Importaciones necesarias
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cell.dart';

// Widget de tabla de cálculo con estado
class SpreadsheetTable extends StatefulWidget {
  // Número de filas de la tabla
  final int rows;
  // Las columnas son fijas: Monto, Cantidad, Importe
  static const int columns = 3;

  // Constructor con valores predeterminados
  const SpreadsheetTable({super.key}) : rows = 12;

  @override
  SpreadsheetTableState createState() => SpreadsheetTableState();
}

// Estado del widget SpreadsheetTable
class SpreadsheetTableState extends State<SpreadsheetTable> {
  // Matriz de celdas
  late List<List<Cell>> cells;
  // Controlador para la edición de texto
  late TextEditingController _editingController;
  // Nodo de foco para el campo de texto
  late FocusNode _editingFocusNode;
  // Celda que se está editando actualmente
  Cell? _editingCell;
  // Índice de la fila que contiene el total
  late int totalRow;
  // Estado para controlar la carga inicial de datos
  bool _isLoading = true;

  // Inicialización del estado
  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController();
    _editingFocusNode = FocusNode();
    _editingFocusNode.addListener(_onFocusChange);
    _loadInitialData();
  }

  /// Carga los datos guardados al iniciar la aplicación.
  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    // Busca una lista de cantidades guardada con la clave 'quantities'.
    final savedQuantities = prefs.getStringList('quantities');
    if (mounted) {
      setState(() {
        // Inicializa las celdas con los datos guardados (si existen).
        _initializeCells(savedQuantities: savedQuantities);
        _isLoading = false;
      });
    }
  }

  // Se ejecuta cuando cambia el foco del TextField.
  void _onFocusChange() {
    // Si el campo de texto pierde el foco y estamos en modo de edición, confirma el valor.
    if (!_editingFocusNode.hasFocus && _editingCell != null) {
      _submitCell(_editingController.text);
    }
  }

  // Inicializa la matriz de celdas
  void _initializeCells({List<String>? savedQuantities}) {
    // Lista de montos predefinidos en pesos argentinos
    final montos = [10, 20, 50, 100, 200, 500, 1000, 2000, 10000, 20000];

    // Establecer el índice de la fila del total
    totalRow = montos.length;

    final totalRows = montos.length + 1; // +1 para la fila de total
    cells = List.generate(
      totalRows,
      (row) => List.generate(SpreadsheetTable.columns, (col) => Cell()),
    );

    // Inicializa las filas de datos
    for (int row = 0; row < totalRow; row++) {
      final monto = montos[row].toDouble();
      // Columna 0: Monto
      cells[row][0].updateValue('\$${monto.toStringAsFixed(2)}');

      // Columna 1: Cantidad (usa datos guardados si existen)
      String quantityValue = '0';
      if (savedQuantities != null && row < savedQuantities.length) {
        quantityValue = savedQuantities[row];
      }
      cells[row][1].updateValue(quantityValue);

      // Columna 2: Importe (calculado)
      final quantityNumber = double.tryParse(quantityValue) ?? 0;
      cells[row][2]
          .updateValue('\$${(monto * quantityNumber).toStringAsFixed(2)}');
    }

    // Inicializa la fila de total
    cells[totalRow][0].updateValue('TOTAL');
    cells[totalRow][1].updateValue('');
    cells[totalRow][2].updateValue('\$0.00');

    _updateTotal();
  }

  /// Limpia los valores de la tabla, reseteando las cantidades y totales.
  void clearTable() {
    setState(() {
      _initializeCells(); // Reinicia las celdas a sus valores por defecto.
    });
    _saveData(); // Guarda el estado limpio.
  }

  /// Guarda la lista actual de cantidades en el almacenamiento local.
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final quantities =
        cells.take(totalRow).map((row) => row[1].value).toList();
    await prefs.setStringList('quantities', quantities);
  }

  // Confirma el valor de una celda y actualiza la tabla.
  void _submitCell(String value) {
    if (_editingCell == null) return;

    // Encuentra la fila y columna de la celda que se está editando
    int? editingRow;
    int? editingCol;
    for (int r = 0; r < cells.length; r++) {
      final c = cells[r].indexOf(_editingCell!);
      if (c != -1) {
        editingRow = r;
        editingCol = c;
        break;
      }
    }

    // Si no se encuentra la celda, sale.
    if (editingRow == null || editingCol == null) {
      setState(() {
        _editingCell = null;
      });
      return;
    }

    // Crea copias locales no nulas para que el analizador de Dart las entienda dentro de setState.
    final int finalRow = editingRow;
    final int finalCol = editingCol;

    final cell = _editingCell!;

    setState(() {
      if (finalCol == 1) {
        // Columna de cantidad
        // Si el usuario deja el campo vacío, se asume '0'.
        final finalValue = value.isEmpty ? '0' : value;
        final numero = double.tryParse(finalValue);

        // Si el valor es un número válido, actualiza.
        if (numero != null) {
          cell.updateValue(numero.toString());
          final monto = double.tryParse(
            cells[finalRow][0].value.replaceAll(r'$', ''),
          );
          if (monto != null) {
            cells[finalRow][2]
                .updateValue('\$${(monto * numero).toStringAsFixed(2)}');
          }
        } else {
          // Si no es un número válido, vuelve a 0.
          cell.updateValue('0');
          cells[finalRow][2].updateValue('\$0.00');
        }
      } else {
        // Otras columnas editables (ej. Monto)
        cell.updateValue(value);
      }
      _updateTotal();
      _editingCell = null;
    });
    _saveData(); // Guarda los datos después de cada modificación.
  }

  // Construye una celda individual de la tabla
  Widget _buildCell(int row, int col) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Obtiene la celda actual y verifica si está siendo editada
    final cell = cells[row][col];
    final isEditing = cell == _editingCell;

    // No permitir edición en la columna de importe (col 2) ni en la fila de total
    final bool isEditable = col != 2 && row != totalRow;

    // Verificar si es la fila de total
    final bool isTotalRow = row == totalRow;

    return GestureDetector(
      // Maneja el toque en la celda solo si es editable
      onTap: isEditable
          ? () {
              setState(() {
                _editingCell = cell;
                // Si es la columna de cantidad y el valor es '0', límpialo para editar.
                if (col == 1 && cell.value == '0') {
                  _editingController.text = '';
                } else {
                  // Si no, muestra el valor actual (o la fórmula si existe).
                  _editingController.text =
                      cell.formula.isNotEmpty ? cell.formula : cell.value;
                }
                // Solicita el foco para el TextField.
                _editingFocusNode.requestFocus();
                // Selecciona todo el texto para reemplazarlo fácilmente.
                _editingController.selection = TextSelection(
                    baseOffset: 0, extentOffset: _editingController.text.length);
              });
            }
          : null,
      child: Container(
        // Decoración de la celda
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          // Cambia el color de fondo cuando se está editando o es la fila de total
          color: isEditing
              // Se usa withAlpha para evitar una advertencia de linter incorrecta sobre withOpacity
              ? colorScheme.primary.withAlpha((255 * 0.1).round())
              : (isTotalRow
                  ? colorScheme.secondaryContainer
                  : (col == 2 ? colorScheme.surfaceContainerHighest : null)),
        ),
        padding: const EdgeInsets.all(8.0),
        // Muestra un campo de texto si se está editando, si no, muestra el valor
        child: isEditing
            ? TextField(
                controller: _editingController,
                focusNode: _editingFocusNode,
                autofocus: true,
                // Estilo para que coincida con el texto de la celda
                style: TextStyle(color: colorScheme.onSurface),
                // Alinea el texto horizontalmente como en la celda de solo lectura
                textAlign: col == 1 ? TextAlign.center : TextAlign.right,
                // Centra el texto verticalmente
                textAlignVertical: TextAlignVertical.center,
                keyboardType:
                    col == 1 ? TextInputType.number : TextInputType.text,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  // isCollapsed permite que textAlignVertical funcione correctamente
                  // dentro de los límites de la celda.
                  isCollapsed: true,
                ),
                // Maneja la confirmación del valor ingresado
                onSubmitted: (value) {
                  _submitCell(value);
                },
              )
            : Container(
                alignment: col == 1 ? Alignment.center : Alignment.centerRight,
                child: Text(
                  cell.value,
                  style: TextStyle(
                    color: col == 2 ? theme.disabledColor : colorScheme.onSurface,
                    fontWeight: isTotalRow
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Muestra un indicador de carga mientras se obtienen los datos guardados.
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // --- Lógica para anchos de columna responsivos ---
    // Obtiene el ancho total disponible para la tabla (considerando el padding de 16 en cada lado de MyHomePage)
    final availableWidth = MediaQuery.of(context).size.width - 32.0;

    // Define las proporciones deseadas para cada columna [Monto, Cantidad, Importe]
    const columnProportions = [0.35, 0.25, 0.40];

    // Define los anchos mínimos para asegurar la legibilidad
    const minColumnWidths = [110.0, 70.0, 110.0];

    // Calcula los anchos finales, asegurando que no sean menores que el mínimo.
    // El SingleChildScrollView horizontal se encargará del desbordamiento si la pantalla es muy estrecha.
    final columnWidths = List.generate(
      SpreadsheetTable.columns,
      (i) => (availableWidth * columnProportions[i]).clamp(minColumnWidths[i], double.infinity),
    );
    // --- Fin de la lógica responsiva ---

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Fila de encabezado con letras de columnas
            Row(
              children: [
                ...List.generate(
                  SpreadsheetTable.columns,
                  (col) => Container(
                    width: columnWidths[col],
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ['Monto', 'Cantidad', 'Importe'][col],
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                  ),
                ),
              ],
            ),
            // Data rows
            ...List.generate(
              cells.length,
              (row) => Row(
                children: [
                  // Cells
                  ...List.generate(
                    SpreadsheetTable.columns,
                    (col) => SizedBox(
                      width: columnWidths[col],
                      height: 40,
                      child: _buildCell(row, col),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Calcula y actualiza el total
  void _updateTotal() {
    double total = 0;

    // Suma todos los importes
    for (int row = 0; row < totalRow; row++) {
      if (cells[row][2].value.isNotEmpty) {
        final importe =
            double.tryParse(cells[row][2].value.replaceAll(r'$', '')) ?? 0;
        total += importe;
      }
    }

    // Actualiza la fila de total
    cells[totalRow][0].updateValue('TOTAL');
    cells[totalRow][1].updateValue('');
    cells[totalRow][2].updateValue('\$${total.toStringAsFixed(2)}');
  }

  @override
  void dispose() {
    _editingController.dispose();
    _editingFocusNode.removeListener(_onFocusChange);
    _editingFocusNode.dispose();
    super.dispose();
  }
}
