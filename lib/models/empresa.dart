class Empresa {
  final String id;
  final String nombre;
  final String ruc;
  final String direccion;
  final String ubigeo;
  final String tokenNubefact;
  final String estado;

  Empresa({
    required this.id,
    required this.nombre,
    required this.ruc,
    required this.direccion,
    required this.ubigeo,
    required this.tokenNubefact,
    required this.estado,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['emp_id'].toString(),
      nombre: json['emp_nombre'] ?? '',
      ruc: json['emp_ruc'] ?? '',
      direccion: json['emp_direccion'] ?? '',
      ubigeo: json['emp_ubigeo'] ?? '',
      tokenNubefact: json['emp_token_nubefact'] ?? '',
      estado: json['emp_estado'] ?? 'ACTIVO',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emp_id': id,
      'emp_nombre': nombre,
      'emp_ruc': ruc,
      'emp_direccion': direccion,
      'emp_ubigeo': ubigeo,
      'emp_token_nubefact': tokenNubefact,
      'emp_estado': estado,
    };
  }
}
