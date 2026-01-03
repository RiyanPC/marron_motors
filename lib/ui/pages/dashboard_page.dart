import 'package:flutter/material.dart';
import '../../services/data_repository.dart';
import '../../models/dashboard_stats.dart';
import 'orden_nueva_page.dart';
import 'orden_detalle_page.dart';
import 'clientes_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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
      appBar: AppBar(
        title: const Text('Panel de Control'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: _isLoading
            ? const Center(
                child: CircularProgress(),
              ) // Placeholder for your theme loader
            : _stats == null
            ? const Center(child: Text('Error al cargar estadísticas'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen del Mes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildKpiGrid(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Actividad Reciente',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navegar a órdenes
                          },
                          child: const Text('Ver todas'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildRecentOrders(),
                    const SizedBox(height: 24),
                    Text(
                      'Acciones Rápidas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildKpiGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildKpiCard(
          title: 'Órdenes Activas',
          value: _stats!.ordenesActivas.toString(),
          icon: Icons.engineering,
          color: Colors.orange,
        ),
        _buildKpiCard(
          title: 'Clientes Nuevos',
          value: _stats!.clientesNuevosMes.toString(),
          icon: Icons.person_add,
          color: Colors.blue,
        ),
        _buildKpiCard(
          title: 'Ganancias Mes',
          value: 'S/ ${_stats!.gananciasMes.toStringAsFixed(2)}',
          icon: Icons.payments,
          color: Colors.green,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    if (_stats!.ordenesRecientes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No hay órdenes recientes'),
        ),
      );
    }

    return Column(
      children: _stats!.ordenesRecientes.map((orden) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(orden.estado),
              child: const Icon(
                Icons.car_repair,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text('${orden.vehPlaca} - ${orden.cliNombre}'),
            subtitle: Text(orden.estado),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrdenDetallePage(orden: orden),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          label: 'Nueva Orden',
          icon: Icons.add_circle_outline,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdenNuevaPage()),
            );
          },
        ),
        _buildActionButton(
          label: 'Ver Clientes',
          icon: Icons.people_outline,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientesPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'En Proceso':
        return Colors.orange;
      case 'Finalizado':
        return Colors.blue;
      case 'Entregado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class CircularProgress extends StatelessWidget {
  const CircularProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator();
  }
}
