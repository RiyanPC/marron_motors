import 'package:flutter/material.dart';

class ItemEditorDialog extends StatefulWidget {
  final String? initialNombre;
  final double initialCantidad;
  final double initialPrecio;
  final int initialAfectoIgv; // 1 = Gravado, 0 = Otros

  const ItemEditorDialog({
    super.key,
    this.initialNombre,
    required this.initialCantidad,
    required this.initialPrecio,
    required this.initialAfectoIgv,
  });

  @override
  State<ItemEditorDialog> createState() => _ItemEditorDialogState();
}

class _ItemEditorDialogState extends State<ItemEditorDialog> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _cantidadCtrl;
  late TextEditingController _precioCtrl;
  late String _selectedTributo;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.initialNombre ?? '');
    _cantidadCtrl = TextEditingController(
      text: widget.initialCantidad.toInt().toString(),
    );
    _precioCtrl = TextEditingController(
      text: widget.initialPrecio.toStringAsFixed(2),
    );
    // 10 = Gravado, 20 = Exonerado (Default mapping)
    _selectedTributo = widget.initialAfectoIgv == 1 ? '10' : '20';
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cantidadCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_note, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'Editar Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildTextField(
                  controller: _nombreCtrl,
                  label: 'Descripción / Nombre',
                  icon: Icons.description_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _cantidadCtrl,
                        label: 'Cantidad',
                        icon: Icons.numbers,
                        isNumeric: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _precioCtrl,
                        label: 'Precio Unit.',
                        icon: Icons.attach_money,
                        prefixText: 'S/ ',
                        isNumeric: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedTributo,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Impuesto',
                    prefixIcon: Icon(
                      Icons.receipt_long_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: const [
                    DropdownMenuItem(value: '10', child: Text('Gravado (18%)')),
                    DropdownMenuItem(
                      value: '20',
                      child: Text('Exonerado (0%)'),
                    ),
                    DropdownMenuItem(value: '30', child: Text('Inafecto (0%)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedTributo = val);
                    }
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: Text(
                      'CANCELAR',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.4),
                    ),
                    child: const Text(
                      'GUARDAR CAMBIOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumeric = false,
    String? prefixText,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  void _submit() {
    final nombre = _nombreCtrl.text.trim();
    final cantidad =
        double.tryParse(_cantidadCtrl.text) ?? widget.initialCantidad;
    final precio = double.tryParse(_precioCtrl.text) ?? widget.initialPrecio;
    // 10 = Gravado -> afectoIgv 1, others -> 0
    final afectoIgv = _selectedTributo == '10' ? 1 : 0;

    if (nombre.isEmpty || cantidad <= 0 || precio < 0) {
      // Basic validation feedback could be added here
      return;
    }

    Navigator.pop(context, {
      'nombre': nombre,
      'cantidad': cantidad,
      'precio': precio,
      'afectoIgv': afectoIgv,
      'codigoTributo': _selectedTributo,
    });
  }
}
