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

  Future<bool> saveCliente(Cliente cliente) async {
    final endpoint = cliente.id == '0' || cliente.id.isEmpty
        ? ApiConfig.clientes.replaceFirst('listar.php', 'crear.php')
        : ApiConfig.clientesEditar;
    final response = await _apiService.post(endpoint, cliente.toJson());
    return response['status'] == 'success';
  }

  Future<bool> saveVehiculo(Vehiculo vehiculo) async {
    final endpoint = vehiculo.id == '0' || vehiculo.id.isEmpty
        ? ApiConfig.vehiculos.replaceFirst('listar.php', 'crear.php')
        : ApiConfig.vehiculosEditar;
    final response = await _apiService.post(endpoint, vehiculo.toJson());
    return response['status'] == 'success';
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

  Future<String?> uploadImage(File imageFile) async {
    final response = await _apiService.upload(ApiConfig.uploadImage, imageFile);
    if (response['status'] == 'success') {
      return response['url'];
    }
    return null;
  }
}
