import 'package:flutter/material.dart';
import '../../services/data_repository.dart';
import '../../models/cliente.dart';

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
                    leading: CircleAvatar(child: Text(cliente.nombre[0])),
                    title: Text(cliente.nombre),
                    subtitle: Text(
                      '${cliente.tipoDocumento}: ${cliente.numeroDocumento} • ${cliente.telefono}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // TODO: Detalle del cliente
                    },
                  ),
                );
              },
            ),
    );
  }
}
