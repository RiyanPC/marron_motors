class ApiConfig {
  static const String baseUrl =
      'http://localhost/marron_motors/bd_marron_motors';

  // Endpoints
  static const String empresas = '$baseUrl/empresas/listar.php';
  static const String clientes = '$baseUrl/clientes/listar.php';
  static const String vehiculos = '$baseUrl/vehiculos/listar.php';
  static const String items = '$baseUrl/items/listar.php';
  static const String ordenesCrear = '$baseUrl/ordenes/crear.php';
}
