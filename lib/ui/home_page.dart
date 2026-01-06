import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/data_repository.dart';
import '../models/dashboard_stats.dart';
import 'widgets/app_drawer.dart';
import 'pages/clientes_page.dart';
import 'pages/vehiculos_page.dart';
import 'pages/items_page.dart';
import 'pages/ordenes_page.dart';
import 'pages/facturacion_page.dart';
import 'pages/configuracion_page.dart';
import 'pages/orden_nueva_page.dart';
import 'pages/orden_detalle_page.dart';
import 'pages/estadisticas_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DataRepository _repository = DataRepository();
  bool _isLoading = true;
  DashboardStats? _stats;
  bool _showDrawer = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Cargar preferencia del drawer
    final prefs = await SharedPreferences.getInstance();
    final showDrawer = prefs.getBool('show_drawer') ?? false;

    // Cargar estadísticas
    final stats = await _repository.getDashboardStats();

    setState(() {
      _showDrawer = showDrawer;
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marron Motors'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfiguracionPage()),
              );
              _loadData(); // Recargar preferencias al volver
            },
            tooltip: 'Configuración',
          ),
        ],
      ),
      drawer: _showDrawer ? const AppDrawer() : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _stats == null
                  ? const Center(child: Text('Error al cargar datos'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeSection(),
                          const SizedBox(height: 24),
                          _buildKpiGrid(),
                          const SizedBox(height: 32),
                          Text(
                            'Acciones Rápidas',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildQuickActions(context),
                          const SizedBox(height: 32),
                          Text(
                            'Gestión',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildManagementGrid(context),
                          const SizedBox(height: 32),
                          if (_stats!.ordenesRecientes.isNotEmpty) ...[
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const OrdenesPage(),
                                      ),
                                    );
                                  },
                                  child: const Text('Ver todas'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildRecentOrders(),
                          ],
                        ],
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrdenNuevaPage()),
          );
        },
        label: const Text('Nueva Orden'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, Bienvenido',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const Text(
          'Panel General',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Activas',
                value: _stats!.ordenesActivas.toString(),
                icon: Icons.engineering,
                color: Colors.orange,
                small: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'Ganancias',
                value:
                    'S/ ${_stats!.gananciasMes.toStringAsFixed(0)}', // Truncate decimals for space
                icon: Icons.payments,
                color: Colors.green,
                small: true,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.grey.shade100,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
                color: Colors.grey.shade700,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EstadisticasPage()),
                  );
                },
                tooltip: 'Ver Estadísticas',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool small = false,
  }) {
    return Container(
      padding: EdgeInsets.all(small ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: small ? 20 : 24),
              ),
              if (!small) ...[
                const SizedBox(width: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (small)
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          Text(
            title,
            style: TextStyle(
              fontSize: small ? 12 : 14,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            'Órdenes',
            Icons.home_repair_service,
            Colors.indigo.shade600,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdenesPage()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            'Facturación',
            Icons.receipt_long,
            Colors.teal.shade600,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FacturacionPage()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManagementGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _buildMiniCard(
          context,
          'Clientes',
          Icons.people,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClientesPage()),
          ),
        ),
        _buildMiniCard(
          context,
          'Vehículos',
          Icons.directions_car,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VehiculosPage()),
          ),
        ),
        _buildMiniCard(
          context,
          'Servicios',
          Icons.inventory_2,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ItemsPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey[700], size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Column(
      children: _stats!.ordenesRecientes.map((orden) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(orden.estado).withOpacity(0.1),
              child: Icon(
                Icons.car_repair,
                color: _getStatusColor(orden.estado),
                size: 20,
              ),
            ),
            title: Text(
              '${orden.vehPlaca} - ${orden.cliNombre}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              orden.estado,
              style: TextStyle(
                color: _getStatusColor(orden.estado),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.grey,
            ),
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

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'En Proceso':
        return Colors.orange;
      case 'Finalizado':
        return const Color(0xFF0D47A1);
      case 'Entregado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
