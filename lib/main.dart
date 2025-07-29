// Importación de paquetes necesarios
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'view_models/home_page_view_model.dart';
import 'widgets/spreadsheet_table.dart';

// Punto de entrada principal de la aplicación
void main() {
  runApp(const MyApp());
}

// Widget principal de la aplicación
class MyApp extends StatefulWidget {
  // Constructor con parámetro key opcional
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      // Determina si el tema actual es oscuro (ya sea explícitamente o por el sistema)
      final isCurrentlyDark =
          _themeMode == ThemeMode.dark ||
          (_themeMode == ThemeMode.system &&
              MediaQuery.of(context).platformBrightness == Brightness.dark);

      // Cambia al tema opuesto
      _themeMode = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  // Método que construye la interfaz de usuario principal
  @override
  Widget build(BuildContext context) {
    const seedColor = Colors.deepPurple;

    return MaterialApp(
      title: 'Planilla de colectas, intenciones y otros',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      // Usamos ChangeNotifierProvider para crear y proveer el ViewModel a MyHomePage y sus descendientes.
      home: ChangeNotifierProvider(
        create: (context) => HomePageViewModel(),
        child: MyHomePage(onToggleTheme: _toggleTheme),
      ),
    );
  }
}

// Widget de la página principal
class MyHomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;

  // Constructor con parámetro key opcional
  const MyHomePage({super.key, required this.onToggleTheme});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    // Accedemos al ViewModel y cargamos los datos iniciales.
    // `listen: false` es importante aquí porque solo queremos llamar al método,
    // no reconstruir el widget si los datos cambian durante esta llamada.
    Provider.of<HomePageViewModel>(context, listen: false).loadInitialData();
  }

  /// Captura el widget de la planilla y lo guarda como imagen en la galería.
  void _captureAndSave() async {
    // Obtenemos el ViewModel sin escuchar cambios, solo para llamar al método.
    final viewModel = Provider.of<HomePageViewModel>(context, listen: false);
    final errorMessage = await viewModel.captureAndSave();

    // La comprobación 'mounted' es crucial antes de usar el 'context' después de una pausa asíncrona.
    if (!mounted) return;

    // Guardamos una referencia al ScaffoldMessenger antes de usarlo para evitar advertencias del linter.
    final messenger = ScaffoldMessenger.of(context);

    if (errorMessage == null) {
      // Éxito
      messenger.showSnackBar(
        const SnackBar(content: Text('Planilla guardada en la galería con éxito.')),
      );
    } else {
      // Error
      messenger.showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  // Método que construye la interfaz de la página principal
  @override
  Widget build(BuildContext context) {
    // Obtenemos la instancia del ViewModel. El widget se reconstruirá si el ViewModel notifica cambios.
    final viewModel = Provider.of<HomePageViewModel>(context);

    // Determina el icono a mostrar basado en el brillo actual del tema
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final icon = isDarkMode ? Icons.light_mode : Icons.dark_mode;

    return Scaffold(
      appBar: AppBar(
        // Barra superior de la aplicación
        title: const Text('Planilla de colectas, intenciones y otros'),
        actions: [
          IconButton(
            icon: Icon(icon),
            onPressed: widget.onToggleTheme,
            tooltip: 'Cambiar tema',
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _captureAndSave,
            tooltip: 'Guardar como imagen',
          ),
        ],
      ),
      body: Screenshot(
        controller: viewModel.screenshotController,
        child: Padding(
          // Contenido principal con padding
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: viewModel.fechaController,
                        decoration: const InputDecoration(
                          labelText: 'Fecha',
                          icon: Icon(Icons.calendar_today),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: viewModel.comunidadController,
                        decoration: const InputDecoration(
                          labelText: 'Comunidad',
                          icon: Icon(Icons.group),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: viewModel.celebracionController,
                        decoration: const InputDecoration(
                          labelText: 'Celebración',
                          icon: Icon(Icons.celebration),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: viewModel.celebranteController,
                        decoration: const InputDecoration(
                          labelText: 'Celebrante',
                          icon: Icon(Icons.person),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: SpreadsheetTable(key: viewModel.spreadsheetKey)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: viewModel.clearAll,
        tooltip: 'Limpiar tabla',
        child: const Icon(Icons.clear_all),
      ),
    );
  }
}
