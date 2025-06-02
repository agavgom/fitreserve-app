import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController monitorController = TextEditingController();
  final TextEditingController aforoController = TextEditingController();
  DateTime? fechaSeleccionada;

  Future<void> _seleccionarFechaYHora() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (fecha == null) return;

    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (hora == null) return;

    setState(() {
      fechaSeleccionada = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Future<void> _crearClase() async {
    if (nombreController.text.trim().isEmpty ||
        monitorController.text.trim().isEmpty ||
        aforoController.text.trim().isEmpty ||
        fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('clases').add({
        'nombre': nombreController.text.trim(),
        'monitor': monitorController.text.trim(),
        'aforo': int.parse(aforoController.text.trim()),
        'fecha': Timestamp.fromDate(fechaSeleccionada!),
        'inscritos': 0,
      });

      nombreController.clear();
      monitorController.clear();
      aforoController.clear();
      setState(() {
        fechaSeleccionada = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clase creada correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear clase: $e')));
    }
  }

  void _mostrarReservas(BuildContext context, String claseId) async {
    final reservas =
        await FirebaseFirestore.instance
            .collection('reservas')
            .where(
              'claseId',
              isEqualTo: FirebaseFirestore.instance
                  .collection('clases')
                  .doc(claseId),
            )
            .get();

    List<String> emails = [];

    for (var reserva in reservas.docs) {
      final usuarioId = reserva['usuarioId'];
      final usuarioDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(usuarioId)
              .get();

      if (usuarioDoc.exists && usuarioDoc.data()!.containsKey('email')) {
        emails.add(usuarioDoc['email']);
      } else {
        emails.add('Email no encontrado para UID: $usuarioId');
      }
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Reservas para esta clase'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: emails.map((email) => Text(email)).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  void _mostrarListaEspera(BuildContext context, String claseId) {
    final claseRef = FirebaseFirestore.instance
        .collection('clases')
        .doc(claseId);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Lista de espera'),
            content: FutureBuilder<QuerySnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('lista_espera')
                      .where('claseId', isEqualTo: claseRef)
                      .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final espera = snapshot.data!.docs;
                if (espera.isEmpty) {
                  return const Text('No hay nadie en lista de espera.');
                }
                return SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children:
                        espera.map((e) {
                          final usuarioId = e['usuarioId'];
                          return ListTile(title: Text('Usuario: $usuarioId'));
                        }).toList(),
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
appBar: AppBar(
  title: const Text('Panel Administrador'),
  actions: [
    IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Cerrar sesión',
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
    ),
  ],
),

body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crear nueva clase',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la clase',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: monitorController,
              decoration: const InputDecoration(labelText: 'Monitor'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: aforoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Aforo'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _seleccionarFechaYHora,
              child: Text(
                fechaSeleccionada == null
                    ? 'Seleccionar fecha y hora'
                    : '${fechaSeleccionada!.toLocal()}',
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _crearClase,
                child: const Text('Crear clase'),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text(
              'Listado de clases',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('clases')
                      .orderBy('fecha')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final clases = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: clases.length,
                  itemBuilder: (context, index) {
                    final clase = clases[index];
                    final nombre = clase['nombre'];
                    final monitor = clase['monitor'];
                    final aforo = clase['aforo'];
                    final inscritos = clase['inscritos'];
                    final fecha = (clase['fecha'] as Timestamp).toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(nombre),
                        subtitle: Text(
                          'Monitor: $monitor'
                          'Fecha: ${fecha.toLocal()}'
                          'Aforo: $inscritos / $aforo',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text(
                                          'Confirmar eliminación',
                                        ),
                                        content: const Text(
                                          '¿Estás segura de que deseas eliminar esta clase? Se eliminarán las reservas asociadas.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                );

                                if (confirm == true) {
                                  final claseRef = FirebaseFirestore.instance
                                      .collection('clases')
                                      .doc(clase.id);

                                  // Eliminar reservas asociadas
                                  final reservas =
                                      await FirebaseFirestore.instance
                                          .collection('reservas')
                                          .where('claseId', isEqualTo: claseRef)
                                          .get();

                                  for (var reserva in reservas.docs) {
                                    await reserva.reference.delete();
                                  }

                                  await claseRef.delete();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Clase y reservas eliminadas',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                final TextEditingController editNombre =
                                    TextEditingController(
                                      text: clase['nombre'],
                                    );
                                final TextEditingController editMonitor =
                                    TextEditingController(
                                      text: clase['monitor'],
                                    );
                                final TextEditingController editAforo =
                                    TextEditingController(
                                      text: clase['aforo'].toString(),
                                    );
                                DateTime? editFecha =
                                    (clase['fecha'] as Timestamp).toDate();

                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return StatefulBuilder(
                                      builder:
                                          (context, setState) => AlertDialog(
                                            title: const Text('Editar clase'),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  TextField(
                                                    controller: editNombre,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText: 'Nombre',
                                                        ),
                                                  ),
                                                  TextField(
                                                    controller: editMonitor,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText: 'Monitor',
                                                        ),
                                                  ),
                                                  TextField(
                                                    controller: editAforo,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText: 'Aforo',
                                                        ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      final DateTime? fecha =
                                                          await showDatePicker(
                                                            context: context,
                                                            initialDate:
                                                                editFecha ??
                                                                DateTime.now(),
                                                            firstDate: DateTime(
                                                              2020,
                                                            ),
                                                            lastDate: DateTime(
                                                              2100,
                                                            ),
                                                          );
                                                      if (fecha == null) return;

                                                      final TimeOfDay?
                                                      hora = await showTimePicker(
                                                        context: context,
                                                        initialTime:
                                                            TimeOfDay.fromDateTime(
                                                              editFecha ??
                                                                  DateTime.now(),
                                                            ),
                                                      );
                                                      if (hora == null) return;

                                                      setState(() {
                                                        editFecha = DateTime(
                                                          fecha.year,
                                                          fecha.month,
                                                          fecha.day,
                                                          hora.hour,
                                                          hora.minute,
                                                        );
                                                      });
                                                    },
                                                    child: Text(
                                                      editFecha == null
                                                          ? 'Seleccionar nueva fecha y hora'
                                                          : 'Fecha: ${editFecha!.toLocal()}',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: const Text('Cancelar'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('clases')
                                                      .doc(clase.id)
                                                      .update({
                                                        'nombre':
                                                            editNombre.text
                                                                .trim(),
                                                        'monitor':
                                                            editMonitor.text
                                                                .trim(),
                                                        'aforo':
                                                            int.tryParse(
                                                              editAforo.text
                                                                  .trim(),
                                                            ) ??
                                                            clase['aforo'],
                                                        if (editFecha != null)
                                                          'fecha':
                                                              Timestamp.fromDate(
                                                                editFecha!,
                                                              ),
                                                      });

                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Clase actualizada',
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: const Text('Guardar'),
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () => _mostrarReservas(context, clase.id),
                        onLongPress:
                            () => _mostrarListaEspera(context, clase.id),
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
