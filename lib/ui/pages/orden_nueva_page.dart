import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/data_repository.dart';
import '../../models/orden.dart';
import '../../models/vehiculo.dart';
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
  String _descripcion = '';
  List<Vehiculo> _vehiculos = [];
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
      setState(() {
        _vehiculos = vehs;
        _availableItems = items;
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
                    onChanged: (val) =>
                        setState(() => _selectedVehiculoId = val),
                  ),
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
