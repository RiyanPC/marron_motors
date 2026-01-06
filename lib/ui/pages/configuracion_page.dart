import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/data_repository.dart';
import '../../models/configuracion.dart';

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
        _isLoading = false;
      });
    }
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
      appBar: AppBar(title: const Text('Configuración del Taller')),
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
