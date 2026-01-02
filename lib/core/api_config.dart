class ApiConfig {
  static const String baseUrl =
      'http://192.168.18.25/marron_motors/bd_marron_motors';

  // Endpoints
  static const String empresas = '$baseUrl/empresas/listar.php';
  static const String clientes = '$baseUrl/clientes/listar.php';
  static const String vehiculos = '$baseUrl/vehiculos/listar.php';
  static const String items = '$baseUrl/items/listar.php';
  static const String ordenes = '$baseUrl/ordenes/listar.php';
  static const String ordenesCrear = '$baseUrl/ordenes/crear.php';
  static const String clientesEditar = '$baseUrl/clientes/editar.php';
  static const String vehiculosEditar = '$baseUrl/vehiculos/editar.php';
  static const String itemsCrear = '$baseUrl/items/crear.php';
  static const String itemsEditar = '$baseUrl/items/editar.php';
  static const String uploadImage = '$baseUrl/uploads/upload_image.php';
  static const String clientesConsulta = '$baseUrl/clientes/consulta_doc.php';
  static const String ordenesActualizarEstado =
      '$baseUrl/ordenes/actualizar_estado.php';
  static const String ordenesAgregarItems =
      '$baseUrl/ordenes/agregar_items.php';
  static const String ordenesEliminarItem =
      '$baseUrl/ordenes/eliminar_item.php';
  static const String facturasEmitir = '$baseUrl/facturas/emitir.php';
}
