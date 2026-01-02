class Factura {
  final String id;
  final String empId;
  final String otId;
  final String cliId;
  final String tipoComprobante; // F o B
  final String serie;
  final int numero;
  final String externalId;
  final String fechaEmision;
  final double total;
  final String estado;
  final String pdfUrl;
  final String xmlUrl;

  Factura({
    required this.id,
    required this.empId,
    required this.otId,
    required this.cliId,
    required this.tipoComprobante,
    required this.serie,
    required this.numero,
    required this.externalId,
    required this.fechaEmision,
    required this.total,
    required this.estado,
    required this.pdfUrl,
    required this.xmlUrl,
  });

  factory Factura.fromJson(Map<String, dynamic> json) {
    return Factura(
      id: json['fac_id'].toString(),
      empId: json['fac_emp_id'].toString(),
      otId: json['fac_ot_id'].toString(),
      cliId: json['fac_cli_id'].toString(),
      tipoComprobante: json['fac_tipo_comprobante'] ?? '',
      serie: json['fac_serie'] ?? '',
      numero: int.tryParse(json['fac_numero']?.toString() ?? '0') ?? 0,
      externalId: json['fac_external_id'] ?? '',
      fechaEmision: json['fac_fecha_emision'] ?? '',
      total: double.tryParse(json['fac_total']?.toString() ?? '0') ?? 0.0,
      estado: json['fac_estado'] ?? '',
      pdfUrl: json['fac_pdf_url'] ?? '',
      xmlUrl: json['fac_xml_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fac_id': id,
      'fac_emp_id': empId,
      'fac_ot_id': otId,
      'fac_cli_id': cliId,
      'fac_tipo_comprobante': tipoComprobante,
      'fac_serie': serie,
      'fac_numero': numero,
      'fac_external_id': externalId,
      'fac_fecha_emision': fechaEmision,
      'fac_total': total,
      'fac_estado': estado,
      'fac_pdf_url': pdfUrl,
      'fac_xml_url': xmlUrl,
    };
  }
}
