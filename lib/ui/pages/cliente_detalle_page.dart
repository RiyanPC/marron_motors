import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/cliente.dart';

class ClienteDetallePage extends StatelessWidget {
  final Cliente cliente;

  const ClienteDetallePage({super.key, required this.cliente});

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Cliente'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildInfoCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              cliente.nombre.isNotEmpty ? cliente.nombre[0].toUpperCase() : 'C',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            cliente.nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: cliente.estado == 'ACTIVO'
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              cliente.estado,
              style: TextStyle(
                color: cliente.estado == 'ACTIVO'
                    ? Colors.green.shade800
                    : Colors.red.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.badge_outlined,
              'Documento',
              '${cliente.tipoDocumento}: ${cliente.numeroDocumento}',
            ),
            const Divider(),
            _buildInfoRow(
              Icons.phone_android_rounded,
              'Teléfono',
              cliente.telefono,
              onAction: () => _makeCall(cliente.telefono),
              actionIcon: Icons.call,
            ),
            const Divider(),
            _buildInfoRow(
              Icons.email_outlined,
              'Email',
              cliente.email.isEmpty ? 'No registrado' : cliente.email,
            ),
            const Divider(),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Dirección',
              cliente.direccion.isEmpty ? 'No registrada' : cliente.direccion,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onAction,
    IconData? actionIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onAction != null && value.isNotEmpty)
            IconButton(
              icon: Icon(
                actionIcon ?? Icons.chevron_right,
                color: Colors.green,
              ),
              onPressed: onAction,
            ),
        ],
      ),
    );
  }
}
