class OrdenTrabajo {
  final String? id;
  final String empId;
  final String vehId;
  final String descripcion;
  final String fechaIngreso;
  final String? fechaCreate;
  final String? vehPlaca;
  final String? cliNombre;
  final String estado;
  final double total;
  final String? facId;
  final List<OrdenItem> items;

  OrdenTrabajo({
    this.id,
    required this.empId,
    required this.vehId,
    required this.descripcion,
    required this.fechaIngreso,
    this.fechaCreate,
    this.vehPlaca,
    this.cliNombre,
    required this.estado,
    required this.total,
    this.facId,
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
      cliNombre: json['cli_nombre'],
      estado: json['ot_estado'] ?? 'ABIERTA',
      total: double.tryParse(json['ot_total']?.toString() ?? '0') ?? 0.0,
      facId: json['fac_id']?.toString(),
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
      'items': items.map((e) => e.toJson()).toList(),
    };
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
}
