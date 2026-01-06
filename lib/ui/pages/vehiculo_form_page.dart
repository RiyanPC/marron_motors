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
    if (_uploadingImage) return;

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
      final newId = await _repository.saveVehiculo(vehiculo);
      if (newId != null) {
        final savedVehiculo = Vehiculo(
          id: newId,
          cliId: vehiculo.cliId,
          empId: vehiculo.empId,
          placa: vehiculo.placa,
          marca: vehiculo.marca,
          modelo: vehiculo.modelo,
          anio: vehiculo.anio,
          color: vehiculo.color,
          vin: vehiculo.vin,
          foto: vehiculo.foto,
        );
        if (mounted) Navigator.pop(context, savedVehiculo);
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

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0D47A1)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehiculo != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Vehículo' : 'Nuevo Vehículo'),
        elevation: 0,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
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
                    _buildSectionHeader(
                      Icons.person_pin_outlined,
                      'PROPIETARIO',
                    ),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: _openClienteSelector,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Seleccionar Cliente *',
                                  prefixIcon: Icon(Icons.person),
                                  suffixIcon: Icon(Icons.arrow_drop_down),
                                ),
                                child: Text(
                                  _selectedCliente != null
                                      ? '${_selectedCliente!.nombre} (${_selectedCliente!.numeroDocumento})'
                                      : 'Toca para buscar un cliente',
                                  style: TextStyle(
                                    color: _selectedCliente != null
                                        ? Colors.black87
                                        : Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader(Icons.badge_outlined, 'IDENTIFICACIÓN'),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _placaController,
                              decoration: const InputDecoration(
                                labelText: 'Número de Placa *',
                                prefixIcon: Icon(Icons.numbers),
                                hintText: 'Ej: ABC-123',
                              ),
                              textCapitalization: TextCapitalization.characters,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _vinController,
                              decoration: const InputDecoration(
                                labelText: 'VIN / Chasis / Motor',
                                prefixIcon: Icon(Icons.fingerprint),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader(
                      Icons.settings_outlined,
                      'ESPECIFICACIONES',
                    ),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _marcaController,
                                    decoration: const InputDecoration(
                                      labelText: 'Marca',
                                      prefixIcon: Icon(
                                        Icons.branding_watermark_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _modeloController,
                                    decoration: const InputDecoration(
                                      labelText: 'Modelo',
                                      prefixIcon: Icon(
                                        Icons.model_training_outlined,
                                      ),
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
                                    decoration: const InputDecoration(
                                      labelText: 'Año',
                                      prefixIcon: Icon(
                                        Icons.calendar_today_outlined,
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    maxLength: 4,
                                    buildCounter:
                                        (
                                          context, {
                                          required currentLength,
                                          required isFocused,
                                          maxLength,
                                        }) => null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _colorController,
                                    decoration: const InputDecoration(
                                      labelText: 'Color',
                                      prefixIcon: Icon(Icons.palette_outlined),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader(Icons.image_outlined, 'MULTIMEDIA'),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (_fotoController.text.isNotEmpty)
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      _fotoController.text,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => setState(
                                          () => _fotoController.clear(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.1),
                                  ),
                                ),
                                child: _uploadingImage
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo_outlined,
                                            size: 48,
                                            color: const Color(
                                              0xFF0D47A1,
                                            ).withOpacity(0.5),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Selecciona una foto del vehículo',
                                            style: TextStyle(
                                              color: Color(0xFF0D47A1),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              _buildUploadButton(
                                                Icons.camera_alt,
                                                'CÁMARA',
                                                () => _pickImage(
                                                  ImageSource.camera,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              _buildUploadButton(
                                                Icons.photo_library,
                                                'GALERÍA',
                                                () => _pickImage(
                                                  ImageSource.gallery,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isEditing
                                  ? 'ACTUALIZAR VEHÍCULO'
                                  : 'REGISTRAR VEHÍCULO',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUploadButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0D47A1),
        side: const BorderSide(color: Color(0xFF0D47A1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
