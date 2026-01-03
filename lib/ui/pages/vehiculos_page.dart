import 'package:flutter/material.dart';
import '../../services/data_repository.dart';
import '../../models/vehiculo.dart';
import 'vehiculo_form_page.dart';
import 'vehiculo_detalle_page.dart';

class VehiculosPage extends StatefulWidget {
  const VehiculosPage({super.key});

  @override
  State<VehiculosPage> createState() => _VehiculosPageState();
}

class _VehiculosPageState extends State<VehiculosPage> {
  final DataRepository _repository = DataRepository();
  List<Vehiculo> _vehiculos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVehiculos();
  }

  Future<void> _loadVehiculos() async {
    try {
      final data = await _repository.getVehiculos('1'); // Hardcoded emp_id
      setState(() {
        _vehiculos = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehículos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VehiculoFormPage()),
          );
          if (result != null) _loadVehiculos();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vehiculos.isEmpty
          ? const Center(child: Text('No hay vehículos registrados'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _vehiculos.length,
              itemBuilder: (context, index) {
                final veh = _vehiculos[index];
                return Card(
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VehiculoDetallePage(vehiculo: veh),
                        ),
                      );
                    },
                    leading: const Icon(
                      Icons.directions_car,
                      color: Colors.blue,
                    ),
                    title: Text(
                      veh.placa,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${veh.marca} ${veh.modelo} • ${veh.cliNombre}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.visibility,
                            color: const Color(0xFF0D47A1),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    VehiculoDetallePage(vehiculo: veh),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    VehiculoFormPage(vehiculo: veh),
                              ),
                            );
                            if (result != null) _loadVehiculos();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
