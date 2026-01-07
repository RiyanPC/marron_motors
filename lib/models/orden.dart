class OrdenTrabajo {
  final String? id;
  final String empId;
  final String vehId;
  final String descripcion;
  final String fechaIngreso;
  final String? fechaCreate;
  final String? vehPlaca;
  final String? vehTipo;
  final String? vehMarca;
  final String? vehModelo;
  final int? vehAnio;
  final String? vehVin;
  final String? cliNombre;
  final String? cliTelefono;
  final String? cliEmail;
  final String? cliDireccion;
  final String? cliDocumento;
  final String? cliTipoDocumento;
  final String estado;
  final double total;
  final String? facId;
  final String? facTipoComprobante;
  final String? foto;
  final List<OrdenItem> items;

  OrdenTrabajo({
    this.id,
    required this.empId,
    required this.vehId,
    required this.descripcion,
    required this.fechaIngreso,
    this.fechaCreate,
    this.vehPlaca,
    this.vehTipo,
    this.vehMarca,
    this.vehModelo,
    this.vehAnio,
    this.vehVin,
    this.cliNombre,
    this.cliTelefono,
    this.cliEmail,
    this.cliDireccion,
    this.cliDocumento,
    this.cliTipoDocumento,
    required this.estado,
    required this.total,
    this.facId,
    this.facTipoComprobante,
    this.foto,
    required this.items,
  });

  factory OrdenTrabajo.fromJson(Map<String, dynamic> json) {
    return OrdenTrabajo(
      id: json['ot_id'].toString(),
      empId: json['ot_emp_id'].toString(),
      vehId: json['ot_veh_id'].toString(),
      descripcion: json['ot_descripcion'] ?? '',
      fechaIngreso: json['ot_fecha_ingreso'] ?? '',
      fechaCreate: json['ot_fecha_create'],
      vehPlaca: json['veh_placa'],
      vehTipo: json['veh_tipo'],
      vehMarca: json['veh_marca'],
      vehModelo: json['veh_modelo'],
      vehAnio: int.tryParse(json['veh_anio']?.toString() ?? ''),
      vehVin: json['veh_vin'],
      cliNombre: json['cli_nombre'],
      cliTelefono: json['cli_telefono'],
      cliEmail: json['cli_email'],
      cliDireccion: json['cli_direccion'],
      cliDocumento: json['cli_numero_documento'],
      cliTipoDocumento: json['cli_tipo_documento'],
      estado: json['ot_estado'] ?? 'ABIERTA',
      total: double.tryParse(json['ot_total']?.toString() ?? '0') ?? 0.0,
      facId: json['fac_id']?.toString(),
      facTipoComprobante: json['fac_tipo_comprobante'],
      foto: json['ot_foto'],
      items: json['items'] != null
          ? (json['items'] as List).map((e) => OrdenItem.fromJson(e)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ot_emp_id': empId,
      'ot_veh_id': vehId,
      'ot_descripcion': descripcion,
      'ot_fecha_ingreso': fechaIngreso,
      'ot_total': total,
      'ot_foto': foto,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  OrdenTrabajo copyWith({
    String? id,
    String? empId,
    String? vehId,
    String? descripcion,
    String? fechaIngreso,
    String? fechaCreate,
    String? vehPlaca,
    String? vehTipo,
    String? vehMarca,
    String? vehModelo,
    int? vehAnio,
    String? vehVin,
    String? cliNombre,
    String? cliTelefono,
    String? cliEmail,
    String? cliDireccion,
    String? cliDocumento,
    String? cliTipoDocumento,
    String? estado,
    double? total,
    String? facId,
    String? facTipoComprobante,
    String? foto,
    List<OrdenItem>? items,
  }) {
    return OrdenTrabajo(
      id: id ?? this.id,
      empId: empId ?? this.empId,
      vehId: vehId ?? this.vehId,
      descripcion: descripcion ?? this.descripcion,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      fechaCreate: fechaCreate ?? this.fechaCreate,
      vehPlaca: vehPlaca ?? this.vehPlaca,
      vehTipo: vehTipo ?? this.vehTipo,
      vehMarca: vehMarca ?? this.vehMarca,
      vehModelo: vehModelo ?? this.vehModelo,
      vehAnio: vehAnio ?? this.vehAnio,
      vehVin: vehVin ?? this.vehVin,
      cliNombre: cliNombre ?? this.cliNombre,
      cliTelefono: cliTelefono ?? this.cliTelefono,
      cliEmail: cliEmail ?? this.cliEmail,
      cliDireccion: cliDireccion ?? this.cliDireccion,
      cliDocumento: cliDocumento ?? this.cliDocumento,
      cliTipoDocumento: cliTipoDocumento ?? this.cliTipoDocumento,
      estado: estado ?? this.estado,
      total: total ?? this.total,
      facId: facId ?? this.facId,
      facTipoComprobante: facTipoComprobante ?? this.facTipoComprobante,
      foto: foto ?? this.foto,
      items: items ?? this.items,
    );
  }
}

class OrdenItem {
  final String? id;
  final String? otId;
  final String itemId;
  final String? itemNombre;
  final double cantidad;
  final double precioUnitario;
  final double subtotal;
  final double igv;
  final double total;
  final int afectoIgv;

  OrdenItem({
    this.id,
    this.otId,
    required this.itemId,
    this.itemNombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.igv,
    required this.total,
    this.afectoIgv = 1,
  });

  factory OrdenItem.fromJson(Map<String, dynamic> json) {
    return OrdenItem(
      id: json['oi_id']?.toString(),
      otId: json['oi_ot_id']?.toString(),
      itemId: json['oi_item_id'].toString(),
      itemNombre: json['item_nombre'],
      cantidad: double.tryParse(json['oi_cantidad']?.toString() ?? '0') ?? 0.0,
      precioUnitario:
          double.tryParse(json['oi_precio_unitario']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['oi_subtotal']?.toString() ?? '0') ?? 0.0,
      igv: double.tryParse(json['oi_igv']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['oi_total']?.toString() ?? '0') ?? 0.0,
      afectoIgv: int.tryParse(json['oi_afecto_igv']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'oi_item_id': itemId,
      'oi_cantidad': cantidad,
      'oi_precio_unitario': precioUnitario,
      'oi_subtotal': subtotal,
      'oi_igv': igv,
      'oi_total': total,
      'oi_afecto_igv': afectoIgv,
    };
  }

  OrdenItem copyWith({
    String? id,
    String? otId,
    String? itemId,
    String? itemNombre,
    double? cantidad,
    double? precioUnitario,
    double? subtotal,
    double? igv,
    double? total,
    int? afectoIgv,
  }) {
    return OrdenItem(
      id: id ?? this.id,
      otId: otId ?? this.otId,
      itemId: itemId ?? this.itemId,
      itemNombre: itemNombre ?? this.itemNombre,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      subtotal: subtotal ?? this.subtotal,
      igv: igv ?? this.igv,
      total: total ?? this.total,
      afectoIgv: afectoIgv ?? this.afectoIgv,
    );
  }
}
