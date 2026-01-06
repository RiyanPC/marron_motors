import 'orden.dart';

class DashboardStats {
  final int ordenesActivas;
  final int clientesNuevosMes;
  final double gananciasMes;
  final List<MonthlyEarning> earningsHistory;
  final List<OrdenTrabajo> ordenesRecientes;

  DashboardStats({
    required this.ordenesActivas,
    required this.clientesNuevosMes,
    required this.gananciasMes,
    required this.earningsHistory,
    required this.ordenesRecientes,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final kpis = json['kpis'];
    var historyList = <MonthlyEarning>[];
    if (kpis['ganancias_historial'] != null) {
      historyList = (kpis['ganancias_historial'] as List)
          .map((e) => MonthlyEarning.fromJson(e))
          .toList();
    }

    return DashboardStats(
      ordenesActivas: int.parse(kpis['ordenes_activas'].toString()),
      clientesNuevosMes: int.parse(kpis['clientes_nuevos_mes'].toString()),
      gananciasMes: double.parse(kpis['ganancias_mes'].toString()),
      earningsHistory: historyList,
      ordenesRecientes: (json['ordenes_recientes'] as List)
          .map((e) => OrdenTrabajo.fromJson(e))
          .toList(),
    );
  }
}

class MonthlyEarning {
  final String month;
  final double amount;

  MonthlyEarning({required this.month, required this.amount});

  factory MonthlyEarning.fromJson(Map<String, dynamic> json) {
    return MonthlyEarning(
      month: json['mes'].toString(),
      amount: double.parse(json['total'].toString()),
    );
  }
}
