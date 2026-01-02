import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';
import '../../services/data_repository.dart';
import '../pages/vehiculo_form_page.dart';

class VehiculoSelectorModal extends StatefulWidget {
  final String? initialSelectedId;
  const VehiculoSelectorModal({super.key, this.initialSelectedId});

  @override
  State<VehiculoSelectorModal> createState() => _VehiculoSelectorModalState();
}

class _VehiculoSelectorModalState extends State<VehiculoSelectorModal> {
  final _repository = DataRepository();
  final _searchController = TextEditingController();
  List<Vehiculo> _allVehiculos = [];
  List<Vehiculo> _filteredVehiculos = [];
  bool _loading = true;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelectedId;
    _loadVehiculos();
    _searchController.addListener(_filterVehiculos);
  }

  Future<void> _loadVehiculos() async {
    try {
      final data = await _repository.getVehiculos('1'); // Hardcoded emp_id
      setState(() {
        _allVehiculos = data;
        _filteredVehiculos = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar vehículos: $e')),
        );
      }
    }
  }

  void _filterVehiculos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredVehiculos = _allVehiculos.where((v) {
        return v.placa.toLowerCase().contains(query) ||
            v.marca.toLowerCase().contains(query) ||
            v.modelo.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Seleccionar Vehículo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar por placa, marca o modelo',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehiculoFormPage()),
              );
              if (result is Vehiculo) {
                setState(() => _loading = true);
                await _loadVehiculos();
                setState(() {
                  _selectedId = result.id;
                });
              }
            },
            icon: const Icon(Icons.add_road),
            label: const Text('NUEVO VEHÍCULO'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVehiculos.isEmpty
                ? const Center(child: Text('No se encontraron vehículos'))
                : ListView.builder(
                    itemCount: _filteredVehiculos.length,
                    itemBuilder: (context, index) {
                      final veh = _filteredVehiculos[index];
                      final isSelected = _selectedId == veh.id;
                      return Card(
                        elevation: isSelected ? 4 : 1,
                        color: isSelected ? Colors.blue.shade50 : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.blue
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: const Icon(Icons.directions_car),
                          ),
                          title: Text(
                            veh.placa,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '${veh.marca} ${veh.modelo} • ${veh.cliNombre}',
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              if (val == true) {
                                setState(() => _selectedId = veh.id);
                              }
                            },
                          ),
                          onTap: () {
                            setState(() => _selectedId = veh.id);
                          },
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _selectedId == null
                ? null
                : () {
                    final selected = _allVehiculos.firstWhere(
                      (v) => v.id == _selectedId,
                    );
                    Navigator.pop(context, selected);
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('CONFIRMAR SELECCIÓN'),
          ),
        ],
      ),
    );
  }
}
