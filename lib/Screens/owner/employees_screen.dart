import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

// Estado del widget EmployeesScreen
class _EmployeesScreenState extends State<EmployeesScreen> {
  // Instancia de Firestore para interactuar con la base de datos
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Muestra el diálogo para crear o editar un grupo.
  /// Si se pasa [groupDoc] se carga la información del grupo para editar.
  void _showGroupDialog({DocumentSnapshot? groupDoc}) {
    // Variables iniciales: en modo edición, se cargan los datos existentes.
    String groupName = groupDoc != null ? groupDoc['name'] : '';
    String groupType = groupDoc != null ? groupDoc['type'] : 'Cleaning';
    List<String> selectedEmployees = groupDoc != null
        ? List<String>.from(groupDoc['members'] ?? [])
        : [];

    // Usamos StatefulBuilder para actualizar el estado dentro del diálogo.
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            // Título del diálogo con opción de eliminar si es edición
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(groupDoc != null ? 'Edit Group' : 'Create New Group'),
                if (groupDoc != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Primero cerramos el diálogo actual
                      Navigator.pop(context);
                      // Eliminamos el grupo de Firestore
                      _firestore.collection('groups').doc(groupDoc.id).delete();
                    },
                  ),
              ],
            ),
            // Contenido del diálogo con scroll
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Campo para el nombre del grupo
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                    ),
                    controller: TextEditingController(text: groupName),
                    onChanged: (value) => groupName = value,
                  ),
                  const SizedBox(height: 16),
                  // Dropdown para el tipo de grupo
                  DropdownButtonFormField<String>(
                    value: groupType,
                    decoration: const InputDecoration(labelText: 'Group Type'),
                    items: const [
                      DropdownMenuItem(
                          value: 'Cleaning', child: Text('Cleaning')),
                      DropdownMenuItem(
                          value: 'Maintenance', child: Text('Maintenance')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        groupType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Lista de empleados con consulta a Firestore
                  FutureBuilder<QuerySnapshot>(
                    future: _firestore
                        .collection('users')
                        .where('role', isEqualTo: 'employee')
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final employees = snapshot.data!.docs;
                      return Column(
                        children: employees.map((employee) {
                          return CheckboxListTile(
                            title: Text(employee['name']),
                            value: selectedEmployees.contains(employee.id),
                            onChanged: (selected) {
                              setStateDialog(() {
                                if (selected == true) {
                                  selectedEmployees.add(employee.id);
                                } else {
                                  selectedEmployees.remove(employee.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Botones de acción del diálogo
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (groupName.isNotEmpty) {
                    if (groupDoc != null) {
                      // Actualiza el grupo existente
                      _firestore.collection('groups').doc(groupDoc.id).update({
                        'name': groupName,
                        'type': groupType,
                        'members': selectedEmployees,
                      });
                    } else {
                      // Crea un nuevo grupo
                      _firestore.collection('groups').add({
                        'name': groupName,
                        'type': groupType,
                        'members': selectedEmployees,
                      });
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(groupDoc != null ? 'Update' : 'Create'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Grupos de Trabajo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Work Groups',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showGroupDialog(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Stream de grupos desde Firestore
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('groups').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final groups = snapshot.data!.docs;
                if (groups.isEmpty) {
                  return const Text('No groups created yet.');
                }
                // Lista de grupos con scroll deshabilitado
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          group['name'],
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('Type: ${group['type']}'),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showGroupDialog(groupDoc: group),
                        ),
                        onTap: () {
                          // Abre el diálogo de edición al tocar
                          _showGroupDialog(groupDoc: group);
                        },
                      ),
                    );
                  },
                );
              },
            ),
            const Divider(height: 32),
            // Sección de Empleados
            const Text(
              'Employees',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Stream de empleados desde Firestore
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'employee')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final employees = snapshot.data!.docs;
                if (employees.isEmpty) {
                  return const Text('No employees found.');
                }
                // Lista de empleados con scroll deshabilitado
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    final employee = employees[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(employee['name'][0]),
                        ),
                        title: Text(employee['name']),
                        subtitle: const Text('Worker'),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}