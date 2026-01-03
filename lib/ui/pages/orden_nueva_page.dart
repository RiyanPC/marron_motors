import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/data_repository.dart';
import '../../models/orden.dart';
import '../../models/vehiculo.dart';
import '../../models/cliente.dart';
import '../widgets/vehiculo_selector_modal.dart';

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
      final clients = await _repository.getClientes('1');
      setState(() {
        _clientes = clients;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedVehiculo == null) return;
    _formKey.currentState!.save();

    final orden = OrdenTrabajo(
      empId: '1',
      vehId: _selectedVehiculo?.id ?? '',
      descripcion: _descripcionController.text,
      fechaIngreso: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      estado: 'ABIERTA',
      total: 0,
      items: [],
    );

    try {
      final success = await _repository.crearOrden(orden);
      if (success) {
        Navigator.pop(context, true); // Retornamos true para refrescar la lista
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingreso registrado correctamente')),
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
          Icon(icon, size: 20, color: const Color(0xFF0D47A1)),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D47A1),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiculoSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          final result = await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) =>
                VehiculoSelectorModal(initialSelectedId: _selectedVehiculo?.id),
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: const Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedVehiculo != null
                          ? _selectedVehiculo!.placa
                          : 'Seleccionar Vehículo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedVehiculo != null
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                    if (_selectedVehiculo != null)
                      Text(
                        '${_selectedVehiculo!.marca} ${_selectedVehiculo!.modelo}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      )
                    else
                      const Text(
                        'Toca para buscar placa o vehículo',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
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
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: Colors.blue.withOpacity(0.4),
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
                Icon(Icons.person, size: 18, color: const Color(0xFF0D47A1)),
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
                  color: const Color(0xFF0D47A1),
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
}
