import 'package:flutter/material.dart';
import 'pages/clientes_page.dart';
import 'pages/vehiculos_page.dart';
import 'pages/items_page.dart';
import 'pages/orden_nueva_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marron Motors'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMenuCard(
              context,
              'Clientes',
              Icons.people_alt_rounded,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClientesPage()),
              ),
            ),
            _buildMenuCard(
              context,
              'Vehículos',
              Icons.directions_car_rounded,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehiculosPage()),
              ),
            ),
            _buildMenuCard(
              context,
              'Servicios/Items',
              Icons.inventory_2_rounded,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ItemsPage()),
              ),
            ),
            _buildMenuCard(
              context,
              'Nueva Orden',
              Icons.add_task_rounded,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdenNuevaPage()),
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
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
