import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Estadísticas y Reportes',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
          ? const Center(child: Text('No hay datos disponibles'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader('RESUMEN DE KPI'),
                  const SizedBox(height: 12),
                  _buildKpiSection(),
                  const SizedBox(height: 32),
                  _buildHeader('DISTRIBUCIÓN DE ÓRDENES (RECIENTES)'),
                  const SizedBox(height: 12),
                  _buildPieChartCard(),
                  const SizedBox(height: 32),
                  _buildHeader('META DE INGRESOS MENSUAL'),
                  const SizedBox(height: 12),
                  _buildBarChartCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildKpiSection() {
    return Column(
      children: [
        _buildKpiCard(
          'Órdenes Activas',
          _stats!.ordenesActivas.toString(),
          Icons.engineering,
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildKpiCard(
          'Clientes Nuevos (Mes)',
          _stats!.clientesNuevosMes.toString(),
          Icons.person_add,
          Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        _buildKpiCard(
          'Ganancias (Mes)',
          'S/ ${_stats!.gananciasMes.toStringAsFixed(2)}',
          Icons.payments,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard() {
    // Calculate distribution from recent orders
    int abiertas = 0;
    int enProceso = 0;
    int finalizadas = 0;

    for (var orden in _stats!.ordenesRecientes) {
      if (orden.estado == 'ABIERTA')
        abiertas++;
      else if (orden.estado == 'EN_PROCESO' || orden.estado == 'En Proceso')
        enProceso++;
      else if ([
        'FINALIZADA',
        'FACTURADA',
        'ENTREGADO',
      ].contains(orden.estado.toUpperCase()))
        finalizadas++;
    }

    // Handle empty data case to avoid empty chart
    if (_stats!.ordenesRecientes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("No hay datos recientes para graficar"),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: Colors.grey,
                  value: abiertas.toDouble(),
                  title: '$abiertas',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Theme.of(context).colorScheme.primary,
                  value: enProceso.toDouble(),
                  title: '$enProceso',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.green,
                  value: finalizadas.toDouble(),
                  title: '$finalizadas',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Colors.grey, 'Abiertas'),
            const SizedBox(width: 16),
            _buildLegendItem(
              Theme.of(context).colorScheme.primary,
              'En Proceso',
            ),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.green, 'Finalizadas'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChartCard() {
    final history = _stats!.earningsHistory;
    if (history.isEmpty)
      return const Center(child: Text("No hay datos de ingresos."));

    double maxEarning = 0;
    for (var h in history) {
      if (h.amount > maxEarning) maxEarning = h.amount;
    }
    final double maxY = maxEarning * 1.2;

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  'S/ ${rod.toY.toStringAsFixed(0)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= history.length)
                    return const SizedBox.shrink();

                  return SideTitleWidget(
                    meta: meta,
                    space: 4,
                    child: Text(
                      history[index].month,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ), // Hide Y axis numbers to keep it clean
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          barGroups: history.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.amount,
                  color: index == history.length - 1
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.grey.withOpacity(0.1),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
