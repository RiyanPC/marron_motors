import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';
import '../../models/cliente.dart';
import '../../services/data_repository.dart';

class VehiculoFormPage extends StatefulWidget {
  final Vehiculo? vehiculo;
  const VehiculoFormPage({super.key, this.vehiculo});

  @override
  State<VehiculoFormPage> createState() => _VehiculoFormPageState();
}

class _VehiculoFormPageState extends State<VehiculoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = DataRepository();
  bool _saving = false;
  bool _loadingClientes = true;

  late TextEditingController _placaController;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;
  late TextEditingController _anioController;
  late TextEditingController _colorController;
  late TextEditingController _vinController;

  List<Cliente> _clientes = [];
  String? _selectedClienteId;

  @override
  void initState() {
    super.initState();
    _placaController = TextEditingController(text: widget.vehiculo?.placa);
    _marcaController = TextEditingController(text: widget.vehiculo?.marca);
    _modeloController = TextEditingController(text: widget.vehiculo?.modelo);
    _anioController = TextEditingController(text: widget.vehiculo?.anio);
    _colorController = TextEditingController(text: widget.vehiculo?.color);
    _vinController = TextEditingController(text: widget.vehiculo?.vin);
    _selectedClienteId = widget.vehiculo?.cliId;
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    try {
      final data = await _repository.getClientes('1');
      setState(() {
        _clientes = data;
        _loadingClientes = false;
        if (_selectedClienteId == null && _clientes.isNotEmpty) {
          _selectedClienteId = _clientes.first.id;
        }
      });
    } catch (e) {
      setState(() => _loadingClientes = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un cliente')),
      );
      return;
    }

    setState(() => _saving = true);
    final vehiculo = Vehiculo(
      id: widget.vehiculo?.id ?? '0',
      cliId: _selectedClienteId!,
      empId: widget.vehiculo?.empId ?? '1',
      placa: _placaController.text,
      marca: _marcaController.text,
      modelo: _modeloController.text,
      anio: _anioController.text,
      color: _colorController.text,
      vin: _vinController.text,
    );

    try {
      final success = await _repository.saveVehiculo(vehiculo);
      if (success) {
        if (mounted) Navigator.pop(context, true);
      } else {
        throw Exception('Error al guardar el vehículo');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehiculo != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Vehículo' : 'Nuevo Vehículo'),
      ),
      body: _loadingClientes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedClienteId,
                      decoration: const InputDecoration(
                        labelText: 'Propietario / Cliente *',
                      ),
                      items: _clientes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text('${c.nombre} (${c.numeroDocumento})'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedClienteId = v),
                      validator: (v) => v == null ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _placaController,
                      decoration: const InputDecoration(labelText: 'Placa *'),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _marcaController,
                            decoration: const InputDecoration(
                              labelText: 'Marca',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _modeloController,
                            decoration: const InputDecoration(
                              labelText: 'Modelo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _anioController,
                            decoration: const InputDecoration(labelText: 'Año'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _colorController,
                            decoration: const InputDecoration(
                              labelText: 'Color',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vinController,
                      decoration: const InputDecoration(
                        labelText: 'VIN / Chasis / Motor',
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _saving
                          ? const CircularProgressIndicator()
                          : const Text('GUARDAR'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
