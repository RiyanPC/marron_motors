class Cliente {
  final String id;
  final String empId;
  final String nombre;
  final String tipoDocumento;
  final String numeroDocumento;
  final String telefono;
  final String email;
  final String direccion;
  final String ubigeo;
  final String estado;

  Cliente({
    required this.id,
    required this.empId,
    required this.nombre,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.telefono,
    required this.email,
    required this.direccion,
    required this.ubigeo,
    required this.estado,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['cli_id'].toString(),
      empId: json['cli_emp_id'].toString(),
      nombre: json['cli_nombre'] ?? '',
      tipoDocumento: json['cli_tipo_documento'] ?? '',
      numeroDocumento: json['cli_numero_documento'] ?? '',
      telefono: json['cli_telefono'] ?? '',
      email: json['cli_email'] ?? '',
      direccion: json['cli_direccion'] ?? '',
      ubigeo: json['cli_ubigeo'] ?? '',
      estado: json['cli_estado'] ?? 'ACTIVO',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cli_id': id,
      'cli_emp_id': empId,
      'cli_nombre': nombre,
      'cli_tipo_documento': tipoDocumento,
      'cli_numero_documento': numeroDocumento,
      'cli_telefono': telefono,
      'cli_email': email,
      'cli_direccion': direccion,
      'cli_ubigeo': ubigeo,
      'cli_estado': estado,
    };
  }
}
