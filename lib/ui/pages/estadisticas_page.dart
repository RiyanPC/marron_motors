import 'package:flutter/material.dart';
import '../../services/data_repository.dart';
import '../../models/dashboard_stats.dart';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key});

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  final DataRepository _repository = DataRepository();
  bool _isLoading = true;
  DashboardStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _repository.getDashboardStats();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas y Reportes')),
      // No drawer here, assuming back button navigation from Home
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
          ? const Center(child: Text('No hay datos disponibles'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildKpiCard(
                    'Órdenes Activas',
                    _stats!.ordenesActivas.toString(),
                    Icons.engineering,
                    Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  _buildKpiCard(
                    'Clientes Nuevos (Mes)',
                    _stats!.clientesNuevosMes.toString(),
                    Icons.person_add,
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildKpiCard(
                    'Ganancias (Mes)',
                    'S/ ${_stats!.gananciasMes.toStringAsFixed(2)}',
                    Icons.payments,
                    Colors.green,
                  ),
                  // Add more charts or details here in the future
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(title),
      ),
    );
  }
}
