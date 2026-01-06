import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/orden.dart';
import '../../services/data_repository.dart';
import 'orden_nueva_page.dart';
import 'orden_detalle_page.dart';
import '../widgets/item_selector_modal.dart';

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
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      });
      _loadOrdenes();
    }
  }

  void _limpiarFiltro() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
    });
    _loadOrdenes();
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
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
      setState(() => _loading = true);
      final success = await _repository.agregarItemsAOrden(orden.id!, [result]);
      if (success) {
        await _loadOrdenes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trabajo/Repuesto añadido con éxito')),
        );
      } else {
        setState(() => _loading = false);
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
          _loadOrdenes();
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
                color: const Color(0xFF0D47A1),
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
                  backgroundColor: const Color(0xFF0D47A1),
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

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Aviso',
          style: TextStyle(
            color: Colors.blue.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
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
        title: const Text('Gestión de Órdenes'),
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
        backgroundColor: const Color(0xFF0D47A1),
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
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton(
              label: '7 días',
              icon: Icons.date_range,
              onTap: () => _aplicarFiltroRapido('7dias'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton(
              label: 'Mes',
              icon: Icons.calendar_month,
              onTap: () => _aplicarFiltroRapido('mes'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton(
              label: 'Especificar',
              icon: Icons.edit_calendar,
              onTap: _mostrarFiltroFechas,
              isOutlined: true,
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
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0D47A1),
          side: const BorderSide(color: Color(0xFF0D47A1), width: 1.5),
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
        backgroundColor: const Color(0xFF0D47A1),
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
                      Icons.directions_car_filled_outlined,
                      'VEHÍCULO',
                      ot.vehPlaca ?? 'S/P',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.build_circle_outlined,
                      'SERVICIO SOLICITADO',
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
                              color: const Color(0xFF0D47A1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Removed Warning for Empty Finalized Orders as it's handled in FacturacionPage
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
        Icon(icon, size: 16, color: const Color(0xFF0D47A1)),
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
          _buildActionButton(
            'INICIAR TRABAJO',
            Icons.play_arrow_rounded,
            const Color(0xFF0D47A1),
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
        if (ot.estado == 'FINALIZADA' || ot.estado == 'FACTURADA')
          _buildActionButton(
            'VER DETALLE',
            Icons.visibility_outlined,
            const Color.fromARGB(255, 57, 146, 173),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrdenDetallePage(orden: ot)),
            ),
          ),
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
        return const Color(0xFF0D47A1);
      case 'FINALIZADA':
        return Colors.orange;
      case 'FACTURADA':
        return Colors.green;
      default:
        return Colors.black;
    }
  }
}
