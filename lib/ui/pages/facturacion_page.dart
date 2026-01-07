import 'package:flutter/material.dart';
import '../../models/orden.dart';
import '../../services/data_repository.dart';
import '../../core/api_config.dart';
import 'comprobante_preview_page.dart';
import '../widgets/item_selector_modal.dart';

class FacturacionPage extends StatefulWidget {
  const FacturacionPage({super.key});

  @override
  State<FacturacionPage> createState() => _FacturacionPageState();
}

class _FacturacionPageState extends State<FacturacionPage>
    with SingleTickerProviderStateMixin {
  final DataRepository _repository = DataRepository();
  List<OrdenTrabajo> _ordenes = [];
  bool _loading = true;
  late TabController _tabController;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _activeFilter;
  String? _highlightedOrderId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final data = await _repository.getOrdenes(
        '1',
        fechaInicio: _fechaInicio != null
            ? '${_fechaInicio!.year}-${_fechaInicio!.month.toString().padLeft(2, '0')}-${_fechaInicio!.day.toString().padLeft(2, '0')}'
            : null,
        fechaFin: _fechaFin != null
            ? '${_fechaFin!.year}-${_fechaFin!.month.toString().padLeft(2, '0')}-${_fechaFin!.day.toString().padLeft(2, '0')}'
            : null,
      );
      setState(() {
        _ordenes = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Error al cargar órdenes para facturación: $e');
      }
    }
  }

  void _aplicarFiltroRapido(String tipo) {
    final ahora = DateTime.now();
    DateTime inicio;
    DateTime fin = ahora;

    switch (tipo) {
      case 'hoy':
        inicio = DateTime(ahora.year, ahora.month, ahora.day);
        break;
      case '7dias':
        inicio = ahora.subtract(const Duration(days: 7));
        break;
      case 'mes':
        inicio = DateTime(ahora.year, ahora.month, 1);
        break;
      default:
        return;
    }

    setState(() {
      _fechaInicio = inicio;
      _fechaFin = fin;
      _activeFilter = tipo;
    });
    _loadOrdenes();
  }

  Future<void> _mostrarFiltroFechas() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _fechaInicio != null && _fechaFin != null
          ? DateTimeRange(start: _fechaInicio!, end: _fechaFin!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _fechaInicio = picked.start;
        _fechaFin = picked.end;
        _activeFilter = 'especificar';
      });
      _loadOrdenes();
    }
  }

  void _limpiarFiltro() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _activeFilter = null;
    });
    _loadOrdenes();
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  List<String> _validateOrderForBilling(OrdenTrabajo orden, String tipo) {
    List<String> errors = [];
    if (orden.items.isEmpty) {
      errors.add('La orden no tiene items.');
    }
    if (orden.cliNombre == null || orden.cliNombre!.isEmpty) {
      errors.add('Nombre del cliente es requerido.');
    }

    final doc = orden.cliDocumento ?? '';
    if (tipo == 'BOLETA') {
      if (doc.length != 8 && doc.length != 11 && doc.isNotEmpty) {
        // SUNAT accepts DNI(8) or RUC(11) in BOLETA, but usually it's DNI.
      }
      if (orden.total >= 700 && doc.isEmpty) {
        errors.add('Monto >= 700 requiere identificación (DNI).');
      }
    } else if (tipo == 'FACTURA') {
      if (doc.length != 11) {
        errors.add('RUC debe tener 11 dígitos.');
      }
      if (orden.cliDireccion == null || orden.cliDireccion!.isEmpty) {
        errors.add('Dirección es requerida para Factura.');
      }
    }
    return errors;
  }

  Future<void> _confirmarYEmitir(OrdenTrabajo orden, String tipo) async {
    final errors = _validateOrderForBilling(orden, tipo);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar $tipo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (errors.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: errors
                        .map(
                          (e) => Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 14,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildSummaryHeader('DATOS DEL CLIENTE'),
              _buildSummaryRow('Nombre', orden.cliNombre ?? 'N/A'),
              _buildSummaryRow(
                tipo == 'FACTURA' ? 'RUC' : 'DNI',
                orden.cliDocumento ?? 'N/A',
              ),
              if (tipo == 'FACTURA')
                _buildSummaryRow('Dir', orden.cliDireccion ?? 'N/A'),
              const Divider(height: 24),
              _buildSummaryHeader('RESUMEN DE VENTA'),
              _buildSummaryRow('Total Items', orden.items.length.toString()),
              _buildSummaryRow(
                'TOTAL A PAGAR',
                'S/ ${orden.total.toStringAsFixed(2)}',
                isBold: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: errors.isNotEmpty
                ? null
                : () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('EMITIR AHORA'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _emitirFactura(orden, tipo);
    }
  }

  Widget _buildSummaryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _emitirFactura(OrdenTrabajo orden, String tipo) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await _repository.emitirFactura(orden.id!, tipo);
      if (mounted) Navigator.pop(context); // Close loading

      if (res['status'] == 'success') {
        _loadOrdenes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Comprobante ${res['data']['serie']}-${res['data']['numero']} aceptado',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showError(res['message'] ?? 'Error desconocido');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
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

  Future<void> _agregarTrabajo(OrdenTrabajo orden) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ItemSelectorModal(),
    );

    if (result is OrdenItem) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await _repository.agregarItemsAOrden(orden.id!, [result]);

      if (mounted) Navigator.pop(context);

      if (success) {
        final newTotal = orden.total + result.total;
        final updatedItems = List<OrdenItem>.from(orden.items)..add(result);

        final updatedOrden = orden.copyWith(
          total: newTotal,
          items: updatedItems,
        );

        final index = _ordenes.indexWhere((o) => o.id == orden.id);
        if (index != -1) {
          setState(() {
            _ordenes[index] = updatedOrden;
            _highlightedOrderId = orden.id;
          });

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() => _highlightedOrderId = null);
            }
          });
        }

        await _showSuccessDialog(
          'Agregado Correctamente',
          'Se ha añadido "${result.itemNombre}" a la orden.',
        );
      } else {
        _showError('No se pudo añadir el item');
      }
    }
  }

  Future<void> _eliminarItem(OrdenTrabajo orden, OrdenItem item) async {
    final confirm = await _showConfirmDialog(
      'Eliminar Item',
      '¿Deseas eliminar "${item.itemNombre}" de esta orden?',
    );

    if (confirm) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await _repository.eliminarItemDesdeOrden(
        orden.id!,
        item.id!,
      );

      if (mounted) Navigator.pop(context); // Close loading

      if (success) {
        // Optimistic UI Update
        final newTotal = orden.total - item.total;
        final updatedItems = List<OrdenItem>.from(orden.items)
          ..removeWhere((i) => i.id == item.id);

        final updatedOrden = orden.copyWith(
          total: newTotal,
          items: updatedItems,
        );

        final index = _ordenes.indexWhere((o) => o.id == orden.id);
        if (index != -1) {
          setState(() {
            _ordenes[index] = updatedOrden;
            _highlightedOrderId = orden.id;
          });

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() => _highlightedOrderId = null);
            }
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item eliminado correctamente'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showError('No se pudo eliminar el item');
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: Colors.blueGrey.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'CANCELAR',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('CONFIRMAR'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showSuccessDialog(String title, String message) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'ENTENDIDO',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Aviso',
          style: TextStyle(
            color: Colors.blueGrey.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('ENTENDIDO'),
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
        title: const Text('Facturación y Cobros'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(
              _fechaInicio != null || _fechaFin != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            onPressed: _mostrarFiltroFechas,
            tooltip: 'Filtrar por fecha',
          ),
          if (_fechaInicio != null || _fechaFin != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _limpiarFiltro,
              tooltip: 'Limpiar filtro',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            _fechaInicio != null || _fechaFin != null ? 96 : 48,
          ),
          child: Column(
            children: [
              if (_fechaInicio != null || _fechaFin != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.white.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.filter_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mostrando: ${_formatearFecha(_fechaInicio!)} - ${_formatearFecha(_fechaFin!)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(
                    text: 'POR EMITIR',
                    icon: Icon(Icons.pending_actions_rounded),
                  ),
                  Tab(text: 'HISTORIAL', icon: Icon(Icons.history_rounded)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildQuickFilters(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrderList('FINALIZADA'),
                      _buildOrderList('FACTURADA'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterButton(
              label: 'Hoy',
              icon: Icons.today,
              onTap: () => _aplicarFiltroRapido('hoy'),
              isSelected: _activeFilter == 'hoy',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton(
              label: '7 días',
              icon: Icons.date_range,
              onTap: () => _aplicarFiltroRapido('7dias'),
              isSelected: _activeFilter == '7dias',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton(
              label: 'Mes',
              icon: Icons.calendar_month,
              onTap: () => _aplicarFiltroRapido('mes'),
              isSelected: _activeFilter == 'mes',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton(
              label: 'Especificar',
              icon: Icons.edit_calendar,
              onTap: _mostrarFiltroFechas,
              isSelected: _activeFilter == 'especificar',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    if (!isSelected) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
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
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
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
            color: _highlightedOrderId == ot.id
                ? Colors.green.shade50
                : Colors.white,
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
                        color: Theme.of(context).colorScheme.primary,
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
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (ot.items.isNotEmpty) ...[
                      const Divider(height: 24),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ot.items.length,
                        itemBuilder: (context, i) {
                          final item = ot.items[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.green.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.itemNombre ?? 'Item ${i + 1}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Text(
                                  'x${item.cantidad.toInt()} S/ ${item.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (ot.estado != 'FACTURADA')
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _eliminarItem(ot, item),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.only(left: 8),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              // Warning for Empty Finalized Orders in Billing
              if (ot.estado == 'FINALIZADA' && ot.items.isEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Requiere añadir trabajos para facturar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Validation Warnings
              ..._buildValidationWarnings(ot),
              // Actions Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildActions(ot),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
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

  Widget _buildStatusPill(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActions(OrdenTrabajo ot) {
    if (ot.estado == 'FACTURADA') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
          const SizedBox(width: 8),
          Text(
            'ORDEN FACTURADA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          if (ot.facId != null)
            TextButton.icon(
              onPressed: () => _verComprobante(ot.facId!),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text(
                'VER DOCUMENTO',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
        ],
      );
    }

    if (ot.estado == 'FINALIZADA') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'BOLETA',
                  Icons.receipt_outlined,
                  Theme.of(context).colorScheme.primary,
                  () => _confirmarYEmitir(ot, 'BOLETA'),
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  'FACTURAR',
                  Icons.description_rounded,
                  Theme.of(context).colorScheme.primary,
                  () => _confirmarYEmitir(ot, 'FACTURA'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            'AJUSTAR TRABAJO',
            Icons.edit_note_rounded,
            Theme.of(context).colorScheme.primary,
            () => _agregarTrabajo(ot),
            isOutlined: true,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
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

  List<Widget> _buildValidationWarnings(OrdenTrabajo ot) {
    if (ot.estado != 'FINALIZADA') return [];

    List<Widget> warnings = [];

    if (ot.items.isEmpty) {
      warnings.add(_warningBox('Requiere añadir trabajos para facturar'));
    }

    // Check for general missing data
    if (ot.cliNombre == null || ot.cliNombre!.isEmpty) {
      warnings.add(_warningBox('Falta nombre del cliente'));
    }

    final doc = ot.cliDocumento ?? '';
    if (doc.isEmpty) {
      warnings.add(_warningBox('Falta Documento (DNI/RUC)'));
    } else if (doc.length != 8 && doc.length != 11) {
      warnings.add(
        _warningBox('Documento debe ser 8 dígitos (DNI) o 11 (RUC)'),
      );
    }

    return warnings;
  }

  Widget _warningBox(String message) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber.shade800,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                color: Colors.amber.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'FINALIZADA':
        return Colors.orange;
      case 'FACTURADA':
        return Colors.green;
      default:
        return Colors.black;
    }
  }
}
