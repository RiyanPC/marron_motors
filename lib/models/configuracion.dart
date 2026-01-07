class Configuracion {
  final int id;
  final String nombreTaller;
  final String ruc;
  final String direccion;
  final String telefono;
  final double igvPorcentaje;
  final String? ubigeo;
  final String? departamento;
  final String? provincia;
  final String? distrito;
  final String? logoUrl;

  Configuracion({
    required this.id,
    required this.nombreTaller,
    required this.ruc,
    required this.direccion,
    required this.telefono,
    required this.igvPorcentaje,
    this.ubigeo,
    this.departamento,
    this.provincia,
    this.distrito,
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
      ubigeo: json['ubigeo'],
      departamento: json['departamento'],
      provincia: json['provincia'],
      distrito: json['distrito'],
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
      'ubigeo': ubigeo,
      'departamento': departamento,
      'provincia': provincia,
      'distrito': distrito,
      'logo_url': logoUrl,
    };
  }
}
