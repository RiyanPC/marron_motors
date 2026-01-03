import 'orden.dart';

class DashboardStats {
  final int ordenesActivas;
  final int clientesNuevosMes;
  final double gananciasMes;
  final List<OrdenTrabajo> ordenesRecientes;

  DashboardStats({
    required this.ordenesActivas,
    required this.clientesNuevosMes,
    required this.gananciasMes,
    required this.ordenesRecientes,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final kpis = json['kpis'];
    return DashboardStats(
      ordenesActivas: int.parse(kpis['ordenes_activas'].toString()),
      clientesNuevosMes: int.parse(kpis['clientes_nuevos_mes'].toString()),
      gananciasMes: double.parse(kpis['ganancias_mes'].toString()),
      ordenesRecientes: (json['ordenes_recientes'] as List)
          .map((e) => OrdenTrabajo.fromJson(e))
          .toList(),
    );
  }
}
