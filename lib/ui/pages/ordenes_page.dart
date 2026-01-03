import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/orden.dart';
import '../../services/data_repository.dart';
import '../../core/api_config.dart';
import 'comprobante_preview_page.dart';
import 'orden_nueva_page.dart';
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
    if (orden.items.isEmpty) {
      _showError(
        'No se puede emitir un comprobante sin ítems de trabajo. Por favor, añada servicios o repuestos primero.',
      );
      return;
    }

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

  Future<void> _eliminarItem(OrdenTrabajo orden, OrdenItem item) async {
    final confirm = await _showConfirmDialog(
      'Eliminar Item',
      '¿Deseas eliminar "${item.itemNombre}" de esta orden?',
    );

    if (confirm) {
      setState(() => _loading = true);
      final success = await _repository.eliminarItemDesdeOrden(
        orden.id!,
        item.id!,
      );
      if (success) {
        await _loadOrdenes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item eliminado correctamente')),
        );
      } else {
        setState(() => _loading = false);
        _showError('No se pudo eliminar el item');
      }
    }
  }

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
        folder: 'ordenes',
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
                color: Colors.blue.shade900,
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
                  backgroundColor: Colors.blue.shade900,
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
              backgroundColor: Colors.blue.shade900,
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'ABIERTAS', icon: Icon(Icons.door_front_door_outlined)),
            Tab(text: 'EN PROCESO', icon: Icon(Icons.build_circle_outlined)),
            Tab(text: 'FINALIZADAS', icon: Icon(Icons.task_alt_rounded)),
            Tab(text: 'FACTURADAS', icon: Icon(Icons.receipt_long_rounded)),
          ],
        ),
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
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
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
                    if (ot.foto != null && ot.foto!.isNotEmpty) ...[
                      const Divider(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          ot.foto!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Imagen referencial para identificar la orden',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Conditional Warning for Empty Finalized Orders
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
                          'Añade trabajos antes de emitir comprobante',
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
        Icon(icon, size: 16, color: Colors.blue.shade700),
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
            'ORDEN COMPLETADA Y FACTURADA',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ot.estado == 'ABIERTA')
          _buildActionButton(
            'INICIAR TRABAJO',
            Icons.play_arrow_rounded,
            Colors.blue.shade800,
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
                      Colors.blue.shade700,
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
                          '¿Confirmas que deseas pasar esta orden a estado "Finalizada"?',
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
        if (ot.estado == 'FINALIZADA') ...[
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'BOLETA',
                  Icons.receipt_outlined,
                  Colors.blueGrey.shade700,
                  () => _emitirFactura(ot, 'BOLETA'),
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  'FACTURAR',
                  Icons.description_rounded,
                  Colors.blue.shade900,
                  () => _emitirFactura(ot, 'FACTURA'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            'AÑADIR TRABAJO',
            Icons.add_circle_outline,
            Colors.blue.shade700,
            () => _agregarTrabajo(ot),
            isOutlined: true,
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
