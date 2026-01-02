import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/vehiculo.dart';
import '../../models/cliente.dart';
import '../../services/data_repository.dart';
import '../widgets/cliente_selector_modal.dart';

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
  bool _uploadingImage = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _placaController;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;
  late TextEditingController _anioController;
  late TextEditingController _colorController;
  late TextEditingController _vinController;
  late TextEditingController _fotoController;

  Cliente? _selectedCliente;

  @override
  void initState() {
    super.initState();
    _placaController = TextEditingController(text: widget.vehiculo?.placa);
    _marcaController = TextEditingController(text: widget.vehiculo?.marca);
    _modeloController = TextEditingController(text: widget.vehiculo?.modelo);
    _anioController = TextEditingController(text: widget.vehiculo?.anio);
    _colorController = TextEditingController(text: widget.vehiculo?.color);
    _vinController = TextEditingController(text: widget.vehiculo?.vin);
    _fotoController = TextEditingController(text: widget.vehiculo?.foto);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (widget.vehiculo != null) {
      try {
        final clientes = await _repository.getClientes('1');
        setState(() {
          _selectedCliente = clientes.firstWhere(
            (c) => c.id == widget.vehiculo!.cliId,
          );
          _loadingClientes = false;
        });
      } catch (e) {
        setState(() => _loadingClientes = false);
      }
    } else {
      setState(() => _loadingClientes = false);
    }
  }

  void _openClienteSelector() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          ClienteSelectorModal(initialSelectedId: _selectedCliente?.id),
    );

    if (result is Cliente) {
      setState(() {
        _selectedCliente = result;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
      _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() => _uploadingImage = true);
    try {
      final placa = _placaController.text.isNotEmpty
          ? _placaController.text
          : 'vehiculo';
      final url = await _repository.uploadImage(
        _imageFile!,
        folder: 'vehiculos',
        name: placa,
      );
      if (url != null) {
        setState(() {
          _fotoController.text = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen subida correctamente')),
        );
      } else {
        throw Exception('Error al subir la imagen');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _uploadingImage = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un cliente')),
      );
      return;
    }

    setState(() => _saving = true);
    final vehiculo = Vehiculo(
      id: widget.vehiculo?.id ?? '0',
      cliId: _selectedCliente!.id,
      empId: widget.vehiculo?.empId ?? '1',
      placa: _placaController.text,
      marca: _marcaController.text,
      modelo: _modeloController.text,
      anio: _anioController.text,
      color: _colorController.text,
      vin: _vinController.text,
      foto: _fotoController.text,
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
                    InkWell(
                      onTap: _openClienteSelector,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Propietario / Cliente *',
                          prefixIcon: Icon(Icons.person),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          _selectedCliente != null
                              ? '${_selectedCliente!.nombre} (${_selectedCliente!.numeroDocumento})'
                              : 'Toca para seleccionar un cliente',
                          style: TextStyle(
                            color: _selectedCliente != null
                                ? Colors.black
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
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
                    const SizedBox(height: 16),
                    const Text(
                      'Foto del Vehículo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_fotoController.text.isNotEmpty)
                      Stack(
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(_fotoController.text),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    setState(() => _fotoController.clear()),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: _uploadingImage
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.image,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _pickImage(ImageSource.camera),
                                        icon: const Icon(Icons.camera_alt),
                                        label: const Text('Cámara'),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _pickImage(ImageSource.gallery),
                                        icon: const Icon(Icons.photo_library),
                                        label: const Text('Galería'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fotoController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'URL de la Foto',
                        hintText:
                            'Se generará automáticamente al subir una foto',
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
