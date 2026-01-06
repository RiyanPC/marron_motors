import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../services/data_repository.dart';

class ItemFormPage extends StatefulWidget {
  final Item? item;
  const ItemFormPage({super.key, this.item});

  @override
  State<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends State<ItemFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = DataRepository();
  bool _saving = false;

  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioController;
  String _tipo = 'SERVICIO';
  String _estado = 'ACTIVO';

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.item?.nombre);
    _descripcionController = TextEditingController(
      text: widget.item?.descripcion,
    );
    _precioController = TextEditingController(
      text: widget.item?.precio.toString() ?? '0.00',
    );
    if (widget.item != null) {
      _tipo = widget.item!.tipo;
      _estado = widget.item!.estado;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final item = Item(
      id: widget.item?.id ?? '0',
      empId: widget.item?.empId ?? '1',
      nombre: _nombreController.text,
      descripcion: _descripcionController.text,
      tipo: _tipo,
      precio: double.tryParse(_precioController.text) ?? 0.0,
      codigoTributo: '10', // Default Gravado
      estado: _estado,
    );

    try {
      final success = await _repository.saveItem(item);
      if (success) {
        if (mounted) Navigator.pop(context, true);
      } else {
        throw Exception('Error al guardar el item');
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Item' : 'Nuevo Item',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[50],
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información General',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tipo de Item
                        DropdownButtonFormField<String>(
                          value: _tipo,
                          decoration: InputDecoration(
                            labelText: 'Tipo de Item',
                            prefixIcon: Icon(
                              _tipo == 'SERVICIO'
                                  ? Icons.build_circle
                                  : Icons.inventory_2,
                              color: const Color(0xFF0D47A1),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items:
                              [
                                    {'val': 'SERVICIO', 'label': 'SERVICIO'},
                                    {
                                      'val': 'PRODUCTO',
                                      'label': 'ITEM / REPUESTO',
                                    },
                                  ]
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t['val'],
                                      child: Text(t['label']!),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => _tipo = v!),
                        ),
                        const SizedBox(height: 16),

                        // Nombre
                        TextFormField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre / Título',
                            prefixIcon: const Icon(
                              Icons.label,
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),

                        // Descripción
                        TextFormField(
                          controller: _descripcionController,
                          decoration: InputDecoration(
                            labelText: 'Descripción (Opcional)',
                            prefixIcon: const Icon(
                              Icons.description,
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalles Económicos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Precio
                        TextFormField(
                          controller: _precioController,
                          decoration: InputDecoration(
                            labelText: 'Precio Referencial (S/)',
                            prefixIcon: const Icon(
                              Icons.attach_money,
                              color: Colors.green,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),

                        // Codigo Tributo
                        DropdownButtonFormField<String>(
                          value: widget.item?.codigoTributo ?? '10',
                          decoration: InputDecoration(
                            labelText: 'Código de Tributo Default',
                            prefixIcon: const Icon(
                              Icons.receipt_long,
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          isExpanded: true,
                          items:
                              [
                                {'id': '10', 'label': '10 - Gravado - Onerosa'},
                                {
                                  'id': '20',
                                  'label': '20 - Exonerado - Onerosa',
                                },
                                {
                                  'id': '30',
                                  'label': '30 - Inafecto - Onerosa',
                                },
                              ].map((t) {
                                return DropdownMenuItem(
                                  value: t['id'],
                                  child: Text(
                                    t['label']!,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged: (v) {
                            // TODO: Add controller support
                          },
                        ),

                        if (isEditing) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _estado,
                            decoration: InputDecoration(
                              labelText: 'Estado',
                              prefixIcon: Icon(
                                _estado == 'ACTIVO'
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: _estado == 'ACTIVO'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: ['ACTIVO', 'INACTIVO']
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _estado = v!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Guardar
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                      : const Text(
                          'GUARDAR ITEM',
                          style: TextStyle(
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
      ),
    );
  }
}
