# 🏋️‍♀️ FitReserve

Aplicación móvil para la **reserva de clases dirigidas en un gimnasio**, desarrollada como proyecto de fin de ciclo del CFGS en Desarrollo de Aplicaciones Multiplataforma.

Permite a los usuarios registrarse, reservar clases, gestionar sus inscripciones y recibir feedback visual claro. Dispone de un **Panel de Administración** para la gestión de clases, reservas y usuarios.

---

## 📱 Tecnologías utilizadas

- **Flutter** (3.32.2)
- **Dart**
- **Firebase**:
  - Firestore (Base de datos en tiempo real)
  - Firebase Authentication
  - Firebase Cloud Messaging (opcional / mejora futura)
- **Android Studio** / **VS Code**

---

## ⚙️ Funcionalidades principales

### 👤 Usuario registrado:
- Registro e inicio de sesión con validación.
- Visualización de clases disponibles.
- Reserva de clase (si hay plazas).
- Cancelación de reserva.
- Gestión de clases llenas mediante **lista de espera automática**.
- Vista de sus reservas activas.

### 🛠️ Usuario administrador:
- Creación, edición y eliminación de clases.
- Visualización de reservas por clase.
- Gestión de la lista de espera.
- Eliminación de clases con borrado automático de reservas.
- Acceso a panel exclusivo tras login.

---

## 🔐 Roles y seguridad

Las reglas de Firestore y la lógica de la app controlan el acceso en función del rol (`user` o `admin`), evitando:
- Reservas duplicadas
- Acceso a datos de otros usuarios
- Acciones no permitidas vía consola o emulador

---

## 🧪 Fase de pruebas

Se ha validado mediante:
- Pruebas funcionales (caja negra)
- Pruebas no funcionales (rendimiento, carga, seguridad)
- Casos límite: clases llenas, usuarios sin conexión, intentos de acceso no autorizado

---

## 📂 Estructura del proyecto

```
lib/
├── main.dart
├── screens/
│ ├── home_screen.dart
│ ├── login_screen.dart
│ ├── register_screen.dart
│ ├── admin_panel_screen.dart
│ ├── mis_reservas_screen.dart
├── widgets/
│ ├── clase_card.dart
│ ├── reserva_card.dart
├── services/
│ ├── auth_service.dart
│ ├── firestore_service.dart
├── models/
│ ├── clase.dart
│ ├── reserva.dart
├── utils/
│ └── constants.dart

```

---

## 🚀 ¿Cómo ejecutar el proyecto?

1. Clona el repositorio:

```
git clone https://github.com/tu-usuario/fitreserve.git
cd fitreserve

```

2. Instala dependencias: `flutter pub get
   
3. Añade los archivos de Firebase:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

4. Ejecuta la app: `flutter run`

---

## Generar -apk de producción

``` 
flutter build apk --release

```

---

## 🧠 Mejoras futuras

- Integración de notificaciones push con Firebase Cloud Messaging (FCM)
- Gestión avanzada de lista de espera (orden, notificaciones)
- Versión web adaptada para escritorio

---

## 👩‍💻 Autoría
Ana Gavilán Gómez
📍 Carcaixent, Valencia
💻 Técnica Superior en Desarrollo de Aplicaciones Multiplataforma
📧 ana.gavilan.gomez@gmail.com
🔗 [LinkedIn](https://www.linkedin.com/in/aniiigo/)

---

## 🏁 Licencia
Proyecto educativo bajo licencia MIT.

