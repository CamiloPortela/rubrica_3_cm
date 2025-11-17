import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream para detectar cambios en la autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Registrar nuevo usuario
  Future<Map<String, dynamic>> registrarUsuario({
    required String nombre,
    required String usuario,
    required String correo,
    required String telefono,
    required String direccion,
    required String horario,
    required String tipoUsuario,
    required String password,
  }) async {
    try {
      // Crear usuario en Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: correo,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // Guardar datos adicionales en Firestore
      await _firestore.collection('usuarios').doc(uid).set({
        'uid': uid,
        'nombre': nombre,
        'usuario': usuario,
        'correo': correo,
        'telefono': telefono,
        'direccion': direccion,
        'horario': horario,
        'tipoUsuario': tipoUsuario,
        'fechaRegistro': FieldValue.serverTimestamp(),
        'actividadesCompletadas': [],
        'huertosRegistrados': [],
      });

      return {
        'success': true,
        'message': '¡Registro exitoso como $tipoUsuario!',
        'uid': uid,
      };
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error en el registro';
      
      if (e.code == 'weak-password') {
        mensaje = 'La contraseña es muy débil';
      } else if (e.code == 'email-already-in-use') {
        mensaje = 'Este correo ya está registrado';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El correo no es válido';
      }
      
      return {
        'success': false,
        'message': mensaje,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Iniciar sesión
  Future<Map<String, dynamic>> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: correo,
        password: password,
      );

      // Obtener datos del usuario de Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        
        return {
          'success': true,
          'message': '¡Bienvenido, ${userData['nombre']}!',
          'userData': userData,
        };
      } else {
        return {
          'success': false,
          'message': 'Usuario no encontrado',
        };
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al iniciar sesión';
      
      if (e.code == 'user-not-found') {
        mensaje = 'Usuario no encontrado';
      } else if (e.code == 'wrong-password') {
        mensaje = 'Contraseña incorrecta';
      } else if (e.code == 'invalid-email') {
        mensaje = 'Correo no válido';
      } else if (e.code == 'user-disabled') {
        mensaje = 'Este usuario ha sido deshabilitado';
      }
      
      return {
        'success': false,
        'message': mensaje,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Cerrar sesión
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  // Obtener datos del usuario actual
  Future<Map<String, dynamic>?> obtenerDatosUsuario() async {
    try {
      if (currentUser != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('usuarios')
            .doc(currentUser!.uid)
            .get();

        if (userDoc.exists) {
          return userDoc.data() as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
      return null;
    }
  }

  // Verificar si hay un usuario logueado
  bool estaLogueado() {
    return currentUser != null;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login & Register',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final userController = TextEditingController();
  final passwordController = TextEditingController();
  String nombreUsuario = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Imagen de bienvenida
                Container(
                  width: 150,
                  height: 150,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/hand_wave.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 30),

                // Texto de bienvenida
                Text(
                  nombreUsuario.isEmpty ? 'Hola' : 'Hola, $nombreUsuario',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Inicia sesión para continuar',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 40),

                // Campo Usuario
                TextField(
                  controller: userController,
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo Contraseña
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Botón Olvidé contraseña
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Recuperar Contraseña'),
                          content: const Text(
                            'Función de recuperación de contraseña en desarrollo.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Login
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (userController.text.isNotEmpty &&
                          passwordController.text.isNotEmpty) {
                        setState(() {
                          nombreUsuario = userController.text;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Bienvenido, ${userController.text}!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Por favor completa todos los campos',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'O',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                  ],
                ),
                const SizedBox(height: 24),

                // Botón Registro
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.blue.shade700, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Crear Cuenta Nueva',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    userController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nombreController = TextEditingController();
  final userController = TextEditingController();
  final telefonoController = TextEditingController();
  final direccionController = TextEditingController();
  final passwordController = TextEditingController();
  String horarioSeleccionado = '6:00 - 9:00';

  final List<String> horarios = [
    '6:00 - 9:00',
    '10:00 - 13:00',
    '14:00 - 17:00',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Imagen de bienvenida
                Container(
                  width: 120,
                  height: 120,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Image.asset('assets/mano.png', fit: BoxFit.contain),
                ),
                const SizedBox(height: 20),

                // Texto de bienvenida
                const Text(
                  'Hola',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea tu cuenta para comenzar',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 30),

                // Campo Nombre
                TextField(
                  controller: nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo Usuario
                TextField(
                  controller: userController,
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: const Icon(Icons.account_circle),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo Teléfono
                TextField(
                  controller: telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo Dirección
                TextField(
                  controller: direccionController,
                  decoration: InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Dropdown Horario de disponibilidad
                DropdownButtonFormField<String>(
                  value: horarioSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Horario de disponibilidad',
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: horarios.map((String horario) {
                    return DropdownMenuItem<String>(
                      value: horario,
                      child: Text(horario),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      horarioSeleccionado = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Campo Contraseña
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Registrarse
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nombreController.text.isNotEmpty &&
                          userController.text.isNotEmpty &&
                          telefonoController.text.isNotEmpty &&
                          direccionController.text.isNotEmpty &&
                          passwordController.text.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '¡Registro exitoso! Ahora puedes iniciar sesión',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Por favor completa todos los campos',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Registrarse',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Botón ¿Ya tienes cuenta?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes cuenta? ',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Inicia Sesión',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    userController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
