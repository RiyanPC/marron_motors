class Configuracion {
  final int id;
  final String nombreTaller;
  final String ruc;
  final String direccion;
  final String telefono;
  final double igvPorcentaje;
  final String? logoUrl;

  Configuracion({
    required this.id,
    required this.nombreTaller,
    required this.ruc,
    required this.direccion,
    required this.telefono,
    required this.igvPorcentaje,
    this.logoUrl,
  });

  factory Configuracion.fromJson(Map<String, dynamic> json) {
    return Configuracion(
      id: int.parse(json['id'].toString()),
      nombreTaller: json['nombre_taller'] ?? '',
      ruc: json['ruc'] ?? '',
      direccion: json['direccion'] ?? '',
      telefono: json['telefono'] ?? '',
      igvPorcentaje: double.parse(json['igv_porcentaje'].toString()),
      logoUrl: json['logo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_taller': nombreTaller,
      'ruc': ruc,
      'direccion': direccion,
      'telefono': telefono,
      'igv_porcentaje': igvPorcentaje,
      'logo_url': logoUrl,
    };
  }
}
