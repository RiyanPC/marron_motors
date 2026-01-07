import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
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
  bool _uploadingImage = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _placaController;
  String? _marcaVehiculo;
  String? _tipoVehiculo;
  Set<String> _customMarcas = {};
  Set<String> _customTipos = {};
  late TextEditingController _modeloController;
  late TextEditingController _anioController;
  late TextEditingController _colorController;
  late TextEditingController _vinController;
  late TextEditingController _fotoController;

  // New Client Fields
  late TextEditingController _newClienteNombreCtrl;
  late TextEditingController _newClienteDocCtrl;
  late TextEditingController _newClienteDireccionCtrl;

  Cliente? _selectedCliente;
  List<Cliente> _clientes = [];
  bool _isCreatingClient = false;
  String _newClienteTipoDoc = 'DNI';

  @override
  void initState() {
    super.initState();
    _placaController = TextEditingController(text: widget.vehiculo?.placa);
    _marcaVehiculo = widget.vehiculo?.marca;
    _tipoVehiculo = widget.vehiculo?.tipo;

    // Add existing values to custom sets if they are not standard
    if (_marcaVehiculo != null && _marcaVehiculo!.isNotEmpty)
      _customMarcas.add(_marcaVehiculo!);
    if (_tipoVehiculo != null && _tipoVehiculo!.isNotEmpty)
      _customTipos.add(_tipoVehiculo!);

    _modeloController = TextEditingController(text: widget.vehiculo?.modelo);
    _anioController = TextEditingController(text: widget.vehiculo?.anio);
    _colorController = TextEditingController(text: widget.vehiculo?.color);
    _vinController = TextEditingController(text: widget.vehiculo?.vin);
    _fotoController = TextEditingController(text: widget.vehiculo?.foto);

    _newClienteNombreCtrl = TextEditingController();
    _newClienteDocCtrl = TextEditingController();
    _newClienteDireccionCtrl = TextEditingController();

    _loadInitialData();
  }

  @override
  void dispose() {
    _placaController
        .dispose(); // Add this if it was missing or keep consistency
    _modeloController.dispose();
    _anioController.dispose();
    _colorController.dispose();
    _vinController.dispose();
    _fotoController.dispose();
    _newClienteNombreCtrl.dispose();
    _newClienteDocCtrl.dispose();
    _newClienteDireccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final clientes = await _repository.getClientes('1');
      setState(() {
        _clientes = clientes;
        if (widget.vehiculo != null) {
          try {
            _selectedCliente = clientes.firstWhere(
              (c) => c.id == widget.vehiculo!.cliId,
            );
          } catch (_) {}
        }
        _loadingClientes = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingClientes = false);
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

    if (!_isCreatingClient && _selectedCliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un cliente')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      String clienteId;

      if (_isCreatingClient) {
        // Crear nuevo cliente
        final newCliente = Cliente(
          id: '0',
          empId: '1',
          nombre: _newClienteNombreCtrl.text.toUpperCase(),
          tipoDocumento: _newClienteTipoDoc,
          numeroDocumento: _newClienteDocCtrl.text,
          telefono: '',
          email: '',
          direccion: _newClienteDireccionCtrl.text.toUpperCase(),
          ubigeo: '',
          estado: 'ACTIVO',
        );

        final newClientId = await _repository.saveCliente(newCliente);
        if (newClientId == null) throw Exception('Error al crear el cliente');
        clienteId = newClientId;
      } else {
        clienteId = _selectedCliente!.id;
      }

      final vehiculo = Vehiculo(
        id: widget.vehiculo?.id ?? '0',
        cliId: clienteId,
        empId: widget.vehiculo?.empId ?? '1',
        placa: _placaController.text.toUpperCase(),
        marca: _marcaVehiculo ?? '',
        modelo: _modeloController.text.toUpperCase(),
        anio: _anioController.text,
        color: _colorController.text.toUpperCase(),
        vin: _vinController.text.toUpperCase(),
        foto: _fotoController.text,
        tipo: _tipoVehiculo ?? '',
      );

      final newId = await _repository.saveVehiculo(vehiculo);
      if (newId != null) {
        // Get full data to return
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

  Future<String?> _showCustomInputDialog(String title, String label) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Escribir en MAYÚSCULAS',
            prefixIcon: Icon(
              Icons.edit_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          textCapitalization: TextCapitalization.characters,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('AGREGAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
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
        backgroundColor: Theme.of(context).colorScheme.primary,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isCreatingClient
                                      ? 'Nuevo Cliente'
                                      : 'Buscar Cliente Existente',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isCreatingClient = !_isCreatingClient;
                                      if (!_isCreatingClient) {
                                        _selectedCliente = null;
                                      }
                                    });
                                  },
                                  icon: Icon(
                                    _isCreatingClient
                                        ? Icons.search
                                        : Icons.add,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _isCreatingClient
                                        ? 'Seleccionar existente'
                                        : 'Cliente no existente -> añadir',
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            if (_isCreatingClient) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: DropdownButtonFormField<String>(
                                      value: _newClienteTipoDoc,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Tipo',
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 15,
                                        ),
                                        border: OutlineInputBorder(),
                                      ),
                                      items: ['DNI', 'RUC']
                                          .map(
                                            (t) => DropdownMenuItem(
                                              value: t,
                                              child: Text(t),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) => setState(
                                        () => _newClienteTipoDoc = v!,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _newClienteDocCtrl,
                                      decoration: InputDecoration(
                                        labelText: 'N° Documento *',
                                        border: const OutlineInputBorder(),
                                        counterText: '',
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.search),
                                          onPressed: () async {
                                            // Implementar consulta RUC/DNI rápida si se desea
                                            // Por ahora solo validación
                                            final doc = _newClienteDocCtrl.text;
                                            if (doc.isNotEmpty) {
                                              try {
                                                // Usar el repositorio existente para consultar
                                                final data = await _repository
                                                    .consultaDocumento(
                                                      _newClienteTipoDoc,
                                                      doc,
                                                    );
                                                if (data != null && mounted) {
                                                  setState(() {
                                                    if (_newClienteTipoDoc ==
                                                        'DNI') {
                                                      _newClienteNombreCtrl
                                                              .text =
                                                          data['nombre'] ?? '';
                                                    } else {
                                                      _newClienteNombreCtrl
                                                              .text =
                                                          data['razonSocial'] ??
                                                          '';
                                                      _newClienteDireccionCtrl
                                                              .text =
                                                          data['direccion'] ??
                                                          '';
                                                    }
                                                  });
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Datos encontrados',
                                                      ),
                                                    ),
                                                  );
                                                } else if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'No encontrado',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (_) {}
                                            }
                                          },
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      maxLength: _newClienteTipoDoc == 'DNI'
                                          ? 8
                                          : 11,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      validator: (v) {
                                        if (!_isCreatingClient) return null;
                                        if (v == null || v.isEmpty)
                                          return 'Requerido';
                                        if (_newClienteTipoDoc == 'DNI' &&
                                            v.length != 8)
                                          return '8 dígitos';
                                        if (_newClienteTipoDoc == 'RUC' &&
                                            v.length != 11)
                                          return '11 dígitos';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _newClienteNombreCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre / Razón Social *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                textCapitalization:
                                    TextCapitalization.characters,
                                validator: (v) {
                                  if (!_isCreatingClient) return null;
                                  return v!.isEmpty ? 'Requerido' : null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _newClienteDireccionCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Dirección (Opcional)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.place_outlined),
                                ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                              ),
                            ] else ...[
                              Autocomplete<Cliente>(
                                displayStringForOption: (Cliente option) =>
                                    '${option.nombre} (${option.numeroDocumento})',
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text == '') {
                                        return const Iterable<Cliente>.empty();
                                      }
                                      return _clientes.where((Cliente option) {
                                        return option.nombre
                                                .toLowerCase()
                                                .contains(
                                                  textEditingValue.text
                                                      .toLowerCase(),
                                                ) ||
                                            option.numeroDocumento.contains(
                                              textEditingValue.text,
                                            );
                                      });
                                    },
                                onSelected: (Cliente selection) {
                                  setState(() {
                                    _selectedCliente = selection;
                                  });
                                },
                                initialValue: _selectedCliente != null
                                    ? TextEditingValue(
                                        text:
                                            '${_selectedCliente!.nombre} (${_selectedCliente!.numeroDocumento})',
                                      )
                                    : null,
                                fieldViewBuilder:
                                    (
                                      context,
                                      textEditingController,
                                      focusNode,
                                      onFieldSubmitted,
                                    ) {
                                      // Hack para establecer el valor inicial si se selecciona uno y luego se vuelve
                                      if (_selectedCliente != null &&
                                          textEditingController.text.isEmpty &&
                                          !focusNode.hasFocus) {
                                        textEditingController.text =
                                            '${_selectedCliente!.nombre} (${_selectedCliente!.numeroDocumento})';
                                      }

                                      return TextFormField(
                                        controller: textEditingController,
                                        focusNode: focusNode,
                                        decoration: InputDecoration(
                                          labelText: 'Buscar Cliente *',
                                          prefixIcon: const Icon(Icons.search),
                                          hintText: 'Nombre o Documento',
                                          border: const OutlineInputBorder(),
                                          suffixIcon:
                                              textEditingController
                                                  .text
                                                  .isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear),
                                                  onPressed: () {
                                                    textEditingController
                                                        .clear();
                                                    setState(
                                                      () => _selectedCliente =
                                                          null,
                                                    );
                                                  },
                                                )
                                              : null,
                                        ),
                                        validator: (v) {
                                          if (_isCreatingClient) return null;
                                          if (_selectedCliente == null)
                                            return 'Seleccione un cliente';
                                          return null;
                                        },
                                      );
                                    },
                              ),
                            ],
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
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    value: _tipoVehiculo,
                                    decoration: InputDecoration(
                                      labelText: 'Tipo',
                                      hintText: 'Seleccionar...',
                                      prefixIcon: const Icon(
                                        Icons.directions_car_outlined,
                                        size: 20,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                    ),
                                    items:
                                        [
                                              ..._customTipos,
                                              'AUTO',
                                              'CAMIONETA',
                                              'CAMIÓN',
                                              'MOTO',
                                              'MOTOKAR',
                                              '+ Agregar nuevo...',
                                            ]
                                            .map(
                                              (tipo) => DropdownMenuItem(
                                                value: tipo,
                                                child: Text(
                                                  tipo,
                                                  style: TextStyle(
                                                    fontStyle:
                                                        tipo ==
                                                            '+ Agregar nuevo...'
                                                        ? FontStyle.italic
                                                        : FontStyle.normal,
                                                    color:
                                                        tipo ==
                                                            '+ Agregar nuevo...'
                                                        ? Colors.blue
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (v) async {
                                      if (v == '+ Agregar nuevo...') {
                                        final custom =
                                            await _showCustomInputDialog(
                                              'Agregar Tipo',
                                              'Tipo de vehículo',
                                            );
                                        if (custom != null &&
                                            custom.isNotEmpty) {
                                          setState(() {
                                            _customTipos.add(
                                              custom.toUpperCase(),
                                            );
                                            _tipoVehiculo = custom
                                                .toUpperCase();
                                          });
                                        }
                                      } else {
                                        setState(() => _tipoVehiculo = v);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    value: _marcaVehiculo,
                                    decoration: InputDecoration(
                                      labelText: 'Marca',
                                      hintText: 'Seleccionar...',
                                      prefixIcon: const Icon(
                                        Icons.branding_watermark_outlined,
                                        size: 20,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                    ),
                                    items:
                                        [
                                              ..._customMarcas,
                                              'TOYOTA',
                                              'HONDA',
                                              'NISSAN',
                                              'HYUNDAI',
                                              'KIA',
                                              'MAZDA',
                                              'SUZUKI',
                                              'MITSUBISHI',
                                              'CHEVROLET',
                                              'FORD',
                                              'VOLKSWAGEN',
                                              'YAMAHA',
                                              'BAJAJ',
                                              '+ Agregar nueva...',
                                            ]
                                            .map(
                                              (marca) => DropdownMenuItem(
                                                value: marca,
                                                child: Text(
                                                  marca,
                                                  style: TextStyle(
                                                    fontStyle:
                                                        marca ==
                                                            '+ Agregar nueva...'
                                                        ? FontStyle.italic
                                                        : FontStyle.normal,
                                                    color:
                                                        marca ==
                                                            '+ Agregar nueva...'
                                                        ? Colors.blue
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (v) async {
                                      if (v == '+ Agregar nueva...') {
                                        final custom =
                                            await _showCustomInputDialog(
                                              'Agregar Marca',
                                              'Marca del vehículo',
                                            );
                                        if (custom != null &&
                                            custom.isNotEmpty) {
                                          setState(() {
                                            _customMarcas.add(
                                              custom.toUpperCase(),
                                            );
                                            _marcaVehiculo = custom
                                                .toUpperCase();
                                          });
                                        }
                                      } else {
                                        setState(() => _marcaVehiculo = v);
                                      }
                                    },
                                    validator: (v) =>
                                        (v == null ||
                                            v.isEmpty ||
                                            v == '+ Agregar nueva...')
                                        ? 'Requerido'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1),
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
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.5),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Selecciona una foto del vehículo',
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
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
        foregroundColor: Theme.of(context).colorScheme.primary,
        side: BorderSide(color: Theme.of(context).colorScheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
