import 'dart:io';
import '../core/api_config.dart';
import '../models/cliente.dart';
import '../models/vehiculo.dart';
import '../models/item.dart';
import '../models/empresa.dart';
import '../models/orden.dart';
import '../models/configuracion.dart';
import '../models/dashboard_stats.dart';
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

  Future<String?> saveItem(Item item) async {
    final endpoint = item.id == '0' || item.id.isEmpty
        ? ApiConfig.itemsCrear
        : ApiConfig.itemsEditar;
    final response = await _apiService.post(endpoint, item.toJson());
    if (response['status'] == 'success') {
      return response['id']?.toString() ?? item.id;
    }
    return null;
  }

  Future<bool> crearOrden(OrdenTrabajo orden) async {
    final response = await _apiService.post(
      ApiConfig.ordenesCrear,
      orden.toJson(),
    );
    return response['status'] == 'success';
  }

  Future<List<OrdenTrabajo>> getOrdenes(
    String empId, {
    String? fechaInicio,
    String? fechaFin,
  }) async {
    final Map<String, String> params = {'emp_id': empId};

    if (fechaInicio != null) {
      params['fecha_inicio'] = fechaInicio;
    }
    if (fechaFin != null) {
      params['fecha_fin'] = fechaFin;
    }

    final response = await _apiService.get(ApiConfig.ordenes, params: params);
    if (response['status'] == 'success') {
      return (response['data'] as List)
          .map((e) => OrdenTrabajo.fromJson(e))
          .toList();
    }
    return [];
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

  Future<bool> agregarItemsAOrden(String otId, List<OrdenItem> items) async {
    final response = await _apiService.post(ApiConfig.ordenesAgregarItems, {
      'ot_id': otId,
      'items': items.map((i) => i.toJson()).toList(),
    });
    return response['status'] == 'success';
  }

  Future<bool> eliminarItemDesdeOrden(String otId, String oiId) async {
    final response = await _apiService.post(ApiConfig.ordenesEliminarItem, {
      'ot_id': otId,
      'oi_id': oiId,
    });
    return response['status'] == 'success';
  }

  Future<bool> actualizarItemOrden(
    String otId,
    String oiId,
    String newItemId,
    double cantidad,
    double precio,
    int afectoIgv,
  ) async {
    final response = await _apiService.post(ApiConfig.ordenesActualizarItem, {
      'ot_id': otId,
      'oi_id': oiId,
      'oi_item_id': newItemId,
      'cantidad': cantidad,
      'precio_unitario': precio,
      'afecto_igv': afectoIgv,
    });
    return response['status'] == 'success';
  }

  Future<Map<String, dynamic>> emitirFactura(String otId, String tipo) async {
    final response = await _apiService.post(ApiConfig.facturasEmitir, {
      'ot_id': otId,
      'tipo_comprobante': tipo,
    });
    return response;
  }

  Future<bool> actualizarFotoOrden(String otId, String fotoUrl) async {
    final response = await _apiService.post(ApiConfig.ordenesActualizarFoto, {
      'ot_id': otId,
      'ot_foto': fotoUrl,
    });
    return response['status'] == 'success';
  }

  // Dashboard & Configuración
  Future<DashboardStats?> getDashboardStats() async {
    final response = await _apiService.get(ApiConfig.dashboardStats);
    if (response['status'] == 'success') {
      return DashboardStats.fromJson(response['data']);
    }
    return null;
  }

  Future<Configuracion?> getConfig() async {
    final response = await _apiService.get(ApiConfig.configObtener);
    if (response['status'] == 'success') {
      return Configuracion.fromJson(response['data']);
    }
    return null;
  }

  Future<bool> saveConfig(Configuracion config) async {
    final response = await _apiService.post(
      ApiConfig.configActualizar,
      config.toJson(),
    );
    return response['status'] == 'success';
  }
}
