import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../../models/orden.dart';
import '../../models/item.dart';
import '../../services/data_repository.dart';
import 'orden_nueva_page.dart';
import 'orden_detalle_page.dart';
import 'facturacion_page.dart';
import '../widgets/item_selector_modal.dart';
import '../widgets/item_editor_dialog.dart';
import '../../core/api_config.dart';
import 'comprobante_preview_page.dart';

class OrdenesPage extends StatefulWidget {
  final int initialTabIndex;
  const OrdenesPage({super.key, this.initialTabIndex = 0});

  @override
  State<OrdenesPage> createState() => _OrdenesPageState();
}

class _OrdenesPageState extends State<OrdenesPage>
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
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
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
      setState(() => _loading = false);
      _showError('Error al cargar órdenes: $e');
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

  Future<void> _updateStatus(OrdenTrabajo orden, String newStatus) async {
    final success = await _repository.actualizarEstadoOrden(
      orden.id!,
      newStatus,
    );

    if (success) {
      // Optimistic update: update state and reorder
      final updatedOrden = orden.copyWith(estado: newStatus);
      setState(() {
        // Remove from current position
        _ordenes.removeWhere((o) => o.id == orden.id);
        // Add at the beginning (top of the list)
        _ordenes.insert(0, updatedOrden);
      });

      if (newStatus == 'FINALIZADA') {
        _showFinalizationSuccess(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Orden actualizada a $newStatus')),
        );
      }
    } else {
      _showError('No se pudo actualizar el estado');
    }
  }

  // Removed _emitirFactura and _verComprobante as they moved to FacturacionPage

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
      // Show processing dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await _repository.agregarItemsAOrden(orden.id!, [result]);

      // Close processing dialog
      if (mounted) Navigator.pop(context);

      if (success) {
        // Reload orders to get updated items with IDs from backend
        await _loadOrdenes();

        await _showSuccessDialog(
          'Agregado Correctamente',
          'Se ha añadido "${result.itemNombre}" a la orden.',
        );
      } else {
        _showError('No se pudo añadir el item');
      }
    }
  }

  // Removed _eliminarItem as finalized item management moved to dedicated views/modules

  Future<void> _pickAndUploadFoto(OrdenTrabajo ot) async {
    final picker = ImagePicker();
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile == null) return;

    setState(() => _loading = true);
    try {
      final String? url = await _repository.uploadImage(
        File(pickedFile.path),
        folder: 'estado_orden',
        name: 'ot_${ot.id}',
      );

      if (url != null) {
        final success = await _repository.actualizarFotoOrden(ot.id!, url);
        if (success) {
          final newOrden = ot.copyWith(foto: url);
          _updateLocalOrder(newOrden);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto subida correctamente')),
          );
        } else {
          _showError('No se pudo actualizar la foto en la base de datos');
        }
      } else {
        _showError('Error al subir la imagen al servidor');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _downloadAndShareImage(String url) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preparando imagen...')));

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final xfile = XFile.fromData(
          bytes,
          name: 'vehiculo_${DateTime.now().millisecondsSinceEpoch}.jpg',
          mimeType: 'image/jpeg',
        );

        await Share.shareXFiles([xfile], text: 'Foto del vehículo');
      } else {
        _showError('No se pudo descargar la imagen');
      }
    } catch (e) {
      _showError('Error al compartir: $e');
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
                color: Theme.of(context).colorScheme.primary,
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
            color: Theme.of(context).colorScheme.primary,
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

  void _showFinalizationSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 60,
                        color: Colors.green.shade600,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Orden Finalizada!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'El trabajo ha sido completado.\nYa puedes proceder con la facturación.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('LUEGO'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FacturacionPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'FACTURAR',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gestión de Órdenes'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
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
                isScrollable: true,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(
                    text: 'ABIERTAS',
                    icon: Icon(Icons.door_front_door_outlined),
                  ),
                  Tab(
                    text: 'EN PROCESO',
                    icon: Icon(Icons.build_circle_outlined),
                  ),
                  Tab(text: 'FINALIZADOS', icon: Icon(Icons.task_alt_rounded)),
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
                      _buildOrderList('ABIERTA'),
                      _buildOrderList('EN_PROCESO'),
                      _buildOrderList('FINALIZADA', includeFacturada: true),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrdenNuevaPage()),
          );
          if (result != null) _loadOrdenes();
        },
        icon: const Icon(Icons.add),
        label: const Text('NUEVA ORDEN'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
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
        backgroundColor: Theme.of(context).colorScheme.secondary,
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

  Widget _buildOrderList(String status, {bool includeFacturada = false}) {
    final filtered = _ordenes.where((o) {
      if (includeFacturada) {
        return o.estado == 'FINALIZADA' || o.estado == 'FACTURADA';
      }
      return o.estado == status;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
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
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _highlightedOrderId == ot.id
                ? Colors.green.shade50
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (ot.vehPlaca != null && ot.vehPlaca!.isNotEmpty)
                            ? ot.vehPlaca!
                            : (ot.vehTipo ?? 'S/P'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
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
                padding: const EdgeInsets.all(12),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (ot.foto != null && ot.foto!.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: EdgeInsets.zero,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Container(
                                        color: Colors.black.withOpacity(0.9),
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                    InteractiveViewer(
                                      maxScale: 4.0,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          ot.foto!,
                                          fit: BoxFit.contain,
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.95,
                                          height:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.8,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 40,
                                      right: 70,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.white,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.download,
                                            color: Colors.black,
                                          ),
                                          onPressed: () =>
                                              _downloadAndShareImage(ot.foto!),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 40,
                                      right: 20,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.white,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.black,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 100, // Slightly wider
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                              color: Colors.grey.shade50,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                ot.foto!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Icon(
                                        Icons.directions_car,
                                        color: Colors.grey,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          children: [
                            _buildDetailRow(
                              Icons.person,
                              'CLIENTE',
                              ot.cliNombre ?? 'No asignado',
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              Icons.directions_car_filled_outlined,
                              'VEHÍCULO',
                              (ot.vehPlaca != null && ot.vehPlaca!.isNotEmpty)
                                  ? ot.vehPlaca!
                                  : (ot.vehTipo ?? 'S/P'),
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              Icons.build_circle_outlined,
                              'SERVICIO SOLICITADO',
                              ot.descripcion,
                            ),
                            const SizedBox(height: 8),
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
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    'S/ ${ot.total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (ot.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [const Divider(height: 16), _buildItemsList(ot)],
                  ),
                ),

              // Removed Warning for Empty Finalized Orders as it's handled in FacturacionPage
              // Actions Section
              Padding(
                padding: const EdgeInsets.all(12),
                child: _buildActions(ot),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemsList(OrdenTrabajo ot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DETALLE DE TRABAJOS:',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        ...ot.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 12,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.itemNombre ?? 'Sin nombre',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text(
                  'x${item.cantidad.toInt()}  S/ ${item.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (ot.estado == 'EN_PROCESO') ...[
                  const SizedBox(width: 8), // Increased spacing
                  InkWell(
                    onTap: () => _editarItem(ot, item),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(
                        8,
                      ), // Increased touch target
                      child: Icon(
                        Icons.edit,
                        size: 18, // Slightly larger icon
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _eliminarItem(ot, item),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(
                        8,
                      ), // Increased touch target
                      child: Icon(
                        Icons.close,
                        size: 18, // Slightly larger icon
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ot.estado == 'ABIERTA')
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildActionButton(
                'SUBIR FOTO',
                Icons.add_a_photo_outlined,
                Colors.teal.shade700,
                () => _pickAndUploadFoto(ot),
                isOutlined: true,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                'INICIAR TRABAJO',
                Icons.play_arrow_rounded,
                Theme.of(context).colorScheme.primary,
                () async {
                  final confirm = await _showConfirmDialog(
                    'Iniciar Trabajo',
                    '¿Confirmas que deseas pasar esta orden a estado "En Proceso"?',
                  );
                  if (confirm) {
                    _updateStatus(ot, 'EN_PROCESO');
                  }
                },
              ),
            ],
          ),
        if (ot.estado == 'EN_PROCESO')
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildActionButton(
                'SUBIR FOTO',
                Icons.add_a_photo_outlined,
                Colors.teal.shade700,
                () => _pickAndUploadFoto(ot),
                isOutlined: true,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'AÑADIR TRABAJO',
                      Icons.add_circle_outline,
                      const Color(0xFF1565C0),
                      () => _agregarTrabajo(ot),
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      'FINALIZAR',
                      Icons.task_alt_rounded,
                      Colors.orange.shade800,
                      () async {
                        final confirm = await _showConfirmDialog(
                          'Finalizar Trabajo',
                          '¿Confirmas que deseas finalizar el trabajo? La orden pasará al módulo de FACTURACIÓN.',
                        );
                        if (confirm) {
                          _updateStatus(ot, 'FINALIZADA');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        if (ot.estado == 'FINALIZADA')
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'VER DETALLE',
                  Icons.visibility_outlined,
                  const Color.fromARGB(255, 57, 146, 173),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrdenDetallePage(orden: ot),
                    ),
                  ),
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  'EMITIR',
                  Icons.receipt_long_rounded,
                  Colors.green.shade700,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FacturacionPage(highlightOrderId: ot.id),
                    ),
                  ),
                ),
              ),
            ],
          ),
        if (ot.estado == 'FACTURADA')
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'VER DETALLE',
                  Icons.visibility_outlined,
                  const Color.fromARGB(255, 57, 146, 173),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrdenDetallePage(orden: ot),
                    ),
                  ),
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  ot.facTipoComprobante == 'F' ? 'VER FACTURA' : 'VER BOLETA',
                  Icons.picture_as_pdf,
                  Colors.green.shade700,
                  () {
                    if (ot.facId != null) {
                      _verComprobante(ot.facId!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ID de comprobante no disponible'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _eliminarItem(OrdenTrabajo orden, OrdenItem item) async {
    final confirm = await _showConfirmDialog(
      'Eliminar Item',
      '¿Deseas eliminar "${item.itemNombre}" de esta orden?',
    );

    if (confirm) {
      // Check if item has an ID
      if (item.id == null) {
        _showError('Error: El item no tiene un ID válido');
        return;
      }

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await _repository.eliminarItemDesdeOrden(
        orden.id!,
        item.id!,
      );

      if (mounted) Navigator.pop(context);

      if (success) {
        // Optimistic Update
        final newTotal = orden.total - item.total;
        final updatedItems = List<OrdenItem>.from(orden.items)
          ..removeWhere((i) => i.id == item.id);

        final updatedOrden = orden.copyWith(
          total: newTotal,
          items: updatedItems,
        );

        _updateLocalOrder(updatedOrden);
        _showSuccessSnackBar('Item eliminado correctamente');
      } else {
        _showError('No se pudo eliminar el item');
      }
    }
  }

  Future<void> _editarItem(OrdenTrabajo orden, OrdenItem item) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => ItemEditorDialog(
        initialNombre: item.itemNombre,
        initialCantidad: item.cantidad,
        initialPrecio: item.precioUnitario,
        initialAfectoIgv: item.afectoIgv,
      ),
    );

    if (result != null) {
      final newNombre = result['nombre'] as String;
      final newCant = result['cantidad'] as double;
      final newPrecio = result['precio'] as double;
      final newAfectoIgv = result['afectoIgv'] as int;
      final selectedTributo = result['codigoTributo'] as String;

      if (newNombre.isEmpty || newCant <= 0 || newPrecio < 0) {
        _showError('Valores inválidos');
        return;
      }

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      String? targetItemId = item.itemId;
      String? targetItemNombre = item.itemNombre;

      // Logic: If name changed, check if exists, else create
      if (newNombre != item.itemNombre) {
        try {
          final allItems = await _repository.getItems(orden.empId);

          final existingItem = allItems.firstWhere(
            (i) => i.nombre.toLowerCase() == newNombre.toLowerCase(),
            orElse: () => Item(
              id: '0',
              empId: orden.empId,
              nombre: '',
              descripcion: '',
              tipo: 'SERVICIO',
              precio: 0.0,
              codigoTributo: '10',
              estado: 'ACTIVO',
            ),
          );

          if (existingItem.id != '0') {
            targetItemId = existingItem.id;
            targetItemNombre = existingItem.nombre;
          } else {
            final newItem = Item(
              id: '0',
              empId: orden.empId,
              nombre: newNombre,
              descripcion: newNombre,
              tipo: 'SERVICIO',
              precio: newPrecio,
              codigoTributo: selectedTributo,
              estado: 'ACTIVO',
            );

            final createdId = await _repository.saveItem(newItem);
            if (createdId != null) {
              targetItemId = createdId;
              targetItemNombre = newNombre;
            } else {
              throw Exception('Error al crear nuevo item');
            }
          }
        } catch (e) {
          if (mounted) Navigator.pop(context);
          _showError('Error procesando item: $e');
          return;
        }
      }

      final success = await _repository.actualizarItemOrden(
        orden.id!,
        item.id!,
        targetItemId!,
        newCant,
        newPrecio,
        newAfectoIgv,
      );

      // Re-map afectoIgv if it changed, but actualizarItemOrden takes the NEW values already?
      // Wait, the call above passes item.afectoIgv (OLD VALUE). We need to pass newAfectoIgv.
      // Retry correcting the call above.

      if (mounted) Navigator.pop(context);

      if (success) {
        // Optimistic Update
        final newIgvValue = (newAfectoIgv == 1)
            ? (newCant * newPrecio * 0.18)
            : 0.0;
        final newSubtotal = newCant * newPrecio;
        final newTotalItem = newSubtotal + newIgvValue;

        // Check if we are merging into an existing item (excluding the one we are editing)
        final collisionIndex = orden.items.indexWhere(
          (i) => i.itemId == targetItemId && i.id != item.id,
        );

        List<OrdenItem> updatedItems;
        final double diffTotal;

        if (collisionIndex != -1) {
          // COLLISION DETECTED: Merge
          final collisionsItem = orden.items[collisionIndex];

          final mergedCant = collisionsItem.cantidad + newCant;
          final mergedSubtotal = mergedCant * newPrecio;
          final mergedIgvVal = (newAfectoIgv == 1)
              ? mergedSubtotal * 0.18
              : 0.0;
          final mergedTotal = mergedSubtotal + mergedIgvVal;

          final mergedItem = collisionsItem.copyWith(
            cantidad: mergedCant,
            precioUnitario: newPrecio,
            subtotal: mergedSubtotal,
            igv: mergedIgvVal,
            total: mergedTotal,
            afectoIgv: newAfectoIgv,
          );

          updatedItems = List<OrdenItem>.from(orden.items);
          updatedItems[collisionIndex] = mergedItem;
          updatedItems.removeWhere((i) => i.id == item.id);

          // Diff = NewMergedTotal - (OldItemTotal + OldCollisionTotal)
          diffTotal = mergedTotal - (item.total + collisionsItem.total);
        } else {
          // No collision, just update
          final diff = newTotalItem - item.total;
          diffTotal = diff;

          final updatedItem = item.copyWith(
            itemId: targetItemId,
            itemNombre: targetItemNombre,
            cantidad: newCant,
            precioUnitario: newPrecio,
            total: newTotalItem,
            igv: newIgvValue,
            subtotal: newSubtotal,
            afectoIgv: newAfectoIgv,
          );

          updatedItems = orden.items
              .map((i) => i.id == item.id ? updatedItem : i)
              .toList();
        }

        final newTotalOrden = orden.total + diffTotal;

        final updatedOrden = orden.copyWith(
          total: newTotalOrden,
          items: updatedItems,
        );

        _updateLocalOrder(updatedOrden);
        _showSuccessSnackBar('Item actualizado correctamente');
      } else {
        _showError('No se pudo actualizar el item');
      }
    }
  }

  void _updateLocalOrder(OrdenTrabajo updatedOrden) {
    final index = _ordenes.indexWhere((o) => o.id == updatedOrden.id);
    if (index != -1) {
      setState(() {
        _ordenes[index] = updatedOrden;
        // Highlight logic could go here if needed
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
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
        return Theme.of(context).colorScheme.primary;
      case 'FINALIZADA':
        return Colors.orange;
      case 'FACTURADA':
        return Colors.green;
      default:
        return Colors.black;
    }
  }
}
