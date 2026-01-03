import 'package:flutter/material.dart';
import '../../models/orden.dart';

class OrdenDetallePage extends StatelessWidget {
  final OrdenTrabajo orden;

  const OrdenDetallePage({super.key, required this.orden});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Orden #${orden.id}'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 16),
            _buildSection(
              title: 'DATOS DEL CLIENTE',
              icon: Icons.person_rounded,
              child: Column(
                children: [
                  _buildDetailedRow('Nombre', orden.cliNombre ?? 'No asignado'),
                  _buildDetailedRow('Documento', orden.cliDocumento ?? 'N/A'),
                  _buildDetailedRow('Teléfonos', orden.cliTelefono ?? 'N/A'),
                  _buildDetailedRow('Email', orden.cliEmail ?? 'N/A'),
                  _buildDetailedRow('Dirección', orden.cliDireccion ?? 'N/A'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'DATOS DEL VEHÍCULO',
              icon: Icons.directions_car_filled_rounded,
              child: Column(
                children: [
                  _buildDetailedRow(
                    'Placa',
                    orden.vehPlaca ?? 'S/P',
                    isBold: true,
                  ),
                  _buildDetailedRow(
                    'Marca/Modelo',
                    '${orden.vehMarca ?? ''} ${orden.vehModelo ?? ''}',
                  ),
                  _buildDetailedRow('Año', orden.vehAnio?.toString() ?? 'N/A'),
                  _buildDetailedRow('VIN / Chasis', orden.vehVin ?? 'N/A'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'SERVICIO SOLICITADO',
              icon: Icons.description_rounded,
              child: Text(
                orden.descripcion,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'DETALLE DE TRABAJOS',
              icon: Icons.list_alt_rounded,
              child: _buildItemsList(),
            ),
            if (orden.foto != null && orden.foto!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSection(
                title: 'EVIDENCIA FOTOGRÁFICA',
                icon: Icons.camera_alt_rounded,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        orden.foto!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Imagen referencial capturada durante el proceso.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ESTADO ACTUAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                orden.estado,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _getStatusColor(orden.estado),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'FECHA DE INGRESO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                orden.fechaIngreso,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue.shade900),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D47A1),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailedRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (orden.items.isEmpty) {
      return const Text(
        'No se han registrado trabajos ni repuestos.',
        style: TextStyle(fontSize: 13, color: Colors.grey),
      );
    }

    return Column(
      children: [
        ...orden.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.itemNombre ?? 'Sin nombre',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  'x${item.cantidad.toInt()}  S/ ${item.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'TOTAL ORDEN: ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              'S/ ${orden.total.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: const Color(0xFF0D47A1),
              ),
            ),
          ],
        ),
      ],
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
