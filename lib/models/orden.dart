class OrdenTrabajo {
  final String? id;
  final String empId;
  final String vehId;
  final String descripcion;
  final String fechaIngreso;
  final double total;
  final List<OrdenItem> items;

  OrdenTrabajo({
    this.id,
    required this.empId,
    required this.vehId,
    required this.descripcion,
    required this.fechaIngreso,
    required this.total,
    required this.items,
  });

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
  final String itemId;
  final double cantidad;
  final double precioUnitario;
  final double subtotal;
  final double igv;
  final double total;

  OrdenItem({
    required this.itemId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.igv,
    required this.total,
  });

  Map<String, dynamic> toJson() {
    return {
      'oi_item_id': itemId,
      'oi_cantidad': cantidad,
      'oi_precio_unitario': precioUnitario,
      'oi_subtotal': subtotal,
      'oi_igv': igv,
      'oi_total': total,
    };
  }
}
