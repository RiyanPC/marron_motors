import 'package:flutter/material.dart';
import '../../models/orden.dart';
import '../../services/data_repository.dart';
import '../../core/api_config.dart';
import 'comprobante_preview_page.dart';

class OrdenesPage extends StatefulWidget {
  const OrdenesPage({super.key});

  @override
  State<OrdenesPage> createState() => _OrdenesPageState();
}

class _OrdenesPageState extends State<OrdenesPage>
    with SingleTickerProviderStateMixin {
  final DataRepository _repository = DataRepository();
  List<OrdenTrabajo> _ordenes = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrdenes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrdenes() async {
    setState(() => _loading = true);
    try {
      final data = await _repository.getOrdenes('1');
      setState(() {
        _ordenes = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Error al cargar órdenes: $e');
    }
  }

  Future<void> _updateStatus(OrdenTrabajo orden, String newStatus) async {
    setState(() => _loading = true);
    final success = await _repository.actualizarEstadoOrden(
      orden.id!,
      newStatus,
    );
    if (success) {
      await _loadOrdenes();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Orden actualizada a $newStatus')));
    } else {
      setState(() => _loading = false);
      _showError('No se pudo actualizar el estado');
    }
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

  Future<void> _verComprobante(String facId) async {
    final url = '${ApiConfig.baseUrl}/facturas/ver.php?id=$facId';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ComprobantePreviewPage(url: url, title: 'Factura #$facId'),
      ),
    );
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aviso'),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gestión de Órdenes'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.blue.shade900,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue.shade900,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'PENDIENTES', icon: Icon(Icons.pending_actions)),
            Tab(text: 'EN PROCESO', icon: Icon(Icons.build_circle)),
            Tab(text: 'FINALIZADAS', icon: Icon(Icons.check_circle)),
            Tab(text: 'FACTURADAS', icon: Icon(Icons.receipt_long)),
          ],
        ),
        actions: [
          IconButton(onPressed: _loadOrdenes, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList('ABIERTA'),
                _buildOrderList('EN_PROCESO'),
                _buildOrderList('FINALIZADA'),
                _buildOrderList('FACTURADA'),
              ],
            ),
    );
  }

  Widget _buildOrderList(String status) {
    final filtered = _ordenes.where((o) => o.estado == status).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No hay registros en esta sección',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final ot = filtered[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ot.vehPlaca ?? 'S/P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildStatusPill(ot.estado),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.person,
                      'CLIENTE',
                      ot.cliNombre ?? 'No asignado',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.build_circle_outlined,
                      'SERVICIO',
                      ot.descripcion,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailRow(
                            Icons.calendar_month,
                            'FECHA',
                            ot.fechaIngreso,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            'S/ ${ot.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action Footer
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: _buildActionButtons(ot),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.replaceAll('_', ' '),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey.shade400),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blueGrey.shade300,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(OrdenTrabajo ot) {
    if (ot.estado == 'FACTURADA') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'ORDEN COMPLETADA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          if (ot.facId != null)
            TextButton.icon(
              onPressed: () => _verComprobante(ot.facId!),
              icon: const Icon(Icons.file_present_rounded, size: 18),
              label: const Text(
                'VER DOCUMENTO',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (ot.estado == 'ABIERTA')
          _buildActionButton(
            'INICIAR TRABAJO',
            Icons.play_arrow_rounded,
            Colors.blue.shade800,
            () => _updateStatus(ot, 'EN_PROCESO'),
          ),
        if (ot.estado == 'EN_PROCESO')
          _buildActionButton(
            'FINALIZAR',
            Icons.task_alt_rounded,
            Colors.orange.shade800,
            () => _updateStatus(ot, 'FINALIZADA'),
          ),
        if (ot.estado == 'FINALIZADA') ...[
          _buildActionButton(
            'BOLETA',
            Icons.receipt_outlined,
            Colors.blueGrey.shade700,
            () => _emitirFactura(ot, 'BOLETA'),
            isOutlined: true,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            'FACTURAR',
            Icons.description_rounded,
            Colors.blue.shade900,
            () => _emitirFactura(ot, 'FACTURA'),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
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
