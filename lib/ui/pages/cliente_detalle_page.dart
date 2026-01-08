import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/cliente.dart';
import '../../models/vehiculo.dart';
import '../../services/data_repository.dart';
import 'vehiculo_detalle_page.dart';

class ClienteDetallePage extends StatefulWidget {
  final Cliente cliente;
  const ClienteDetallePage({super.key, required this.cliente});

  @override
  State<ClienteDetallePage> createState() => _ClienteDetallePageState();
}

class _ClienteDetallePageState extends State<ClienteDetallePage> {
  final DataRepository _repository = DataRepository();
  List<Vehiculo> _vehiculos = [];
  bool _loadingVehicles = true;

  @override
  void initState() {
    super.initState();
    _loadVehiculos();
  }

  Future<void> _loadVehiculos() async {
    try {
      final allVehiculos = await _repository.getVehiculos(widget.cliente.empId);
      if (mounted) {
        setState(() {
          _vehiculos = allVehiculos
              .where((v) => v.cliId == widget.cliente.id)
              .toList();
          _loadingVehicles = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingVehicles = false);
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Perfil del Cliente'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(Icons.info_outline, 'DATOS DE CONTACTO'),
                  _buildContactCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    Icons.directions_car,
                    'VEHÍCULOS (${_vehiculos.length})',
                  ),
                  _buildVehiclesSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 32, top: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              widget.cliente.nombre.isNotEmpty
                  ? widget.cliente.nombre[0].toUpperCase()
                  : 'C',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.cliente.nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: widget.cliente.estado == 'ACTIVO'
                  ? Colors.green.shade400
                  : Colors.red.shade400,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              widget.cliente.estado,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.badge_outlined,
              'Documento Identidad',
              '${widget.cliente.tipoDocumento}: ${widget.cliente.numeroDocumento}',
            ),
            const Divider(),
            _buildInfoRow(
              Icons.phone_android_rounded,
              'Teléfono Principal',
              widget.cliente.telefono,
              onPressed: () => _makeCall(widget.cliente.telefono),
              actionIcon: Icons.call,
              actionColor: Colors.green,
            ),
            const Divider(),
            _buildInfoRow(
              Icons.email_outlined,
              'Correo Electrónico',
              widget.cliente.email.isEmpty
                  ? 'No registrado'
                  : widget.cliente.email,
            ),
            const Divider(),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Dirección Registrada',
              widget.cliente.direccion.isEmpty
                  ? 'No registrada'
                  : widget.cliente.direccion,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiclesSection() {
    if (_loadingVehicles) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_vehiculos.isEmpty) {
      return Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Text(
              'Este cliente aún no tiene vehículos registrados.',
              style: TextStyle(color: Colors.blueGrey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _vehiculos.map((v) => _buildVehicleCard(v)).toList(),
    );
  }

  Widget _buildVehicleCard(Vehiculo vehiculo) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehiculoDetallePage(vehiculo: vehiculo),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  image: vehiculo.foto.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(vehiculo.foto),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: vehiculo.foto.isEmpty
                    ? Icon(
                        Icons.directions_car,
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehiculo.placa,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${vehiculo.marca} ${vehiculo.modelo}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Color: ${vehiculo.color} • Año: ${vehiculo.anio}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onPressed,
    IconData? actionIcon,
    Color? actionColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (onPressed != null && value.isNotEmpty)
            IconButton(
              onPressed: onPressed,
              icon: Icon(actionIcon, color: actionColor ?? Colors.blue),
            ),
        ],
      ),
    );
  }
}
