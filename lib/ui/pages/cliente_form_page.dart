import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/cliente.dart';
import '../../services/data_repository.dart';

class ClienteFormPage extends StatefulWidget {
  final Cliente? cliente;
  const ClienteFormPage({super.key, this.cliente});

  @override
  State<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends State<ClienteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = DataRepository();
  bool _saving = false;
  bool _consultando = false;

  late TextEditingController _nombreController;
  late TextEditingController _numeroDocumentoController;
  late TextEditingController _telefonoController;
  late TextEditingController _emailController;
  late TextEditingController _direccionController;
  late TextEditingController _ubigeoController;
  String _tipoDocumento = 'DNI';
  String _estado = 'ACTIVO';

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cliente?.nombre);
    _numeroDocumentoController = TextEditingController(
      text: widget.cliente?.numeroDocumento,
    );
    _telefonoController = TextEditingController(text: widget.cliente?.telefono);
    _emailController = TextEditingController(text: widget.cliente?.email);
    _direccionController = TextEditingController(
      text: widget.cliente?.direccion,
    );
    _ubigeoController = TextEditingController(text: widget.cliente?.ubigeo);
    if (widget.cliente != null) {
      _tipoDocumento = widget.cliente!.tipoDocumento;
      _estado = widget.cliente!.estado;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final cliente = Cliente(
      id: widget.cliente?.id ?? '0',
      empId: widget.cliente?.empId ?? '1', // Hardcoded emp_id
      nombre: _nombreController.text,
      tipoDocumento: _tipoDocumento,
      numeroDocumento: _numeroDocumentoController.text,
      telefono: _telefonoController.text,
      email: _emailController.text,
      direccion: _direccionController.text,
      ubigeo: _ubigeoController.text,
      estado: _estado,
    );

    try {
      final newId = await _repository.saveCliente(cliente);
      if (newId != null) {
        final savedCliente = Cliente(
          id: newId,
          empId: cliente.empId,
          nombre: cliente.nombre,
          tipoDocumento: cliente.tipoDocumento,
          numeroDocumento: cliente.numeroDocumento,
          telefono: cliente.telefono,
          email: cliente.email,
          direccion: cliente.direccion,
          ubigeo: cliente.ubigeo,
          estado: cliente.estado,
        );
        if (mounted) Navigator.pop(context, savedCliente);
      } else {
        throw Exception('Error al guardar el cliente');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _consultarDocumento() async {
    final doc = _numeroDocumentoController.text;
    if (_tipoDocumento == 'DNI' && doc.length != 8) return;
    if (_tipoDocumento == 'RUC' && doc.length != 11) return;

    setState(() => _consultando = true);
    try {
      final data = await _repository.consultaDocumento(_tipoDocumento, doc);
      if (data != null) {
        setState(() {
          if (_tipoDocumento == 'DNI') {
            _nombreController.text = data['nombre'] ?? '';
          } else {
            _nombreController.text = data['razonSocial'] ?? '';
            _direccionController.text = data['direccion'] ?? '';
            _ubigeoController.text = data['ubigeo'] ?? '';
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontraron resultados')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error en la consulta')));
      }
    } finally {
      if (mounted) setState(() => _consultando = false);
    }
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cliente != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cliente' : 'Nuevo Cliente'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader(Icons.badge_outlined, 'IDENTIFICACIÓN'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: _tipoDocumento,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Tipo Doc.',
                                helperText:
                                    '', // Reserve space for height alignment
                              ),
                              items: ['DNI', 'RUC', 'CE']
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _tipoDocumento = v!),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _numeroDocumentoController,
                              decoration: InputDecoration(
                                labelText: 'Número de Documento *',
                                prefixIcon: const Icon(Icons.numbers),
                                counterText:
                                    '${_numeroDocumentoController.text.length} / ${_tipoDocumento == 'DNI'
                                        ? 8
                                        : _tipoDocumento == 'RUC'
                                        ? 11
                                        : 15}',
                                suffixIcon: _consultando
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : (_tipoDocumento == 'DNI' ||
                                          _tipoDocumento == 'RUC')
                                    ? IconButton(
                                        icon: const Icon(Icons.search),
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        onPressed: _consultarDocumento,
                                      )
                                    : null,
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: _tipoDocumento == 'DNI'
                                  ? 8
                                  : _tipoDocumento == 'RUC'
                                  ? 11
                                  : 15,
                              onChanged: (v) => setState(() {}),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Requerido';
                                if (_tipoDocumento == 'DNI' && v.length != 8) {
                                  return 'DNI debe tener 8 dígitos';
                                }
                                if (_tipoDocumento == 'RUC' && v.length != 11) {
                                  return 'RUC debe tener 11 dígitos';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionHeader(Icons.person_outline, 'DATOS PERSONALES'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo / Razón Social *',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      if (isEditing) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _estado,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            prefixIcon: Icon(Icons.info_outline),
                          ),
                          items: ['ACTIVO', 'INACTIVO']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _estado = v!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionHeader(Icons.contact_mail_outlined, 'CONTACTO'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono / WhatsApp',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionHeader(Icons.location_on_outlined, 'UBICACIÓN'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección Fiscal / Domicilio',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ubigeoController,
                        decoration: const InputDecoration(
                          labelText: 'Ubigeo (6 dígitos)',
                          hintText: 'Ej: 150101',
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEditing ? 'ACTUALIZAR DATOS' : 'REGISTRAR CLIENTE',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
