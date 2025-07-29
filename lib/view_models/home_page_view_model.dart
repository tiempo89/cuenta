import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../widgets/spreadsheet_table.dart';

class HomePageViewModel extends ChangeNotifier {
  // Claves y Controladores que antes estaban en el State
  final spreadsheetKey = GlobalKey<SpreadsheetTableState>();
  final screenshotController = ScreenshotController();

  static const _keyFecha = 'header_fecha';
  static const _keyComunidad = 'header_comunidad';
  static const _keyCelebracion = 'header_celebracion';
  static const _keyCelebrante = 'header_celebrante';

  final fechaController = TextEditingController();
  final comunidadController = TextEditingController();
  final celebracionController = TextEditingController();
  final celebranteController = TextEditingController();

  /// Carga los datos iniciales y configura los listeners para autoguardado.
  Future<void> loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final formattedDate = "${now.day}/${now.month}/${now.year}";
    fechaController.text = prefs.getString(_keyFecha) ?? formattedDate;
    comunidadController.text = prefs.getString(_keyComunidad) ?? '';
    celebracionController.text = prefs.getString(_keyCelebracion) ?? '';
    celebranteController.text = prefs.getString(_keyCelebrante) ?? '';

    // Añade listeners para guardar los datos cada vez que cambian.
    fechaController.addListener(_saveHeaderData);
    comunidadController.addListener(_saveHeaderData);
    celebracionController.addListener(_saveHeaderData);
    celebranteController.addListener(_saveHeaderData);
  }

  /// Guarda el contenido de los campos de texto en SharedPreferences.
  Future<void> _saveHeaderData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFecha, fechaController.text);
    await prefs.setString(_keyComunidad, comunidadController.text);
    await prefs.setString(_keyCelebracion, celebracionController.text);
    await prefs.setString(_keyCelebrante, celebranteController.text);
  }

  /// Limpia la tabla y los campos del encabezado.
  void clearAll() {
    spreadsheetKey.currentState?.clearTable();

    final now = DateTime.now();
    final formattedDate = "${now.day}/${now.month}/${now.year}";
    fechaController.text = formattedDate;
    comunidadController.clear();
    celebracionController.clear();
    celebranteController.clear();
  }

  /// Captura la planilla y la guarda, devolviendo un mensaje de error o null si tiene éxito.
  Future<String?> captureAndSave() async {
    try {
      // 1. Solicitar permisos
      final permissionGranted = await _requestPermissions();
      if (!permissionGranted) {
        return 'Permisos necesarios denegados.';
      }

      // 2. Capturar la imagen
      final image = await screenshotController.capture();
      if (image == null) {
        return 'No se pudo capturar la imagen.';
      }

      // 3. Guardar en archivo temporal
      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/planilla.png').create();
      await imagePath.writeAsBytes(image);

      // 4. Guardar en la galería
      final dynamic result = await ImageGallerySaver.saveFile(
        imagePath.path,
        name: 'planilla_${DateTime.now().millisecondsSinceEpoch}',
      );

      // El plugin local devuelve un booleano, pero el analizador de Dart puede
      // inferir un tipo Map<> del paquete original. Hacemos una comprobación segura.
      if (result is bool && result == true) {
        return null; // Éxito
      }

      return 'No se pudo guardar la imagen en la galería.';
    } catch (e) {
      return 'Error al guardar la imagen: $e';
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // En Android 13 (API 33) y superior, se necesitan permisos granulares para fotos.
      // En versiones anteriores, se necesita el permiso de almacenamiento general.
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt >= 33) {
        // Android 13+
        return await Permission.photos.request().isGranted;
      } else {
        // Android 12 y anteriores
        return await Permission.storage.request().isGranted;
      }
    } else if (Platform.isIOS) {
      // Para iOS, también se usa Permission.photos
      return await Permission.photos.request().isGranted;
    }
    // Para otras plataformas, asumimos que no se necesitan permisos especiales.
    return true;
  }

  @override
  void dispose() {
    // Limpiamos los controladores para evitar fugas de memoria.
    fechaController.removeListener(_saveHeaderData);
    comunidadController.removeListener(_saveHeaderData);
    celebracionController.removeListener(_saveHeaderData);
    celebranteController.removeListener(_saveHeaderData);
    fechaController.dispose();
    comunidadController.dispose();
    celebracionController.dispose();
    celebranteController.dispose();
    super.dispose();
  }
}