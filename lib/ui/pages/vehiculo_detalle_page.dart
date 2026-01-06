import 'package:flutter/material.dart';
import '../../models/vehiculo.dart';

class VehiculoDetallePage extends StatelessWidget {
  final Vehiculo vehiculo;

  const VehiculoDetallePage({super.key, required this.vehiculo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Detalle del Vehículo'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    context,
                    Icons.info_outline,
                    'ESPECIFICACIONES TÉCNICAS',
                  ),
                  _buildInfoCard(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    Icons.history,
                    'HISTORIAL RECIENTE',
                  ),
                  _buildEmptyHistory(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          vehiculo.foto.isNotEmpty
              ? Container(
                  height: 180,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(vehiculo.foto),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    size: 70,
                    color: Colors.white,
                  ),
                ),
          const SizedBox(height: 20),
          Text(
            vehiculo.placa,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
          Text(
            '${vehiculo.marca} ${vehiculo.modelo}',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(
              context,
              Icons.person_pin_outlined,
              'Propietario Registrado',
              vehiculo.cliNombre,
            ),
            const Divider(),
            _buildInfoRow(
              context,
              Icons.calendar_month_outlined,
              'Año de Fabricación',
              vehiculo.anio.isEmpty ? 'No especificado' : vehiculo.anio,
            ),
            const Divider(),
            _buildInfoRow(
              context,
              Icons.palette_outlined,
              'Color de la Unidad',
              vehiculo.color.isEmpty ? 'No especificado' : vehiculo.color,
            ),
            const Divider(),
            _buildInfoRow(
              context,
              Icons.fingerprint_rounded,
              'Número de VIN / Chasis',
              vehiculo.vin.isEmpty ? 'No especificado' : vehiculo.vin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        ),
      ),
      child: const Column(
        children: [
          Icon(Icons.history_toggle_off, color: Colors.blueGrey, size: 32),
          SizedBox(height: 12),
          Text(
            'No hay órdenes de servicio registradas recientemente para este vehículo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
