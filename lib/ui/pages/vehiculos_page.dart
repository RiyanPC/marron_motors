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
  List<Vehiculo> _filteredVehiculos = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVehiculos();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterVehiculos(_searchController.text);
  }

  void _filterVehiculos(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVehiculos = _vehiculos;
      } else {
        _filteredVehiculos = _vehiculos.where((v) {
          final placa = v.placa.toLowerCase();
          final marca = v.marca.toLowerCase();
          final modelo = v.modelo.toLowerCase();
          final cliente = v.cliNombre.toLowerCase();
          final searchLower = query.toLowerCase();
          return placa.contains(searchLower) ||
              marca.contains(searchLower) ||
              modelo.contains(searchLower) ||
              cliente.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _loadVehiculos() async {
    setState(() => _loading = true);
    try {
      final data = await _repository.getVehiculos('1'); // Hardcoded emp_id
      setState(() {
        _vehiculos = data;
        _filteredVehiculos = data;
        _loading = false;
      });
      if (_searchController.text.isNotEmpty) {
        _filterVehiculos(_searchController.text);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Inventario de Vehículos'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VehiculoFormPage()),
          );
          if (result != null) _loadVehiculos();
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_road),
        label: const Text('NUEVO VEHÍCULO'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por placa, marca o cliente...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVehiculos.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadVehiculos,
                    color: Theme.of(context).colorScheme.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredVehiculos.length,
                      itemBuilder: (context, index) {
                        return _buildVehiculoCard(_filteredVehiculos[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isEmpty
                ? Icons.directions_car_outlined
                : Icons.no_sim_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No hay vehículos registrados'
                : 'Sin resultados para la búsqueda',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            TextButton(
              onPressed: () => _searchController.clear(),
              child: const Text('Limpiar búsqueda'),
            ),
        ],
      ),
    );
  }

  Widget _buildVehiculoCard(Vehiculo veh) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehiculoDetallePage(vehiculo: veh),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  image: veh.foto.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(veh.foto),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: veh.foto.isEmpty
                    ? Icon(
                        Icons.directions_car,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      veh.placa,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${veh.marca} ${veh.modelo}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            veh.cliNombre,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (val) async {
                  if (val == 'view') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VehiculoDetallePage(vehiculo: veh),
                      ),
                    );
                  } else if (val == 'edit') {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VehiculoFormPage(vehiculo: veh),
                      ),
                    );
                    if (result != null) _loadVehiculos();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Detalles'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
