class Cliente {
  final String id;
  final String empId;
  final String nombre;
  final String documento;
  final String telefono;
  final String email;
  final String direccion;
  final String estado;

  Cliente({
    required this.id,
    required this.empId,
    required this.nombre,
    required this.documento,
    required this.telefono,
    required this.email,
    required this.direccion,
    required this.estado,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['cli_id'].toString(),
      empId: json['cli_emp_id'].toString(),
      nombre: json['cli_nombre'] ?? '',
      documento: json['cli_documento'] ?? '',
      telefono: json['cli_telefono'] ?? '',
      email: json['cli_email'] ?? '',
      direccion: json['cli_direccion'] ?? '',
      estado: json['cli_estado'] ?? 'ACTIVO',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cli_id': id,
      'cli_emp_id': empId,
      'cli_nombre': nombre,
      'cli_documento': documento,
      'cli_telefono': telefono,
      'cli_email': email,
      'cli_direccion': direccion,
      'cli_estado': estado,
    };
  }
}
