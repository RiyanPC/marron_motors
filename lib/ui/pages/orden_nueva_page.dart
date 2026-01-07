import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../services/data_repository.dart';
import '../../models/orden.dart';
import '../../models/vehiculo.dart';
import '../../models/cliente.dart';

class OrdenNuevaPage extends StatefulWidget {
  const OrdenNuevaPage({super.key});

  @override
  State<OrdenNuevaPage> createState() => _OrdenNuevaPageState();
}

class _OrdenNuevaPageState extends State<OrdenNuevaPage> {
  final DataRepository _repository = DataRepository();
  final _formKey = GlobalKey<FormState>();

  Vehiculo? _selectedVehiculo;
  List<Vehiculo> _vehiculos = [];
  bool _isCreatingVehiculo = false;

  // Vehiculo Fields
  late TextEditingController _placaCtrl;
  String? _marcaVehiculo; // Nullable for empty start
  String? _tipoVehiculo; // Nullable for empty start
  Set<String> _customMarcas = {}; // Custom brands added by user
  Set<String> _customTipos = {}; // Custom types added by user
  late TextEditingController _modeloCtrl;
  late TextEditingController _anioCtrl;
  late TextEditingController _colorCtrl;
  late TextEditingController _vinCtrl;
  late TextEditingController _descripcionController;

  // New Client Fields (Nested)
  Cliente? _selectedCliente;
  bool _isCreatingClient = false;
  List<Cliente> _clientes = [];
  late TextEditingController _newClienteNombreCtrl;
  late TextEditingController _newClienteDocCtrl;
  late TextEditingController _newClienteDireccionCtrl;
  String _newClienteTipoDoc = 'DNI';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _descripcionController = TextEditingController();

    // Init Vehiculo controllers
    _placaCtrl = TextEditingController();
    _modeloCtrl = TextEditingController();
    _anioCtrl = TextEditingController();
    // Auto-assign Peru Year
    final peruTime = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    _anioCtrl.text = peruTime.year.toString();
    _colorCtrl = TextEditingController();
    _vinCtrl = TextEditingController();

    // Init Client controllers
    _newClienteNombreCtrl = TextEditingController();
    _newClienteDocCtrl = TextEditingController();
    _newClienteDireccionCtrl = TextEditingController();

    _loadData();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _placaCtrl.dispose();
    _modeloCtrl.dispose();
    _anioCtrl.dispose();
    _colorCtrl.dispose();
    _vinCtrl.dispose();
    _newClienteNombreCtrl.dispose();
    _newClienteDocCtrl.dispose();
    _newClienteDireccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final clients = await _repository.getClientes('1');
      final vehicles = await _repository.getVehiculos('1');
      setState(() {
        _clientes = clients;
        _vehiculos = vehicles;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isCreatingVehiculo && _selectedVehiculo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleccione un vehículo')));
      return;
    }

    if (_isCreatingVehiculo) {
      if (!_isCreatingClient && _selectedCliente == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Seleccione un cliente')));
        return;
      }
    }

    _formKey.currentState!.save();

    setState(() => _loading = true);

    try {
      String ordenVehId = '';

      if (_isCreatingVehiculo) {
        // 1. Resolve Client ID
        String ordenCliId = '';
        if (_isCreatingClient) {
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
          final newCliId = await _repository.saveCliente(newCliente);
          if (newCliId == null) throw Exception('Error al crear cliente');
          ordenCliId = newCliId;
        } else {
          ordenCliId = _selectedCliente!.id;
        }

        // 2. Create Vehicle
        final newVehiculo = Vehiculo(
          id: '0',
          cliId: ordenCliId,
          empId: '1',
          placa: _placaCtrl.text.toUpperCase(),
          marca: _marcaVehiculo ?? '',
          modelo: '',
          anio: _anioCtrl.text,
          color: _colorCtrl.text.toUpperCase(),
          vin: '',
          tipo: _tipoVehiculo ?? '',
          foto: '',
        );
        final newVehId = await _repository.saveVehiculo(newVehiculo);
        if (newVehId == null) throw Exception('Error al crear vehículo');
        ordenVehId = newVehId;
      } else {
        ordenVehId = _selectedVehiculo!.id;
      }

      // 3. Create Order
      final orden = OrdenTrabajo(
        empId: '1',
        vehId: ordenVehId,
        descripcion: _descripcionController.text,
        fechaIngreso: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        estado: 'ABIERTA',
        total: 0,
        items: [],
      );

      final success = await _repository.crearOrden(orden);
      if (success) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingreso registrado correctamente')),
          );
        }
      } else {
        throw Exception('Error al crear la orden');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
            hintText: 'Escribir nombre...',
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
          textCapitalization: TextCapitalization.sentences,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim().toUpperCase()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Registrar Ingreso de Vehículo'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildSectionHeader(
                          Icons.person_pin,
                          'CLIENTE Y VEHÍCULO',
                        ),
                        _buildVehiculoSelector(),
                        if (_selectedVehiculo != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoSection(),
                        ],
                        const SizedBox(height: 20),
                        _buildSectionHeader(
                          Icons.description,
                          'DETALLES DEL SERVICIO',
                        ),
                        _buildProblemDescription(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  _buildBottomSummary(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
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

  Widget _buildVehiculoSelector() {
    return Card(
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
                  _isCreatingVehiculo ? 'Nuevo Vehículo' : 'Buscar Vehículo',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isCreatingVehiculo = !_isCreatingVehiculo;
                      if (_isCreatingVehiculo) {
                        // clear selected
                        _selectedVehiculo = null;
                        _selectedCliente = null;
                      } else {
                        // clear new forms
                        _selectedCliente = null;
                      }
                    });
                  },
                  icon: Icon(
                    _isCreatingVehiculo ? Icons.search : Icons.add,
                    size: 18,
                  ),
                  label: Text(
                    _isCreatingVehiculo
                        ? 'Seleccionar existente'
                        : 'Crear Nuevo',
                  ),
                ),
              ],
            ),
            const Divider(),
            if (_isCreatingVehiculo) ...[
              // New Vehicle Form
              // New Vehicle Form: Only Tipo, Color, Placa (Optional)
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _tipoVehiculo,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Tipo *',
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
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      items:
                          [
                                ..._customTipos,
                                'AUTO',
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
                                      fontStyle: tipo == '+ Agregar nuevo...'
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                      color: tipo == '+ Agregar nuevo...'
                                          ? Colors.blue
                                          : null,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) async {
                        if (v == '+ Agregar nuevo...') {
                          final custom = await _showCustomInputDialog(
                            'Agregar Tipo',
                            'Tipo de vehículo',
                          );
                          if (custom != null && custom.isNotEmpty) {
                            setState(() {
                              _customTipos.add(custom.toUpperCase());
                              _tipoVehiculo = custom.toUpperCase();
                            });
                          }
                        } else {
                          setState(() => _tipoVehiculo = v);
                        }
                      },
                      validator: (v) =>
                          _isCreatingVehiculo &&
                              (v == null ||
                                  v.isEmpty ||
                                  v == '+ Agregar nuevo...')
                          ? 'Requerido'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _marcaVehiculo,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Marca *',
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
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      items: [..._customMarcas, '+ Agregar nueva...']
                          .map(
                            (marca) => DropdownMenuItem(
                              value: marca,
                              child: Text(
                                marca,
                                style: TextStyle(
                                  fontStyle: marca == '+ Agregar nueva...'
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                  color: marca == '+ Agregar nueva...'
                                      ? Colors.blue
                                      : null,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) async {
                        if (v == '+ Agregar nueva...') {
                          final custom = await _showCustomInputDialog(
                            'Agregar Marca',
                            'Marca del vehículo',
                          );
                          if (custom != null && custom.isNotEmpty) {
                            setState(() {
                              _customMarcas.add(custom.toUpperCase());
                              _marcaVehiculo = custom.toUpperCase();
                            });
                          }
                        } else {
                          setState(() => _marcaVehiculo = v);
                        }
                      },
                      validator: (v) =>
                          _isCreatingVehiculo &&
                              (v == null ||
                                  v.isEmpty ||
                                  v == '+ Agregar nueva...')
                          ? 'Requerido'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _colorCtrl,
                      decoration: InputDecoration(
                        labelText: 'Color *',
                        prefixIcon: const Icon(
                          Icons.palette_outlined,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50], // Consistent filled color
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) =>
                          _isCreatingVehiculo && (v == null || v.isEmpty)
                          ? 'Requerido'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _anioCtrl,
                      readOnly:
                          true, // Year is read-only unless we add a picker
                      decoration: InputDecoration(
                        labelText: 'Año (Auto)',
                        prefixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors
                            .grey[200], // Slightly darker to indicate read-only/disabled
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _placaCtrl,
                decoration: InputDecoration(
                  labelText: 'Placa (Opcional)',
                  prefixIcon: const Icon(Icons.numbers_outlined, size: 20),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              const Divider(),
              // Nested Client Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Propietario (${_isCreatingClient ? 'Nuevo' : 'Existente'})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isCreatingClient = !_isCreatingClient;
                        _selectedCliente = null;
                      });
                    },
                    child: Text(
                      _isCreatingClient ? 'Buscar Existente' : 'Nuevo Cliente',
                    ),
                  ),
                ],
              ),
              if (_isCreatingClient) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: DropdownButtonFormField<String>(
                        value: _newClienteTipoDoc,
                        isExpanded: true,
                        items: ['DNI', 'RUC']
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _newClienteTipoDoc = v!),
                        decoration: InputDecoration(
                          labelText: 'Tipo',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _newClienteDocCtrl,
                        maxLength: _newClienteTipoDoc == 'DNI' ? 8 : 11,
                        decoration: InputDecoration(
                          labelText: 'N° Documento *',
                          counterText: '',
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () async {
                              try {
                                final doc = _newClienteDocCtrl.text;
                                if (doc.isEmpty) return;
                                final data = await _repository
                                    .consultaDocumento(_newClienteTipoDoc, doc);
                                if (data != null && mounted) {
                                  setState(() {
                                    if (_newClienteTipoDoc == 'DNI') {
                                      _newClienteNombreCtrl.text =
                                          data['nombre'] ?? '';
                                    } else {
                                      _newClienteNombreCtrl.text =
                                          data['razonSocial'] ?? '';
                                      _newClienteDireccionCtrl.text =
                                          data['direccion'] ?? '';
                                    }
                                  });
                                }
                              } catch (_) {}
                            },
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (!_isCreatingVehiculo || !_isCreatingClient)
                            return null;
                          if (v == null || v.isEmpty) return 'Requerido';
                          if (_newClienteTipoDoc == 'DNI' && v.length != 8) {
                            return 'DNI debe tener 8 dígitos';
                          }
                          if (_newClienteTipoDoc == 'RUC' && v.length != 11) {
                            return 'RUC debe tener 11 dígitos';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _newClienteNombreCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nombre / Razón Social *',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  validator: (v) =>
                      _isCreatingVehiculo &&
                          _isCreatingClient &&
                          (v == null || v.isEmpty)
                      ? 'Requerido'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _newClienteDireccionCtrl,
                  decoration: InputDecoration(
                    labelText: 'Dirección',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ] else ...[
                // Client Autocomplete
                Autocomplete<Cliente>(
                  displayStringForOption: (Cliente option) =>
                      '${option.nombre} (${option.numeroDocumento})',
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<Cliente>.empty();
                    }
                    return _clientes.where((Cliente option) {
                      return option.nombre.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
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
                  fieldViewBuilder:
                      (
                        context,
                        textEditingController,
                        focusNode,
                        onFieldSubmitted,
                      ) {
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Buscar Cliente *',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          validator: (v) {
                            if (_isCreatingVehiculo &&
                                !_isCreatingClient &&
                                _selectedCliente == null)
                              return 'Seleccione un cliente';
                            return null;
                          },
                        );
                      },
                ),
              ],
            ] else ...[
              // Vehicle Autocomplete (Search Mode)
              Autocomplete<Vehiculo>(
                displayStringForOption: (Vehiculo option) =>
                    '${option.tipo} ${option.marca} ${option.modelo} ${option.color} - ${option.placa}',
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<Vehiculo>.empty();
                  }
                  return _vehiculos.where((Vehiculo option) {
                    final search = textEditingValue.text.toLowerCase();
                    return option.placa.toLowerCase().contains(search) ||
                        option.tipo.toLowerCase().contains(search) ||
                        option.marca.toLowerCase().contains(search) ||
                        option.modelo.toLowerCase().contains(search);
                  });
                },
                onSelected: (Vehiculo selection) {
                  setState(() {
                    _selectedVehiculo = selection;
                    try {
                      _selectedCliente = _clientes.firstWhere(
                        (c) => c.id == selection.cliId,
                      );
                    } catch (_) {
                      _selectedCliente = null;
                    }
                  });
                },
                fieldViewBuilder:
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      if (_selectedVehiculo != null &&
                          textEditingController.text.isEmpty &&
                          !focusNode.hasFocus) {
                        textEditingController.text =
                            '${_selectedVehiculo!.tipo} ${_selectedVehiculo!.marca} ${_selectedVehiculo!.modelo}';
                      }
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Buscar Vehículo (Tipo, Placa...) *',
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          suffixIcon: textEditingController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    textEditingController.clear();
                                    setState(() {
                                      _selectedVehiculo = null;
                                      _selectedCliente = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                      );
                    },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProblemDescription() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          controller: _descripcionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe el problema o el mantenimiento a realizar...',
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSummary() {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'REGISTRAR INGRESO VEHÍCULO',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: Theme.of(
                  context,
                ).colorScheme.secondary.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Datos del Cliente',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            _infoRow('Nombre:', _selectedCliente?.nombre ?? 'No encontrado'),
            _infoRow(
              '${_selectedCliente?.tipoDocumento ?? 'Doc'}:',
              _selectedCliente?.numeroDocumento ?? '-',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Datos del Vehículo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            _infoRow(
              'Vehículo:',
              '${_selectedVehiculo?.tipo} ${_selectedVehiculo?.marca} ${_selectedVehiculo?.modelo} ${_selectedVehiculo?.color}',
            ),
            _infoRow(
              'Año/Color:',
              '${_selectedVehiculo?.anio} / ${_selectedVehiculo?.color}',
            ),
            _infoRow('VIN/Chasis:', _selectedVehiculo?.vin ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
