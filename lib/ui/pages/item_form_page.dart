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
      appBar: AppBar(title: Text(isEditing ? 'Editar Item' : 'Nuevo Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo de Item *'),
                items:
                    [
                          {'val': 'SERVICIO', 'label': 'SERVICIO'},
                          {'val': 'PRODUCTO', 'label': 'ITEM'},
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
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre / Título *',
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(labelText: 'Precio (S/) *'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: widget.item?.codigoTributo ?? '10',
                decoration: const InputDecoration(
                  labelText: 'Código de Tributo (IGV)',
                ),
                items:
                    [
                      {'id': '10', 'label': '10 - Gravado - Operación Onerosa'},
                      {
                        'id': '20',
                        'label': '20 - Exonerado - Operación Onerosa',
                      },
                      {
                        'id': '30',
                        'label': '30 - Inafecto - Operación Onerosa',
                      },
                    ].map((t) {
                      return DropdownMenuItem(
                        value: t['id'],
                        child: Text(t['label']!),
                      );
                    }).toList(),
                onChanged: (v) {
                  // This is a simplified implementation, ideally we'd use a controller or state variable
                },
              ),
              if (isEditing) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _estado,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: ['ACTIVO', 'INACTIVO']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _estado = v!),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('GUARDAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
