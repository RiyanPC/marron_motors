class Item {
  final String id;
  final String empId;
  final String nombre;
  final String descripcion;
  final String tipo; // REPUESTO / SERVICIO
  final double precio;
  final String codigoTributo;
  final String estado;

  Item({
    required this.id,
    required this.empId,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.precio,
    required this.codigoTributo,
    required this.estado,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['item_id'].toString(),
      empId: json['item_emp_id'].toString(),
      nombre: json['item_nombre'] ?? '',
      descripcion: json['item_descripcion'] ?? '',
      tipo: json['item_tipo'] ?? 'SERVICIO',
      precio: double.tryParse(json['item_precio']?.toString() ?? '0') ?? 0.0,
      codigoTributo: json['item_codigo_tributo'] ?? '10',
      estado: json['item_estado'] ?? 'ACTIVO',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': id,
      'item_emp_id': empId,
      'item_nombre': nombre,
      'item_descripcion': descripcion,
      'item_tipo': tipo,
      'item_precio': precio,
      'item_codigo_tributo': codigoTributo,
      'item_estado': estado,
    };
  }
}
