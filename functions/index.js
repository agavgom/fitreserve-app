const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.moverDeListaDeEsperaAReservas = functions.firestore
    .document("clases/{claseId}")
    .onUpdate(async (change, context) => {
      const claseId = context.params.claseId;
      const nuevaClase = change.after.data();
      const aforo = nuevaClase.aforo;
      const inscritos = nuevaClase.inscritos;

      if (inscritos >= aforo) {
      // No hay plazas disponibles
        return null;
      }

      const claseRef = admin.firestore().collection("clases").doc(claseId);
      const listaEsperaRef = admin.firestore().collection("lista_espera");
      const reservasRef = admin.firestore().collection("reservas");

      const listaEsperaSnap = await listaEsperaRef
          .where("claseId", "==", claseRef)
          .orderBy("fecha") // asume que hay un campo fecha en lista de espera
          .limit(1)
          .get();

      if (listaEsperaSnap.empty) {
        console.log("No hay usuarios en lista de espera.");
        return null;
      }

      const usuario = listaEsperaSnap.docs[0];
      const usuarioId = usuario.data().usuarioId;

      // Crear nueva reserva
      await reservasRef.add({
        claseId: claseRef,
        usuarioId: usuarioId,
        fecha: admin.firestore.Timestamp.now(),
      });

      // Eliminar de lista de espera
      await listaEsperaRef.doc(usuario.id).delete();

      // Actualizar inscritos
      await claseRef.update({
        inscritos: inscritos + 1,
      });

      console.log(`Usuario ${usuarioId} pasó de lista de espera a reservas`);
      return null;
    });
