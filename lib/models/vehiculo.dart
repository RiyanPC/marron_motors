import '../core/api_config.dart';

class Vehiculo {
  final String id;
  final String cliId;
  final String empId;
  final String placa;
  final String marca;
  final String modelo;
  final String anio;
  final String color;
  final String vin;
  final String tipo;
  final String foto;
  final String cliNombre;

  Vehiculo({
    required this.id,
    required this.cliId,
    required this.empId,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.color,
    required this.vin,
    this.tipo = '',
    this.foto = '',
    this.cliNombre = '',
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: json['veh_id'].toString(),
      cliId: json['veh_cli_id'].toString(),
      empId: json['veh_emp_id'].toString(),
      placa: json['veh_placa'] ?? '',
      marca: json['veh_marca'] ?? '',
      modelo: json['veh_modelo'] ?? '',
      anio: json['veh_anio']?.toString() ?? '',
      color: json['veh_color'] ?? '',
      vin: json['veh_vin'] ?? '',
      tipo: json['veh_tipo'] ?? '',
      foto: _fixUrl(json['veh_foto'] ?? ''),
      cliNombre: json['cli_nombre'] ?? '',
    );
  }

  static String _fixUrl(String url) {
    if (url.isEmpty) return url;
    if (url.contains('192.168.') || url.contains('localhost')) {
      if (url.contains('/uploads/')) {
        final path = url.split('/uploads/').last;
        return '${ApiConfig.baseUrl}/uploads/$path';
      }
    }
    return url;
  }

  Map<String, dynamic> toJson() {
    return {
      'veh_id': id,
      'veh_cli_id': cliId,
      'veh_emp_id': empId,
      'veh_placa': placa,
      'veh_marca': marca,
      'veh_modelo': modelo,
      'veh_anio': anio,
      'veh_color': color,
      'veh_vin': vin,
      'veh_tipo': tipo,
      'veh_foto': foto,
    };
  }
}
