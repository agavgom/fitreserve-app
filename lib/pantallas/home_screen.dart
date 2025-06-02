import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String filtroClase = '';
  String filtroMonitor = '';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clases disponibles'),
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
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Mis Reservas',
            onPressed: () {
              Navigator.pushNamed(context, '/mis_reservas');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Filtrar por clase',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  filtroClase = value.toLowerCase();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Filtrar por monitor',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  filtroMonitor = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clases')
                  .orderBy('fecha')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar clases'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final clases = snapshot.data!.docs;

                final clasesFiltradas = clases.where((doc) {
                  final nombre = doc['nombre'].toString().toLowerCase();
                  final monitor = doc['monitor'].toString().toLowerCase();
                  return nombre.contains(filtroClase) &&
                      monitor.contains(filtroMonitor);
                }).toList();

                if (clasesFiltradas.isEmpty) {
                  return const Center(child: Text('No hay clases disponibles'));
                }

                return ListView.builder(
                  itemCount: clasesFiltradas.length,
                  itemBuilder: (context, index) {
                    final clase = clasesFiltradas[index];
                    final nombre = clase['nombre'];
                    final monitor = clase['monitor'];
                    final aforo = clase['aforo'];
                    final inscritos = clase['inscritos'];
                    final fecha = (clase['fecha'] as Timestamp).toDate();

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(nombre),
                        subtitle: Text(
                            'Monitor: $monitor\nFecha: ${fecha.toLocal()}\nAforo: $inscritos / $aforo'),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/detalle',
                            arguments: clase.id,
                          );
                        },
                        trailing: ElevatedButton(
                          onPressed: () async {
                            if (uid == null) return;

                            final claseRef = FirebaseFirestore.instance
                                .collection('clases')
                                .doc(clase.id);

                            // Comprobar si ya tiene reserva
                            final existingReservation = await FirebaseFirestore
                                .instance
                                .collection('reservas')
                                .where('usuarioId', isEqualTo: uid)
                                .where('claseId', isEqualTo: claseRef)
                                .get();

                            if (existingReservation.docs.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Ya estás apuntada')),
                              );
                              return;
                            }

                            if (inscritos < aforo) {
                              // Reservar plaza
                              await FirebaseFirestore.instance
                                  .collection('reservas')
                                  .add({
                                'usuarioId': uid,
                                'claseId': claseRef,
                                'fecha': Timestamp.now(),
                              });

                              await claseRef.update({
                                'inscritos': inscritos + 1,
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Reserva confirmada')),
                              );
                            } else {
                              // Añadir a lista de espera
                              await FirebaseFirestore.instance
                                  .collection('lista_espera')
                                  .add({
                                'usuarioId': uid,
                                'claseId': claseRef,
                                'fecha': Timestamp.now(),
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Clase llena. Añadida a lista de espera')),
                              );
                            }
                          },
                          child: const Text('Reservar'),
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
    );
  }
}

