import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DetalleClaseScreen extends StatelessWidget {
  const DetalleClaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final claseId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de la clase')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('clases').doc(claseId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Error al cargar los datos de la clase'));
          }

          final clase = snapshot.data!;
          final nombre = clase['nombre'] ?? 'Sin nombre';
          final monitor = clase['monitor'] ?? 'Sin monitor';
          final descripcion = clase.data().toString().contains('descripcion')
              ? clase['descripcion']
              : 'Sin descripción';
          final aforo = clase['aforo'] ?? 0;
          final inscritos = clase['inscritos'] ?? 0;
          final fecha = (clase['fecha'] as Timestamp).toDate();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text('Monitor: $monitor'),
                const SizedBox(height: 10),
                Text('Fecha: ${fecha.toLocal()}'),
                const SizedBox(height: 10),
                Text('Descripción:\n$descripcion'),
                const SizedBox(height: 10),
                Text('Aforo: $inscritos / $aforo'),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Usuario no autenticado')),
                        );
                        return;
                      }

                      final claseRef =
                          FirebaseFirestore.instance.collection('clases').doc(claseId);

                      // Verificar si ya existe una reserva de este usuario para esta clase
                      final reservaExistente = await FirebaseFirestore.instance
                          .collection('reservas')
                          .where('usuarioId', isEqualTo: uid)
                          .where('claseId', isEqualTo: claseRef)
                          .get();

                      if (reservaExistente.docs.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ya tienes una reserva para esta clase')),
                        );
                        return;
                      }

                      if (inscritos < aforo) {
                        await FirebaseFirestore.instance.collection('reservas').add({
                          'usuarioId': uid,
                          'claseId': claseRef,
                          'fecha': Timestamp.now(),
                        });

                        await claseRef.update({'inscritos': inscritos + 1});

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reserva confirmada')),
                        );
                      } else {
                        await FirebaseFirestore.instance.collection('lista_espera').add({
                          'usuarioId': uid,
                          'claseId': claseRef,
                          'fecha': Timestamp.now(),
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Clase llena. Añadido a la lista de espera')),
                        );
                      }
                    },
                    child: const Text('Reservar clase'),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
