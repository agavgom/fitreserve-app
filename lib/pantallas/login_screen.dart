import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true;

  void _toggleFormMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
        
        final uid = cred.user!.uid;

        final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();

        if (!doc.exists) {
          Fluttertoast.showToast(msg: 'Error: el perfil de usuario no existe en Firestore');
          return;
        }

        final rol = doc.data()?['rol'] ?? 'usuario';
        Fluttertoast.showToast(msg: 'Bienvenido, $rol');

        if (rol == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {

        final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        final uid = cred.user!.uid;

        await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
          'email': email,
          'rol': 'usuario',
        });

        Fluttertoast.showToast(msg: 'Registro exitoso');
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error desconocido';
      switch (e.code) {
        case 'invalid-email':
          mensaje = 'Correo no válido';
          break;
        case 'user-not-found':
          mensaje = 'Usuario no encontrado';
          break;
        case 'wrong-password':
          mensaje = 'Contraseña incorrecta';
          break;
        case 'email-already-in-use':
          mensaje = 'Correo ya registrado';
          break;
        case 'weak-password':
          mensaje = 'Contraseña demasiado débil';
          break;
        default:
          mensaje = 'Error: ${e.message}';
      }
      Fluttertoast.showToast(msg: mensaje);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Iniciar Sesión' : 'Registrarse'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo electrónico'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isLogin ? 'Iniciar sesión' : 'Registrarse'),
            ),
            TextButton(
              onPressed: _toggleFormMode,
              child: Text(_isLogin
                  ? '¿No tienes cuenta? Regístrate aquí'
                  : '¿Ya tienes cuenta? Inicia sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
