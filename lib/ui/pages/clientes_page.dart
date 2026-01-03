import 'package:flutter/material.dart';
import '../../services/data_repository.dart';
import '../../models/cliente.dart';
import 'cliente_form_page.dart';
import 'cliente_detalle_page.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final DataRepository _repository = DataRepository();
  List<Cliente> _clientes = [];
  List<Cliente> _filteredClientes = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClientes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterClientes(_searchController.text);
  }

  void _filterClientes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredClientes = _clientes;
      } else {
        _filteredClientes = _clientes.where((c) {
          final nombre = c.nombre.toLowerCase();
          final documento = c.numeroDocumento.toLowerCase();
          final searchLower = query.toLowerCase();
          return nombre.contains(searchLower) ||
              documento.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _loadClientes() async {
    setState(() => _loading = true);
    try {
      final data = await _repository.getClientes('1');
      setState(() {
        _clientes = data;
        _filteredClientes = data;
        _loading = false;
      });
      if (_searchController.text.isNotEmpty) {
        _filterClientes(_searchController.text);
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
        title: const Text('Directorio de Clientes'),
        elevation: 0,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ClienteFormPage()),
          );
          if (result != null) _loadClientes();
        },
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('NUEVO CLIENTE'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0D47A1),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o documento...',
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
                : _filteredClientes.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadClientes,
                    color: const Color(0xFF0D47A1),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredClientes.length,
                      itemBuilder: (context, index) {
                        return _buildClienteCard(_filteredClientes[index]);
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
                ? Icons.people_outline
                : Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No hay clientes registrados'
                : 'No se encontraron resultados',
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

  Widget _buildClienteCard(Cliente cliente) {
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
              builder: (context) => ClienteDetallePage(cliente: cliente),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF0D47A1).withOpacity(0.1),
                child: Text(
                  cliente.nombre[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF0D47A1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cliente.nombre,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusBadge(cliente.estado),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cliente.tipoDocumento}: ${cliente.numeroDocumento}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          cliente.telefono.isEmpty ? 'N/A' : cliente.telefono,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (val) async {
                  if (val == 'view') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ClienteDetallePage(cliente: cliente),
                      ),
                    );
                  } else if (val == 'edit') {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClienteFormPage(cliente: cliente),
                      ),
                    );
                    if (result != null) _loadClientes();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Ver Detalle'),
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

  Widget _buildStatusBadge(String estado) {
    final isActive = estado == 'ACTIVO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.green[700] : Colors.red[700],
        ),
      ),
    );
  }
}
