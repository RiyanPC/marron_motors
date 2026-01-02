import 'dart:io';
import '../core/api_config.dart';
import '../models/cliente.dart';
import '../models/vehiculo.dart';
import '../models/item.dart';
import '../models/empresa.dart';
import '../models/orden.dart';
import 'api_service.dart';

class DataRepository {
  final ApiService _apiService = ApiService();

  Future<List<Empresa>> getEmpresas() async {
    final response = await _apiService.get(ApiConfig.empresas);
    if (response['status'] == 'success') {
      return (response['data'] as List)
          .map((e) => Empresa.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<List<Cliente>> getClientes(String empId) async {
    final response = await _apiService.get(
      ApiConfig.clientes,
      params: {'emp_id': empId},
    );
    if (response['status'] == 'success') {
      return (response['data'] as List)
          .map((e) => Cliente.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<List<Vehiculo>> getVehiculos(String empId) async {
    final response = await _apiService.get(
      ApiConfig.vehiculos,
      params: {'emp_id': empId},
    );
    if (response['status'] == 'success') {
      return (response['data'] as List)
          .map((e) => Vehiculo.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<List<Item>> getItems(String empId, {String? tipo}) async {
    final Map<String, String> params = {'emp_id': empId};
    if (tipo != null) params['tipo'] = tipo;

    final response = await _apiService.get(ApiConfig.items, params: params);
    if (response['status'] == 'success') {
      return (response['data'] as List).map((e) => Item.fromJson(e)).toList();
    }
    return [];
  }

  Future<String?> saveCliente(Cliente cliente) async {
    final endpoint = cliente.id == '0' || cliente.id.isEmpty
        ? ApiConfig.clientes.replaceFirst('listar.php', 'crear.php')
        : ApiConfig.clientesEditar;
    final response = await _apiService.post(endpoint, cliente.toJson());
    if (response['status'] == 'success') {
      return response['id']?.toString() ?? cliente.id;
    }
    return null;
  }

  Future<String?> saveVehiculo(Vehiculo vehiculo) async {
    final endpoint = vehiculo.id == '0' || vehiculo.id.isEmpty
        ? ApiConfig.vehiculos.replaceFirst('listar.php', 'crear.php')
        : ApiConfig.vehiculosEditar;
    final response = await _apiService.post(endpoint, vehiculo.toJson());
    if (response['status'] == 'success') {
      return response['id']?.toString() ?? vehiculo.id;
    }
    return null;
  }

  Future<bool> saveItem(Item item) async {
    final endpoint = item.id == '0' || item.id.isEmpty
        ? ApiConfig.itemsCrear
        : ApiConfig.itemsEditar;
    final response = await _apiService.post(endpoint, item.toJson());
    return response['status'] == 'success';
  }

  Future<bool> crearOrden(OrdenTrabajo orden) async {
    final response = await _apiService.post(
      ApiConfig.ordenesCrear,
      orden.toJson(),
    );
    return response['status'] == 'success';
  }

  Future<List<OrdenTrabajo>> getOrdenes(String empId) async {
    final response = await _apiService.get(
      ApiConfig.ordenes, // Make sure this exists in ApiConfig
      params: {'emp_id': empId},
    );
    if (response['status'] == 'success') {
      return (response['data'] as List)
          .map((e) => OrdenTrabajo.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> emitirFactura(String otId, String tipo) async {
    final response = await _apiService.post(
      '${ApiConfig.baseUrl}/facturas/emitir.php',
      {'ot_id': otId, 'tipo_comprobante': tipo},
    );
    return response;
  }

  Future<String?> uploadImage(
    File imageFile, {
    String folder = 'general',
    String name = 'img',
  }) async {
    final response = await _apiService.upload(
      ApiConfig.uploadImage,
      imageFile,
      fields: {'folder': folder, 'name': name},
    );
    if (response['status'] == 'success') {
      return response['url'];
    }
    return null;
  }

  Future<Map<String, dynamic>?> consultaDocumento(
    String tipo,
    String num,
  ) async {
    final response = await _apiService.get(
      ApiConfig.clientesConsulta,
      params: {'tipo': tipo, 'num': num},
    );
    if (response['status'] == 'success') {
      return response['data'];
    }
    return null;
  }

  Future<bool> actualizarEstadoOrden(String otId, String nuevoEstado) async {
    final response = await _apiService.post(ApiConfig.ordenesActualizarEstado, {
      'ot_id': otId,
      'ot_estado': nuevoEstado,
    });
    return response['status'] == 'success';
  }
}
