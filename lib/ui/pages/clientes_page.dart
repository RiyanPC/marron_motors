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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    try {
      final data = await _repository.getClientes(
        '1',
      ); // Hardcoded emp_id for demo
      setState(() {
        _clientes = data;
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
      appBar: AppBar(title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ClienteFormPage()),
          );
          if (result != null) _loadClientes();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _clientes.isEmpty
          ? const Center(child: Text('No hay clientes registrados'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _clientes.length,
              itemBuilder: (context, index) {
                final cliente = _clientes[index];
                return Card(
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ClienteDetallePage(cliente: cliente),
                        ),
                      );
                    },
                    leading: CircleAvatar(child: Text(cliente.nombre[0])),
                    title: Text(cliente.nombre),
                    subtitle: Text(
                      '${cliente.tipoDocumento}: ${cliente.numeroDocumento} • ${cliente.telefono}',
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
                                    ClienteDetallePage(cliente: cliente),
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
                                    ClienteFormPage(cliente: cliente),
                              ),
                            );
                            if (result != null) _loadClientes();
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
