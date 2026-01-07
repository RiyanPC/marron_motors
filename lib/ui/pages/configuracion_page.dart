import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../services/data_repository.dart';
import '../../models/configuracion.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  final DataRepository _repository = DataRepository();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  Configuracion? _config;
  bool _showDrawer = false;

  final _nombreController = TextEditingController();
  final _rucController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _igvController = TextEditingController();

  // Theme selection
  String _selectedTheme = 'Azul Clásico';
  Color _customPrimaryColor = const Color(0xFF0D47A1);
  Color _customAccentColor = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    final config = await _repository.getConfig();
    final prefs = await SharedPreferences.getInstance();

    if (config != null) {
      setState(() {
        _config = config;
        _nombreController.text = config.nombreTaller;
        _rucController.text = config.ruc;
        _direccionController.text = config.direccion;
        _telefonoController.text = config.telefono;
        _igvController.text = config.igvPorcentaje.toString();
        _showDrawer = prefs.getBool('show_drawer') ?? false;

        // Cargar tema
        _selectedTheme = prefs.getString('theme_name') ?? 'Azul Clásico';
        if (_selectedTheme == 'Personalizado') {
          final primaryValue = prefs.getInt('custom_primary_color');
          final accentValue = prefs.getInt('custom_accent_color');
          if (primaryValue != null) _customPrimaryColor = Color(primaryValue);
          if (accentValue != null) _customAccentColor = Color(accentValue);
        }

        _isLoading = false;
      });
    }
  }

  Future<void> _applyTheme() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.setTheme(
      _selectedTheme,
      customPrimary: _selectedTheme == 'Personalizado'
          ? _customPrimaryColor
          : null,
      customAccent: _selectedTheme == 'Personalizado'
          ? _customAccentColor
          : null,
    );
  }

  void _showColorPicker(bool isPrimary) {
    Color pickerColor = isPrimary ? _customPrimaryColor : _customAccentColor;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Seleccionar ${isPrimary ? 'Color Primario' : 'Color de Acento'}',
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  if (isPrimary) {
                    _customPrimaryColor = pickerColor;
                  } else {
                    _customAccentColor = pickerColor;
                  }
                });
                // await _applyTheme(); // Removed: Only apply on save
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('SELECCIONAR'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Guardar configuración del taller
      final newConfig = Configuracion(
        id: _config!.id,
        nombreTaller: _nombreController.text,
        ruc: _rucController.text,
        direccion: _direccionController.text,
        telefono: _telefonoController.text,
        igvPorcentaje: double.parse(_igvController.text),
        logoUrl: _config!.logoUrl,
      );

      final success = await _repository.saveConfig(newConfig);

      // Apply theme changes
      await _applyTheme();

      // Guardar preferencias de interfaz
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_drawer', _showDrawer);

      setState(() => _isLoading = false);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configuración guardada')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar datos del taller')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Taller'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      'Información General',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Taller',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _rucController,
                      decoration: const InputDecoration(
                        labelText: 'RUC',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Personalización',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Activar Menú Lateral (Drawer)'),
                      subtitle: const Text(
                        'Muestra el botón de menú en la pantalla principal',
                      ),
                      value: _showDrawer,
                      onChanged: (val) {
                        setState(() {
                          _showDrawer = val;
                        });
                      },
                      secondary: const Icon(Icons.menu),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Apariencia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Seleccionar Tema',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Temas predefinidos
                    ...AppTheme.predefinedThemes.entries.map((entry) {
                      return RadioListTile<String>(
                        title: Text(entry.key),
                        subtitle: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: entry.value['primary'],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: entry.value['accent'],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                            ),
                          ],
                        ),
                        value: entry.key,
                        groupValue: _selectedTheme,
                        onChanged: (value) async {
                          setState(() {
                            _selectedTheme = value!;
                          });
                          // await _applyTheme(); // Removed: Only apply on save
                        },
                      );
                    }),
                    // Tema personalizado
                    RadioListTile<String>(
                      title: const Text('Personalizado'),
                      subtitle: _selectedTheme == 'Personalizado'
                          ? Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _customPrimaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _customAccentColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : null,
                      value: 'Personalizado',
                      groupValue: _selectedTheme,
                      onChanged: (value) async {
                        setState(() {
                          _selectedTheme = value!;
                        });
                        // await _applyTheme(); // Removed: Only apply on save
                      },
                    ),
                    // Selectores de color personalizado (solo visible si es tema personalizado)
                    if (_selectedTheme == 'Personalizado') ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Configurar Colores',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showColorPicker(true),
                                    icon: Icon(
                                      Icons.palette,
                                      color: _customPrimaryColor,
                                    ),
                                    label: const Text('Color Primario'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _customPrimaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showColorPicker(false),
                                    icon: Icon(
                                      Icons.palette,
                                      color: _customAccentColor,
                                    ),
                                    label: const Text('Color de Acento'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _customAccentColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'Tributación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _igvController,
                      decoration: const InputDecoration(
                        labelText: 'Porcentaje IGV (%)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.percent),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: false,
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _saveConfig,
                      icon: const Icon(Icons.save),
                      label: const Text('GUARDAR CAMBIOS'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
