import 'package:flutter/material.dart';
import '../../models/cliente.dart';
import '../../services/data_repository.dart';
import '../pages/cliente_form_page.dart';

class ClienteSelectorModal extends StatefulWidget {
  final String? initialSelectedId;
  const ClienteSelectorModal({super.key, this.initialSelectedId});

  @override
  State<ClienteSelectorModal> createState() => _ClienteSelectorModalState();
}

class _ClienteSelectorModalState extends State<ClienteSelectorModal> {
  final _repository = DataRepository();
  final _searchController = TextEditingController();
  List<Cliente> _allClientes = [];
  List<Cliente> _filteredClientes = [];
  bool _loading = true;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelectedId;
    _loadClientes();
    _searchController.addListener(_filterClientes);
  }

  Future<void> _loadClientes() async {
    try {
      final data = await _repository.getClientes('1'); // Hardcoded emp_id
      setState(() {
        _allClientes = data;
        _filteredClientes = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar clientes: $e')));
      }
    }
  }

  void _filterClientes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClientes = _allClientes.where((c) {
        return c.nombre.toLowerCase().contains(query) ||
            c.numeroDocumento.toLowerCase().contains(query);
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
                'Seleccionar Cliente',
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
              labelText: 'Buscar por nombre o documento',
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
                MaterialPageRoute(builder: (_) => const ClienteFormPage()),
              );
              if (result is Cliente) {
                // Si se creó un cliente, recargamos la lista y lo seleccionamos
                setState(() => _loading = true);
                await _loadClientes();
                setState(() {
                  _selectedId = result.id;
                });
              }
            },
            icon: const Icon(Icons.person_add),
            label: const Text('NUEVO CLIENTE'),
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
                : _filteredClientes.isEmpty
                ? const Center(child: Text('No se encontraron clientes'))
                : ListView.builder(
                    itemCount: _filteredClientes.length,
                    itemBuilder: (context, index) {
                      final cliente = _filteredClientes[index];
                      final isSelected = _selectedId == cliente.id;
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
                            child: Text(cliente.nombre[0].toUpperCase()),
                          ),
                          title: Text(
                            cliente.nombre,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '${cliente.tipoDocumento}: ${cliente.numeroDocumento}',
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              if (val == true) {
                                setState(() => _selectedId = cliente.id);
                              }
                            },
                          ),
                          onTap: () {
                            setState(() => _selectedId = cliente.id);
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
                    final selected = _allClientes.firstWhere(
                      (c) => c.id == _selectedId,
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
