import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/data_repository.dart';
import '../../models/orden.dart';
import '../../models/vehiculo.dart';
import '../../models/cliente.dart';
import '../../models/item.dart';
import '../widgets/vehiculo_selector_modal.dart';
import '../widgets/item_selector_modal.dart';

class OrdenNuevaPage extends StatefulWidget {
  const OrdenNuevaPage({super.key});

  @override
  State<OrdenNuevaPage> createState() => _OrdenNuevaPageState();
}

class _OrdenNuevaPageState extends State<OrdenNuevaPage> {
  final DataRepository _repository = DataRepository();
  final _formKey = GlobalKey<FormState>();

  Vehiculo? _selectedVehiculo;
  Cliente? _selectedCliente;
  late TextEditingController _descripcionController;
  List<Cliente> _clientes = [];
  List<Item> _availableItems = [];
  List<OrdenItem> _selectedItems = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _descripcionController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final items = await _repository.getItems('1');
      final clients = await _repository.getClientes('1');
      setState(() {
        _availableItems = items;
        _clientes = clients;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  double get _total => _selectedItems.fold(0, (sum, item) => sum + item.total);

  void _addItem(OrdenItem ordenItem) {
    setState(() {
      _selectedItems.add(ordenItem);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedVehiculo == null) return;
    _formKey.currentState!.save();

    final orden = OrdenTrabajo(
      empId: '1',
      vehId: _selectedVehiculo?.id ?? '',
      descripcion: _descripcionController.text,
      fechaIngreso: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      total: _total,
      items: _selectedItems,
    );

    try {
      final success = await _repository.crearOrden(orden);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden creada correctamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Orden')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  InkWell(
                    onTap: () async {
                      final result = await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) => VehiculoSelectorModal(
                          initialSelectedId: _selectedVehiculo?.id,
                        ),
                      );

                      if (result is Vehiculo) {
                        setState(() {
                          _selectedVehiculo = result;
                          _selectedCliente = _clientes.firstWhere(
                            (c) => c.id == _selectedVehiculo?.cliId,
                            orElse: () => _selectedCliente!, // Fallback
                          );
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Vehículo *',
                        prefixIcon: Icon(Icons.directions_car),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      child: Text(
                        _selectedVehiculo != null
                            ? '${_selectedVehiculo!.placa} - ${_selectedVehiculo!.marca} ${_selectedVehiculo!.modelo}'
                            : 'Toca para seleccionar un vehículo',
                        style: TextStyle(
                          color: _selectedVehiculo != null
                              ? Colors.black
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  if (_selectedVehiculo != null) ...[
                    const SizedBox(height: 16),
                    _buildInfoSection(),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción del problema',
                    ),
                    maxLines: 3,
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Items / Servicios',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ..._selectedItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final oi = entry.value;
                    final item = _availableItems.firstWhere(
                      (i) => i.id == oi.itemId,
                      orElse: () => Item(
                        id: oi.itemId,
                        empId: '',
                        nombre: 'Item desconocido',
                        descripcion: '',
                        tipo: 'SERVICIO',
                        precio: 0,
                        codigoTributo: '10',
                        estado: 'ACTIVO',
                      ),
                    );
                    return ListTile(
                      title: Text(item.nombre),
                      subtitle: Text(
                        'Cant: ${oi.cantidad} x S/ ${oi.precioUnitario.toStringAsFixed(2)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'S/ ${oi.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedItems.removeAt(idx);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => _showItemSelector(),
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir Item'),
                  ),
                  const Divider(),
                  Text(
                    'Total con IGV: S/ ${_total.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('CREAR ORDEN'),
                  ),
                ],
              ),
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
                Icon(Icons.person, size: 18, color: Colors.blue.shade700),
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
                  color: Colors.blue.shade700,
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
              '${_selectedVehiculo?.marca} ${_selectedVehiculo?.modelo}',
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

  void _showItemSelector() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ItemSelectorModal(),
    );

    if (result is OrdenItem) {
      _addItem(result);
    }
  }
}
