import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../models/orden.dart';
import '../../services/data_repository.dart';
import '../pages/item_form_page.dart';

class ItemSelectorModal extends StatefulWidget {
  const ItemSelectorModal({super.key});

  @override
  State<ItemSelectorModal> createState() => _ItemSelectorModalState();
}

class _ItemSelectorModalState extends State<ItemSelectorModal> {
  final _repository = DataRepository();
  final _searchController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  final _precioController = TextEditingController();
  bool _afectoIgv = false;

  List<Item> _allItems = [];
  List<Item> _filteredItems = [];
  bool _loading = true;
  Item? _selectedItem;
  String _tipoFiltro = 'TODOS'; // TODOS, SERVICIO, PRODUCTO

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchController.addListener(_filterItems);
  }

  Future<void> _loadItems() async {
    try {
      final data = await _repository.getItems('1'); // Hardcoded emp_id
      setState(() {
        _allItems = data;
        _filteredItems = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar items: $e')));
      }
    }
  }

  void _openItemForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ItemFormPage()),
    );

    if (result == true) {
      setState(() => _loading = true);
      _loadItems();
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _allItems.where((i) {
        final matchesQuery =
            i.nombre.toLowerCase().contains(query) ||
            i.descripcion.toLowerCase().contains(query);
        final matchesTipo = _tipoFiltro == 'TODOS' || i.tipo == _tipoFiltro;
        return matchesQuery && matchesTipo;
      }).toList();
    });
  }

  void _onItemTap(Item item) {
    setState(() {
      _selectedItem = item;
      _precioController.text = item.precio.toStringAsFixed(2);
    });
  }

  void _confirmSelection() {
    if (_selectedItem == null) return;

    final double? cant = double.tryParse(_cantidadController.text);
    final double? precio = double.tryParse(_precioController.text);

    if (cant == null || cant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese una cantidad válida')),
      );
      return;
    }

    if (precio == null || precio < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingrese un precio válido')));
      return;
    }

    final subtotal = cant * precio;
    final igv = _afectoIgv ? subtotal * 0.18 : 0.0;
    final total = subtotal + igv;

    final ordenItem = OrdenItem(
      itemId: _selectedItem!.id,
      cantidad: cant,
      precioUnitario: precio,
      subtotal: subtotal,
      igv: igv,
      total: total,
      afectoIgv: _afectoIgv ? 1 : 0,
    );

    Navigator.pop(context, ordenItem);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Añadir Item a la Orden',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _openItemForm,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('NUEVO ITEM', style: TextStyle(fontSize: 12)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Filtro de Tipo
          Row(
            children: [
              _filterChip('TODOS'),
              const SizedBox(width: 8),
              _filterChip('SERVICIO'),
              const SizedBox(width: 8),
              _filterChip('PRODUCTO', label: 'ITEMS'),
            ],
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar item...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = _selectedItem?.id == item.id;
                      return Card(
                        elevation: isSelected ? 4 : 1,
                        color: isSelected ? Colors.blue.shade50 : null,
                        child: ListTile(
                          title: Text(item.nombre),
                          subtitle: Text('Precio ref: S/ ${item.precio}'),
                          trailing: Icon(
                            item.tipo == 'SERVICIO'
                                ? Icons.build
                                : Icons.inventory_2,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onTap: () => _onItemTap(item),
                        ),
                      );
                    },
                  ),
          ),

          if (_selectedItem != null) ...[
            const Divider(height: 32),
            const Text(
              'Configurar Detalle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cantidadController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _precioController,
                    decoration: const InputDecoration(
                      labelText: 'Precio Unit. (S/)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Aplicar IGV (18%)'),
              subtitle: Text(
                _afectoIgv ? 'Operación Gravada' : 'Operación Exonerada',
              ),
              value: _afectoIgv,
              onChanged: (val) => setState(() => _afectoIgv = val),
              secondary: Icon(
                _afectoIgv ? Icons.receipt : Icons.money_off,
                color: _afectoIgv ? Colors.blue : Colors.grey,
              ),
              dense: true,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _confirmSelection,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('AÑADIR A LA ORDEN'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(String value, {String? label}) {
    final isSelected = _tipoFiltro == value;
    return ChoiceChip(
      label: Text(label ?? value),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _tipoFiltro = value;
            _filterItems();
          });
        }
      },
    );
  }
}
