import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';

class VehiculoDetallePage extends StatelessWidget {
  final Vehiculo vehiculo;

  const VehiculoDetallePage({super.key, required this.vehiculo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Vehículo'), elevation: 0),
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
          vehiculo.foto.isNotEmpty
              ? Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(vehiculo.foto),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(
                    Icons.directions_car_rounded,
                    size: 48,
                    color: Colors.orange,
                  ),
                ),
          const SizedBox(height: 16),
          Text(
            vehiculo.placa,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${vehiculo.marca} ${vehiculo.modelo}',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
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
              Icons.person_outline,
              'Propietario',
              vehiculo.cliNombre,
            ),
            const Divider(),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Año',
              vehiculo.anio.isEmpty ? 'No registrado' : vehiculo.anio,
            ),
            const Divider(),
            _buildInfoRow(
              Icons.palette_outlined,
              'Color',
              vehiculo.color.isEmpty ? 'No registrado' : vehiculo.color,
            ),
            const Divider(),
            _buildInfoRow(
              Icons.fingerprint_rounded,
              'VIN / Motor',
              vehiculo.vin.isEmpty ? 'No registrado' : vehiculo.vin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange, size: 24),
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
        ],
      ),
    );
  }
}
