import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MisReservasScreen extends StatelessWidget {
  const MisReservasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Reservas')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservas')
            .where('usuarioId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar reservas'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reservas = snapshot.data!.docs;

          if (reservas.isEmpty) {
            return const Center(child: Text('No tienes reservas activas'));
          }

          return ListView.builder(
            itemCount: reservas.length,
            itemBuilder: (context, index) {
              final reserva = reservas[index];
              final claseRef = reserva['claseId'] as DocumentReference;

              return FutureBuilder<DocumentSnapshot>(
                future: claseRef.get(),
                builder: (context, claseSnapshot) {
                  if (!claseSnapshot.hasData) {
                    return const ListTile(title: Text('Cargando clase...'));
                  }

                  if (!claseSnapshot.data!.exists) {
                    return const ListTile(
                      title: Text('Clase eliminada'),
                      subtitle: Text('Esta reserva pertenece a una clase que ya no existe.'),
                    );
                  }

                  final clase = claseSnapshot.data!;
                  final nombre = clase['nombre'] ?? 'Sin nombre';
                  final fecha = (clase['fecha'] as Timestamp).toDate();

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(nombre),
                      subtitle: Text('Fecha: ${fecha.toLocal()}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () async {
                          // 1. Eliminar la reserva
                          await FirebaseFirestore.instance
                              .collection('reservas')
                              .doc(reserva.id)
                              .delete();

                          // 2. Decrementar inscritos en la clase
                          await claseRef.update({
                            'inscritos': (clase['inscritos'] ?? 1) - 1,
                          });

                          // 3. Ver si hay alguien en la lista de espera
                          final listaEsperaSnapshot = await FirebaseFirestore.instance
                              .collection('lista_espera')
                              .where('claseId', isEqualTo: claseRef)
                              .orderBy('fecha') // más antiguo primero
                              .limit(1)
                              .get();

                          if (listaEsperaSnapshot.docs.isNotEmpty) {
                            final primero = listaEsperaSnapshot.docs.first;
                            final usuarioId = primero['usuarioId'];

                            // 4. Crear nueva reserva para el primero en espera
                            await FirebaseFirestore.instance.collection('reservas').add({
                              'usuarioId': usuarioId,
                              'claseId': claseRef,
                              'fecha': Timestamp.now(),
                            });

                            // 5. Eliminarlo de lista_espera
                            await FirebaseFirestore.instance
                                .collection('lista_espera')
                                .doc(primero.id)
                                .delete();

                            // 6. Actualizar campo inscritos
                            await claseRef.update({
                              'inscritos': (clase['inscritos'] ?? 0) + 1,
                            });

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Plaza asignada al siguiente en lista de espera'),
                                ),
                              );
                            }
                          }

                          // 7. Mensaje de cancelación
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reserva cancelada')),
                            );
                          });
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
