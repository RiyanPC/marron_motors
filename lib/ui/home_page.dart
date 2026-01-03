import 'package:flutter/material.dart';
import 'pages/clientes_page.dart';
import 'pages/vehiculos_page.dart';
import 'pages/items_page.dart';
import 'pages/ordenes_page.dart';
import 'pages/facturacion_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/configuracion_page.dart';
import 'widgets/app_drawer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marron Motors'), centerTitle: true),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMenuCard(
              context,
              'Dashboard',
              Icons.dashboard_rounded,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DashboardPage()),
              ),
            ),
            _buildMenuCard(
              context,
              'Clientes',
              Icons.people_alt_rounded,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClientesPage()),
              ),
            ),
            _buildMenuCard(
              context,
              'Vehículos',
              Icons.directions_car_rounded,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehiculosPage()),
              ),
            ),
            _buildMenuCard(
              context,
              'Órdenes',
              Icons.home_repair_service_rounded,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdenesPage()),
              ),
            ),
            _buildMenuCard(
              context,
              'Servicios/Items',
              Icons.inventory_2_rounded,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ItemsPage()),
              ),
            ),
            _buildMenuCard(
              context,
              'Facturación',
              Icons.receipt_long_rounded,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FacturacionPage()),
              ),
            ),
            _buildMenuCard(
              context,
              'Configuración',
              Icons.settings_suggest_rounded,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfiguracionPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade50.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: const Color(0xFF0D47A1)),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
