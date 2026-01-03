import 'package:flutter/material.dart';
import '../pages/clientes_page.dart';
import '../pages/vehiculos_page.dart';
import '../pages/items_page.dart';
import '../pages/ordenes_page.dart';
import '../pages/facturacion_page.dart';
import '../pages/configuracion_page.dart';
import '../pages/dashboard_page.dart';
import '../home_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade900),
            accountName: const Text(
              'Marron Motors',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text('Taller Mecánico'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.engineering,
                size: 40,
                color: Color(0xFF0D47A1),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(context, Icons.dashboard, 'Dashboard', () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardPage()),
                  );
                }),
                _drawerItem(context, Icons.people, 'Clientes', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClientesPage()),
                  );
                }),
                _drawerItem(context, Icons.directions_car, 'Vehículos', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VehiculosPage()),
                  );
                }),
                _drawerItem(context, Icons.build, 'Órdenes / Taller', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdenesPage()),
                  );
                }),
                _drawerItem(context, Icons.inventory, 'Servicios / Items', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ItemsPage()),
                  );
                }),
                _drawerItem(context, Icons.receipt_long, 'Facturación', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FacturacionPage()),
                  );
                }),
                const Divider(),
                _drawerItem(context, Icons.grid_view, 'Menú Principal', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                }),
                _drawerItem(context, Icons.settings, 'Configuración', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConfiguracionPage(),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade900),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
