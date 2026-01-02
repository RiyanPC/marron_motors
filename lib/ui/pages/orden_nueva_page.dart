import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/data_repository.dart';
import '../../models/orden.dart';
import '../../models/vehiculo.dart';
import '../../models/cliente.dart';
import '../../models/item.dart';

class OrdenNuevaPage extends StatefulWidget {
  const OrdenNuevaPage({super.key});

  @override
  State<OrdenNuevaPage> createState() => _OrdenNuevaPageState();
}

class _OrdenNuevaPageState extends State<OrdenNuevaPage> {
  final DataRepository _repository = DataRepository();
  final _formKey = GlobalKey<FormState>();

  String? _selectedVehiculoId;
  Vehiculo? _selectedVehiculo;
  Cliente? _selectedCliente;
  String _descripcion = '';
  List<Vehiculo> _vehiculos = [];
  List<Cliente> _clientes = [];
  List<Item> _availableItems = [];
  List<OrdenItem> _selectedItems = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final vehs = await _repository.getVehiculos('1');
      final items = await _repository.getItems('1');
      final clients = await _repository.getClientes('1');
      setState(() {
        _vehiculos = vehs;
        _availableItems = items;
        _clientes = clients;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  double get _total => _selectedItems.fold(0, (sum, item) => sum + item.total);

  void _addItem(Item item) {
    setState(() {
      _selectedItems.add(
        OrdenItem(
          itemId: item.id,
          cantidad: 1,
          precioUnitario: item.precio,
          subtotal: item.precio,
          igv: item.precio * 0.18,
          total: item.precio * 1.18,
        ),
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedVehiculoId == null)
      return;
    _formKey.currentState!.save();

    final orden = OrdenTrabajo(
      empId: '1',
      vehId: _selectedVehiculoId!,
      descripcion: _descripcion,
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
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Vehículo'),
                    items: _vehiculos
                        .map(
                          (v) => DropdownMenuItem(
                            value: v.id,
                            child: Text('${v.placa} - ${v.marca}'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedVehiculoId = val;
                        _selectedVehiculo = _vehiculos.firstWhere(
                          (v) => v.id == val,
                        );
                        _selectedCliente = _clientes.firstWhere(
                          (c) => c.id == _selectedVehiculo?.cliId,
                        );
                      });
                    },
                  ),
                  if (_selectedVehiculo != null) ...[
                    const SizedBox(height: 16),
                    _buildInfoSection(),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Descripción del problema',
                    ),
                    maxLines: 3,
                    onSaved: (val) => _descripcion = val ?? '',
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Items / Servicios',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ..._selectedItems.map((oi) {
                    final item = _availableItems.firstWhere(
                      (i) => i.id == oi.itemId,
                    );
                    return ListTile(
                      title: Text(item.nombre),
                      subtitle: Text(
                        'Cant: ${oi.cantidad} x S/ ${oi.precioUnitario}',
                      ),
                      trailing: Text('S/ ${oi.total.toStringAsFixed(2)}'),
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

  void _showItemSelector() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: _availableItems.length,
        itemBuilder: (ctx, idx) {
          final item = _availableItems[idx];
          return ListTile(
            title: Text(item.nombre),
            subtitle: Text('S/ ${item.precio}'),
            onTap: () {
              _addItem(item);
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }
}
