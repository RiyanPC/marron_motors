import 'package:flutter/material.dart';
import '../../models/orden.dart';
import '../../services/data_repository.dart';

class OrdenesPage extends StatefulWidget {
  const OrdenesPage({super.key});

  @override
  State<OrdenesPage> createState() => _OrdenesPageState();
}

class _OrdenesPageState extends State<OrdenesPage> {
  final DataRepository _repository = DataRepository();
  List<OrdenTrabajo> _ordenes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrdenes();
  }

  Future<void> _loadOrdenes() async {
    setState(() => _loading = true);
    final data = await _repository.getOrdenes('1');
    setState(() {
      _ordenes = data;
      _loading = false;
    });
  }

  Future<void> _emitirFactura(OrdenTrabajo orden, String tipo) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await _repository.emitirFactura(orden.id!, tipo);
      Navigator.pop(context); // Close loading

      if (res['status'] == 'success') {
        _loadOrdenes();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Comprobante ${res['data']['serie']}-${res['data']['numero']} aceptado',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError(res['message'] ?? 'Error desconocido');
      }
    } catch (e) {
      Navigator.pop(context);
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error en SUNAT'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CERRAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Órdenes'),
        actions: [
          IconButton(onPressed: _loadOrdenes, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ordenes.isEmpty
          ? const Center(child: Text('No hay órdenes registradas'))
          : ListView.builder(
              itemCount: _ordenes.length,
              itemBuilder: (context, index) {
                final ot = _ordenes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(ot.estado),
                      child: const Icon(
                        Icons.build,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'OT #${(ot.id ?? "").padLeft(5, '0')} - ${ot.vehPlaca}',
                    ),
                    subtitle: Text(
                      '${ot.cliNombre} | S/ ${ot.total.toStringAsFixed(2)}',
                    ),
                    trailing: _buildStatusBadge(ot.estado),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Descripción: ${ot.descripcion}'),
                            const SizedBox(height: 12),
                            if (ot.estado != 'FACTURADA')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _emitirFactura(ot, 'BOLETA'),
                                    icon: const Icon(Icons.receipt_long),
                                    label: const Text('BOLETA'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _emitirFactura(ot, 'FACTURA'),
                                    icon: const Icon(Icons.description),
                                    label: const Text('FACTURA'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Center(
                                child: Chip(
                                  label: Text('COMPROBANTE EMITIDO'),
                                  backgroundColor: Colors.green,
                                  labelStyle: TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ABIERTA':
        return Colors.grey;
      case 'EN_PROCESO':
        return Colors.blue;
      case 'FINALIZADA':
        return Colors.orange;
      case 'FACTURADA':
        return Colors.green;
      default:
        return Colors.black;
    }
  }
}
