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
  String _tipoFiltro = 'TODOS'; // TODOS, SERVICIO, REPUESTO

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
      itemNombre: _selectedItem!.nombre, // Set itemNombre explicitly
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
    // Determine height based on screen size but keep it reasonable
    final double modalHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: modalHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Añadir Item a la Orden',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _openItemForm,
                      icon: const Icon(
                        Icons.add,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'NUEVO',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Chips de Filtro
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('TODOS'),
                        const SizedBox(width: 8),
                        _filterChip('SERVICIO'),
                        const SizedBox(width: 8),
                        _filterChip('REPUESTO', label: 'REPUESTOS'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Buscador
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar item por nombre...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lista de Items
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No se encontraron items',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _filteredItems.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              final isSelected = _selectedItem?.id == item.id;
                              return InkWell(
                                onTap: () => _onItemTap(item),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                              .withOpacity(0.08)
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.grey[200]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      if (!isSelected)
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: item.tipo == 'SERVICIO'
                                          ? Colors.orange.withOpacity(0.1)
                                          : Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1),
                                      child: Icon(
                                        item.tipo == 'SERVICIO'
                                            ? Icons.build
                                            : Icons.settings,
                                        color: item.tipo == 'SERVICIO'
                                            ? Colors.orange[800]
                                            : Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      item.nombre,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Colors.black87,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Ref: S/ ${item.precio.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check_circle,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Sección de Detalle / Confirmación
                  if (_selectedItem != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.edit_note,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Detalles de la operación',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _cantidadController,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Cantidad',
                                    prefixIcon: Icon(Icons.numbers, size: 18),
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _precioController,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Precio Unit.',
                                    prefixText: 'S/ ',
                                    prefixIcon: Icon(
                                      Icons.attach_money,
                                      size: 18,
                                    ),
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: SwitchListTile(
                              title: const Text(
                                'Aplicar IGV (18%)',
                                style: TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                _afectoIgv
                                    ? 'Operación Gravada'
                                    : 'Operación Exonerada',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _afectoIgv
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                                ),
                              ),
                              value: _afectoIgv,
                              activeColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              onChanged: (val) =>
                                  setState(() => _afectoIgv = val),
                              secondary: Icon(
                                _afectoIgv
                                    ? Icons.receipt_long
                                    : Icons.money_off,
                                color: _afectoIgv
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _confirmSelection,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'AÑADIR A LA ORDEN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, {String? label}) {
    final isSelected = _tipoFiltro == value;
    return FilterChip(
      label: Text(
        label ?? value,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _tipoFiltro = value;
            _filterItems();
          });
        }
      },
      backgroundColor: Colors.white,
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.grey[300]!,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      showCheckmark: false,
    );
  }
}
