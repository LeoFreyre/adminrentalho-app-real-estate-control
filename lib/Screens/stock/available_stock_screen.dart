import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _StockScreenState createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _newItemNameController = TextEditingController();
  final TextEditingController _newItemQuantityController = TextEditingController();
  bool _isLoading = false;

  // Referencia a la colección en Firestore
  late CollectionReference _stockCollection;

  // Longitud máxima para nombres de items
  final int _maxNameLength = 50;

  @override
  void initState() {
    super.initState();
    _stockCollection = _firestore.collection('inventory_stock');
  }

  @override
  void dispose() {
    _newItemNameController.dispose();
    _newItemQuantityController.dispose();
    super.dispose();
  }

  // Método para añadir un nuevo item al inventario
  Future<void> _addStockItem() async {
    if (_newItemNameController.text.isNotEmpty &&
        _newItemQuantityController.text.isNotEmpty) {
      try {
        await _stockCollection.add({
          'name': _newItemNameController.text
              .trim()
              .substring(0,
                  _newItemNameController.text.length > _maxNameLength ? _maxNameLength : _newItemNameController.text.length),
          'quantity': int.tryParse(_newItemQuantityController.text) ?? 0,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Limpiar campos después de añadir
        _newItemNameController.clear();
        _newItemQuantityController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete all fields')),
        );
      }
    }
  }

  // Método para actualizar un item existente
  Future<void> _updateStockItem(String docId, String name, int quantity) async {
    if (name.isNotEmpty) {
      try {
        await _stockCollection.doc(docId).update({
          'name': name
              .trim()
              .substring(0, name.length > _maxNameLength ? _maxNameLength : name.length),
          'quantity': quantity,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name cannot be empty')),
        );
      }
    }
  }

  // Método para eliminar un item del inventario
  Future<void> _deleteStockItem(String docId) async {
    try {
      await _stockCollection.doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Inventory'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de agregar nuevo item
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Item',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Campo de texto para el nombre
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Item Name:', style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _newItemNameController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              maxLength: _maxNameLength,
                              buildCounter: (context,
                                      {required currentLength,
                                      required isFocused,
                                      maxLength}) =>
                                  null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Campo de texto para la cantidad
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quantity:', style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _newItemQuantityController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botón para añadir
                        Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Action:', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          StatefulBuilder(
                          builder: (context, setState) {
                            return SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : () async {
                              setState(() => _isLoading = true);
                              await _addStockItem();
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                              },
                              icon: _isLoading 
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white),
                                )
                              : const Icon(Icons.add),
                              label: Text(_isLoading ? 'Adding...' : 'Add'),
                              style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              ),
                            ),
                            );
                          },
                          ),
                        ],
                        ),
                      ],
                      ),
                    ],
                    ),
                  ),
            const SizedBox(height: 20),
            // Encabezado de la lista
            const Text(
              'Current Inventory',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Cabecera de la tabla
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.grey[200],
              child: Row(
              children: const [
                Expanded(
                flex: 3,
                child: Text(
                  'NAME',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                ),
                Expanded(
                flex: 1,
                child: Text(
                  'QUANTITY',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                ),
                  SizedBox(width: 104), // Espacio para los botones
                ],
              ),
            ),
            // Lista de items del inventario
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _stockCollection
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('No items in inventory'),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc = snapshot.data!.docs[index];
                      Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;
                      String itemName = data['name'] ?? 'Unknown';
                      int quantity = data['quantity'] ?? 0;

                      // Controladores para este item de la lista
                      TextEditingController nameController =
                          TextEditingController(text: itemName);
                      TextEditingController quantityController =
                          TextEditingController(text: quantity.toString());

                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            children: [
                              // Campo editable del nombre
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  maxLength: _maxNameLength,
                                  buildCounter: (context,
                                          {required currentLength,
                                          required isFocused,
                                          maxLength}) =>
                                      null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Campo editable de la cantidad
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: quantityController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Botón de guardar (update)
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _updateStockItem(
                                      doc.id,
                                      nameController.text,
                                      int.tryParse(quantityController.text) ?? 0,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: const Icon(Icons.check, size: 24),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Botón de eliminar (delete)
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () => _deleteStockItem(doc.id),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: const Icon(Icons.delete, size: 24),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
