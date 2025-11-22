import 'package:flutter_localizations/flutter_localizations.dart'
    as localizations;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: correo, password: password);

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

      return {'success': false, 'message': mensaje};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  //Iniciar sesión
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
        return {'success': false, 'message': 'Usuario no encontrado'};
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

      return {'success': false, 'message': mensaje};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  //Cerrar sesión
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  //Obtener datos del usuario actual
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

  //Verificar si hay un usuario logueado
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
      title: 'Greenhand App',
      theme: ThemeData(primarySwatch: Colors.red),

      //Para arreglar date picker que no funciona
      localizationsDelegates: [
        localizations.GlobalMaterialLocalizations.delegate,
        localizations.GlobalWidgetsLocalizations.delegate,
        localizations.GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés
      ],
      locale: const Locale('es', 'ES'), //español por defecto

      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              //Logo principal
              Container(
                width: 200,
                height: 200,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/hand_png.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),

              // Título
              const Text(
                'Greenhand App',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              //Descripción
              Text(
                'Cultiva, colabora y aprende\ncon tu comunidad',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              //Botón Iniciar Sesión
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              //Botón Registrarse
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
                    side: BorderSide(color: Colors.green.shade700, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Registrarse',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 1),

              //Versión de la app
              Text(
                'Versión 1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService(); // NUEVO
  final correoController =
      TextEditingController(); // CAMBIADO de userController
  final passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false; // NUEVO

  // NUEVO - Método para iniciar sesión
  Future<void> _iniciarSesion() async {
    String correo = correoController.text.trim();
    String password = passwordController.text.trim();

    if (correo.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!correo.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un correo válido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar loading
    setState(() {
      _isLoading = true;
    });

    // Iniciar sesión en Firebase
    Map<String, dynamic> resultado = await _authService.iniciarSesion(
      correo: correo,
      password: password,
    );

    setState(() {
      _isLoading = false;
    });

    // Mostrar resultado
    if (resultado['success']) {
      // Navegar a la pantalla principal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userData: resultado['userData']),
        ),
      );
    } else {
      print('Error en login: ${resultado['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message']),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

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

                //Imagen de bienvenida
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
                    'assets/images/hand_png.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 30),

                //Texto de bienvenida
                const Text(
                  '¡Bienvenido!',
                  style: TextStyle(
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

                //Campo Correo
                TextField(
                  controller: correoController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    hintText: 'Ingresa tu correo',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.green.shade700,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                //Campo contraseña con botón ocultar
                TextField(
                  controller: passwordController,
                  enabled: !_isLoading,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    hintText: 'Ingresa tu contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.green.shade700,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                //Botón lvidé contraseña
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Recuperar Contraseña'),
                                content: const Text(
                                  'Aún trabajamos en la recuperación de contraseña.',
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
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Login con loading
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _iniciarSesion, // MODIFICADO
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
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
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.green.shade700, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Crear Cuenta Nueva',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
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
    correoController.dispose();
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
  final AuthService _authService = AuthService(); // NUEVO
  final nombreController = TextEditingController();
  final userController = TextEditingController();
  final correoController = TextEditingController();
  final telefonoController = TextEditingController();
  final direccionController = TextEditingController();
  final passwordController = TextEditingController();

  String horarioSeleccionado = '6:00 - 9:00';
  String tipoUsuario = 'Voluntario';
  bool _isLoading = false;

  final List<String> horarios = [
    '6:00 - 9:00',
    '10:00 - 13:00',
    '14:00 - 17:00',
  ];

  final List<String> tiposUsuario = ['Voluntario', 'Administrador'];

  //Método para registrar usuario
  Future<void> _registrarUsuario() async {
    // Validación de campos vacíos
    if (nombreController.text.isEmpty ||
        userController.text.isEmpty ||
        correoController.text.isEmpty ||
        telefonoController.text.isEmpty ||
        direccionController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    //Validación básica de correo
    if (!correoController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un correo válido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    //Validación de contraseña
    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 6 caracteres'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar loading
    setState(() {
      _isLoading = true;
    });

    //Registrar en Firebase
    Map<String, dynamic> resultado = await _authService.registrarUsuario(
      nombre: nombreController.text.trim(),
      usuario: userController.text.trim(),
      correo: correoController.text.trim(),
      telefono: telefonoController.text.trim(),
      direccion: direccionController.text.trim(),
      horario: horarioSeleccionado,
      tipoUsuario: tipoUsuario,
      password: passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    //Mostrar resultado
    if (resultado['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message']),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      //Volver al login
      Navigator.pop(context);
    } else {
      //Imprimir en consola para debug
      print('Error detallado: ${resultado['message']}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['message']),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                //Imagen de bienvenida
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
                  child: Image.asset(
                    'assets/images/hand_png.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),

                //Texto de bienvenida
                const Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Completa el formulario para comenzar',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 30),

                //Campo Nombre
                TextField(
                  controller: nombreController,
                  enabled: !_isLoading, // NUEVO
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                //Campo Usuario
                TextField(
                  controller: userController,
                  enabled: !_isLoading, // NUEVO
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: const Icon(Icons.account_circle),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                //Campo correo
                TextField(
                  controller: correoController,
                  enabled: !_isLoading, // NUEVO
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                //Campo teléfono
                TextField(
                  controller: telefonoController,
                  enabled: !_isLoading, // NUEVO
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

                //Campo dirección
                TextField(
                  controller: direccionController,
                  enabled: !_isLoading, // NUEVO
                  decoration: InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                //Dropdown Horario de disponibilidad
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
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          // NUEVO
                          setState(() {
                            horarioSeleccionado = value!;
                          });
                        },
                ),
                const SizedBox(height: 16),

                //Dropdown tipo de usuario
                DropdownButtonFormField<String>(
                  value: tipoUsuario,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Usuario',
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: tiposUsuario.map((String tipo) {
                    return DropdownMenuItem<String>(
                      value: tipo,
                      child: Text(tipo),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          // NUEVO
                          setState(() {
                            tipoUsuario = value!;
                          });
                        },
                ),
                const SizedBox(height: 16),

                //Campo contraseña
                TextField(
                  controller: passwordController,
                  enabled: !_isLoading, // NUEVO
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

                //Botón registrarse con loading
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _registrarUsuario, // MODIFICADO
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading // NUEVO - Mostrar loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
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

                //Botón ¿Ya tienes cuenta?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes cuenta? ',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              // NUEVO
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
    correoController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

//Pantalla estadísticas
class EstadisticasScreen extends StatelessWidget {
  const EstadisticasScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text(
          'Estadísticas',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Text('Pantalla de Estadísticas - En construcción'),
      ),
    );
  }
}

//Pantalla educación
class EducacionScreen extends StatelessWidget {
  const EducacionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Educación', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Text('Pantalla de Educación - En construcción'),
      ),
    );
  }
}

//Pantalla perfil
class PerfilScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const PerfilScreen({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String nombre = userData['nombre'] ?? 'Usuario';
    String usuario = userData['usuario'] ?? 'usuario';
    String correo = userData['correo'] ?? 'No especificado';
    String telefono = userData['telefono'] ?? 'No especificado';
    String direccion = userData['direccion'] ?? 'No especificada';
    String horario = userData['horario'] ?? 'No especificado';
    String tipoUsuario = userData['tipoUsuario'] ?? 'Voluntario';

    // Obtener actividades completadas (por ahora de Firebase o lista vacía)
    List actividadesCompletadas = userData['actividadesCompletadas'] ?? [];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mi Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              // TODO: Implementar edición de perfil
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de edición en desarrollo'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con degradado
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade500],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  //Imagen de perfil
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nombre
                  Text(
                    nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Usuario
                  Text(
                    '@$usuario',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  // Badge tipo de usuario
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tipoUsuario == 'Administrador'
                              ? Icons.admin_panel_settings
                              : Icons.volunteer_activism,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tipoUsuario,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),

            // Contenido del perfil
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección: Estadísticas rápidas
                  const Text(
                    'Mis Estadísticas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  //Cards de estadísticas
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          Icons.task_alt,
                          '${actividadesCompletadas.length}',
                          'Actividades\nCompletadas',
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          Icons.eco,
                          '${(userData['huertosRegistrados'] ?? []).length}',
                          tipoUsuario == 'Administrador'
                              ? 'Huertos\nCreados'
                              : 'Huertos\nRegistrados',
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Sección: Información Personal
                  const Text(
                    'Información Personal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card de información
                  _buildInfoCard([
                    _buildInfoRow(Icons.email, 'Correo', correo),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.phone, 'Teléfono', telefono),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.location_on, 'Dirección', direccion),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.access_time,
                      'Horario disponible',
                      horario,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Sección: Descripción
                  const Text(
                    'Acerca de mí',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card de descripción
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      tipoUsuario == 'Administrador'
                          ? 'Como administrador, gestiono y organizo los huertos comunitarios, asigno tareas y coordino las actividades de los voluntarios.'
                          : 'Como voluntario, participo activamente en las labores de los huertos comunitarios, contribuyendo al desarrollo sostenible de mi comunidad.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sección: Historial de Actividades
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Historial de Actividades',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (actividadesCompletadas.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            // TODO: Ver todas las actividades
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ver todas las actividades'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Text(
                            'Ver todas',
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Lista de actividades o mensaje vacío
                  actividadesCompletadas.isEmpty
                      ? _buildEmptyActivities()
                      : _buildActivityList(actividadesCompletadas),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para cuando no hay actividades
  Widget _buildEmptyActivities() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin actividades completadas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Regístrate en actividades para\ncomenzar tu historial',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para lista de actividades
  Widget _buildActivityList(List actividades) {
    return Column(
      children: List.generate(
        actividades.length > 3 ? 3 : actividades.length, // Mostrar máximo 3
        (index) {
          var actividad = actividades[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildActivityCard(
              actividad['titulo'] ?? 'Actividad',
              actividad['fecha'] ?? 'Sin fecha',
              actividad['huerto'] ?? 'Huerto desconocido',
              _getActivityIcon(actividad['tipo'] ?? 'general'),
              _getActivityColor(actividad['tipo'] ?? 'general'),
            ),
          );
        },
      ),
    );
  }

  // Widget para tarjeta de actividad
  Widget _buildActivityCard(
    String titulo,
    String fecha,
    String huerto,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  huerto,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  fecha,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
        ],
      ),
    );
  }

  // Helper para obtener ícono según tipo de actividad
  IconData _getActivityIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'riego':
        return Icons.water_drop;
      case 'siembra':
        return Icons.eco;
      case 'poda':
        return Icons.content_cut;
      case 'limpieza':
        return Icons.cleaning_services;
      case 'cosecha':
        return Icons.agriculture;
      default:
        return Icons.task_alt;
    }
  }

  // Helper para obtener color según tipo de actividad
  Color _getActivityColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'riego':
        return Colors.blue;
      case 'siembra':
        return Colors.green;
      case 'poda':
        return Colors.orange;
      case 'limpieza':
        return Colors.purple;
      case 'cosecha':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  // Widget helper para card de información
  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // Widget helper para fila de información
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.green.shade700, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget helper para card de estadística
  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

//Pantalla huertos
class HuertosScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HuertosScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<HuertosScreen> createState() => _HuertosScreenState();
}

class _HuertosScreenState extends State<HuertosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _misHuertos = [];

  @override
  void initState() {
    super.initState();
    _cargarHuertos();
  }

  Future<void> _cargarHuertos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String tipoUsuario = widget.userData['tipoUsuario'] ?? 'Voluntario';
      String uid = widget.userData['uid'];

      if (tipoUsuario == 'Administrador') {
        // Cargar huertos creados por el administrador
        QuerySnapshot snapshot = await _firestore
            .collection('huertos')
            .where('creadorId', isEqualTo: uid)
            .orderBy('fechaCreacion', descending: true)
            .get();

        _misHuertos = snapshot.docs
            .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
            .toList();
      } else {
        // Cargar huertos en los que está registrado el voluntario
        DocumentSnapshot userDoc = await _firestore
            .collection('usuarios')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          List<dynamic> huertosIds = userData['huertosRegistrados'] ?? [];

          List<Map<String, dynamic>> huertosList = [];

          for (String huertoId in huertosIds) {
            DocumentSnapshot huertoDoc = await _firestore
                .collection('huertos')
                .doc(huertoId)
                .get();

            if (huertoDoc.exists) {
              Map<String, dynamic> huertoData =
                  huertoDoc.data() as Map<String, dynamic>;
              huertoData['id'] = huertoDoc.id;
              huertosList.add(huertoData);
            }
          }

          _misHuertos = huertosList;
        }
      }
    } catch (e) {
      print('Error al cargar huertos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar huertos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    String tipoUsuario = widget.userData['tipoUsuario'] ?? 'Voluntario';
    bool esAdmin = tipoUsuario == 'Administrador';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          esAdmin ? 'Mis Huertos' : 'Huertos',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : esAdmin
          ? _buildAdminView()
          : _buildVoluntarioView(),
    );
  }

  // Vista para Administradores
  Widget _buildAdminView() {
    return RefreshIndicator(
      onRefresh: _cargarHuertos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Imagen de personaje
              Center(
                child: Container(
                  width: 120,
                  height: 120,
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
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/apple_png.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              //Botón crear huerto
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    //Navegar al formulario de creación
                    final resultado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CrearHuertoScreen(userData: widget.userData),
                      ),
                    );

                    // Si se creó un huerto, recargar la lista
                    if (resultado == true) {
                      _cargarHuertos();
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Crear Nuevo Huerto',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Título de la lista
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mis Huertos Creados',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (_misHuertos.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_misHuertos.length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Lista de huertos o mensaje vacío
              _misHuertos.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: _misHuertos.map((huerto) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildHuertoCard(huerto),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Vista para Voluntarios
  Widget _buildVoluntarioView() {
    return RefreshIndicator(
      onRefresh: _cargarHuertos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen de personaje
              Center(
                child: Container(
                  width: 120,
                  height: 120,
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
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/apple_png.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Botón Buscar Huertos
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Navegar a búsqueda de huertos
                    final resultado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BuscarHuertosScreen(userData: widget.userData),
                      ),
                    );

                    // Si hubo cambios (se registró en un huerto), recargar lista
                    if (resultado == true) {
                      _cargarHuertos();
                    }
                  },
                  icon: const Icon(Icons.search, color: Colors.white),
                  label: const Text(
                    'Buscar Huertos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Título
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mis Huertos',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (_misHuertos.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_misHuertos.length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Lista de huertos o mensaje vacío
              _misHuertos.isEmpty
                  ? _buildEmptyStateVoluntario()
                  : Column(
                      children: _misHuertos.map((huerto) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildHuertoCardVoluntario(huerto),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para estado vacío (Voluntario)
  Widget _buildEmptyStateVoluntario() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.park_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'No estás registrado en ningún huerto',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Busca huertos disponibles\ny únete para colaborar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para card de huerto (vista Voluntario)
  Widget _buildHuertoCardVoluntario(Map<String, dynamic> huerto) {
    String nombre = huerto['nombre'] ?? 'Sin nombre';
    String tipoCultivo = huerto['tipoCultivo'] ?? 'No especificado';
    String tamano = huerto['tamaño'] ?? 'No especificado';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.grass, color: Colors.green.shade700, size: 30),
        ),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Tipo: $tipoCultivo',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            Text(
              'Tamaño: $tamano',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey.shade400,
          size: 16,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleHuertoVoluntarioScreen(
                huertoData: huerto,
                userData: widget.userData,
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget para estado vacío
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.park_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'Aún no has creado huertos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Crea tu primer huerto para comenzar\na gestionar actividades',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para card de huerto
  Widget _buildHuertoCard(Map<String, dynamic> huerto) {
    String nombre = huerto['nombre'] ?? 'Sin nombre';
    String tamano = huerto['tamaño'] ?? 'No especificado';
    String tipoCultivo = huerto['tipoCultivo'] ?? 'No especificado';
    String estado = huerto['estado'] ?? 'activo';
    int numVoluntarios = (huerto['voluntarios'] ?? []).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$numVoluntarios voluntarios',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estado.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Información del huerto
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(Icons.straighten, 'Tamaño', tamano),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.grass,
                        'Cultivo',
                        tipoCultivo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        //Ver detalles del huerto
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalleHuertoScreen(
                                huertoData: huerto,
                                userData: widget.userData,
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.visibility,
                          size: 18,
                          color: Colors.green.shade700,
                        ),
                        label: Text(
                          'Ver Detalles',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.green.shade700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          //Gestionar huerto
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalleHuertoScreen(
                                huertoData: huerto,
                                userData: widget.userData,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.settings,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Gestionar',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper para items de información
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.green.shade700),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// Pantalla de búsqueda de huertos
class BuscarHuertosScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const BuscarHuertosScreen({Key? key, required this.userData})
    : super(key: key);

  @override
  State<BuscarHuertosScreen> createState() => _BuscarHuertosScreenState();
}

class _BuscarHuertosScreenState extends State<BuscarHuertosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _todosLosHuertos = [];
  List<Map<String, dynamic>> _huertosFiltrados = [];
  List<String> _misHuertosIds = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _cargarHuertos();
  }

  // Cargar todos los huertos disponibles
  Future<void> _cargarHuertos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String uid = widget.userData['uid'];

      // Obtener IDs de huertos donde ya está registrado el voluntario
      DocumentSnapshot userDoc = await _firestore
          .collection('usuarios')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        _misHuertosIds = List<String>.from(
          userData['huertosRegistrados'] ?? [],
        );
      }

      // Obtener todos los huertos activos
      QuerySnapshot snapshot = await _firestore
          .collection('huertos')
          .where('estado', isEqualTo: 'activo')
          .get();

      _todosLosHuertos = snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();

      _huertosFiltrados = _todosLosHuertos;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar huertos: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar huertos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Filtrar huertos por búsqueda
  void _filtrarHuertos(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;

      if (query.isEmpty) {
        _huertosFiltrados = _todosLosHuertos;
      } else {
        _huertosFiltrados = _todosLosHuertos.where((huerto) {
          String nombre = (huerto['nombre'] ?? '').toLowerCase();
          String direccion = (huerto['direccion'] ?? '').toLowerCase();
          String busqueda = query.toLowerCase();

          return nombre.contains(busqueda) || direccion.contains(busqueda);
        }).toList();
      }
    });
  }

  // Registrarse en un huerto
  Future<void> _registrarseEnHuerto(Map<String, dynamic> huerto) async {
    // Mostrar diálogo de confirmación
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar registro'),
        content: Text(
          '¿Deseas registrarte en el huerto "${huerto['nombre']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String uid = widget.userData['uid'];
      String huertoId = huerto['id'];

      // Agregar huerto a la lista del usuario
      await _firestore.collection('usuarios').doc(uid).update({
        'huertosRegistrados': FieldValue.arrayUnion([huertoId]),
      });

      // Agregar usuario a la lista de voluntarios del huerto
      await _firestore.collection('huertos').doc(huertoId).update({
        'voluntarios': FieldValue.arrayUnion([uid]),
      });

      // Cerrar loading
      Navigator.pop(context);

      // Mostrar éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Te has registrado en ${huerto['nombre']}!'),
          backgroundColor: Colors.green,
        ),
      );

      // Actualizar lista
      _cargarHuertos();
    } catch (e) {
      // Cerrar loading
      Navigator.pop(context);

      print('Error al registrarse: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrarse: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () =>
              Navigator.pop(context, true), // true indica que hubo cambios
        ),
        title: const Text(
          'Buscar Huertos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            color: Colors.green.shade700,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filtrarHuertos,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o zona...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                          _filtrarHuertos('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Lista de resultados
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _huertosFiltrados.isEmpty
                ? _buildEmptyResults()
                : RefreshIndicator(
                    onRefresh: _cargarHuertos,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _huertosFiltrados.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> huerto = _huertosFiltrados[index];
                        bool yaRegistrado = _misHuertosIds.contains(
                          huerto['id'],
                        );
                        return _buildHuertoCard(huerto, yaRegistrado);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Widget para resultados vacíos
  Widget _buildEmptyResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSearching ? Icons.search_off : Icons.eco_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching
                  ? 'No se encontraron huertos'
                  : 'No hay huertos disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching ? 'Intenta con otra búsqueda' : 'Vuelve más tarde',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para card de huerto
  Widget _buildHuertoCard(Map<String, dynamic> huerto, bool yaRegistrado) {
    String nombre = huerto['nombre'] ?? 'Sin nombre';
    String tamano = huerto['tamaño'] ?? 'No especificado';
    String tipoCultivo = huerto['tipoCultivo'] ?? 'No especificado';
    String direccion = huerto['direccion'] ?? 'No especificada';
    int maxVoluntarios = huerto['maxVoluntarios'] ?? 999;
    int numVoluntarios = (huerto['voluntarios'] ?? []).length;
    bool aceptaVoluntarios = numVoluntarios < maxVoluntarios;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del card con imagen
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.eco,
                size: 60,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),

          // Información del huerto
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre y estado
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (yaRegistrado)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'REGISTRADO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Información
                _buildInfoRow(Icons.location_on, direccion),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.grass, 'Tipo: $tipoCultivo'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.straighten, 'Tamaño: $tamano'),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.people,
                  'Voluntarios: $numVoluntarios${maxVoluntarios < 999 ? '/$maxVoluntarios' : ''}',
                ),
                const SizedBox(height: 16),

                // Indicador de disponibilidad
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: aceptaVoluntarios
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: aceptaVoluntarios
                          ? Colors.green.shade200
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        aceptaVoluntarios ? Icons.check_circle : Icons.info,
                        size: 16,
                        color: aceptaVoluntarios
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        aceptaVoluntarios
                            ? 'Cupos disponibles'
                            : 'Cupo completo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: aceptaVoluntarios
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Botón de acción
                SizedBox(
                  width: double.infinity,
                  child: yaRegistrado
                      ? OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Ya estás registrado'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: aceptaVoluntarios
                              ? () => _registrarseEnHuerto(huerto)
                              : null,
                          icon: const Icon(
                            Icons.add,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: Text(
                            aceptaVoluntarios ? 'Registrarse' : 'Cupo lleno',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper para filas de información
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Pantalla de detalle de huerto para Voluntario
class DetalleHuertoVoluntarioScreen extends StatefulWidget {
  final Map<String, dynamic> huertoData;
  final Map<String, dynamic> userData;

  const DetalleHuertoVoluntarioScreen({
    Key? key,
    required this.huertoData,
    required this.userData,
  }) : super(key: key);

  @override
  State<DetalleHuertoVoluntarioScreen> createState() =>
      _DetalleHuertoVoluntarioScreenState();
}

class _DetalleHuertoVoluntarioScreenState
    extends State<DetalleHuertoVoluntarioScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _voluntarios = [];
  List<Map<String, dynamic>> _actividades = [];
  bool _isLoadingVoluntarios = true;
  bool _isLoadingActividades = true;
  int _selectedTab = 0; // 0: Info, 1: Voluntarios, 2: Actividades

  @override
  void initState() {
    super.initState();
    _cargarVoluntarios();
    _cargarActividades();
  }

  // Cargar lista de voluntarios del huerto
  Future<void> _cargarVoluntarios() async {
    setState(() {
      _isLoadingVoluntarios = true;
    });

    try {
      List<dynamic> voluntariosIds = widget.huertoData['voluntarios'] ?? [];
      List<Map<String, dynamic>> voluntariosList = [];

      for (String uid in voluntariosIds) {
        DocumentSnapshot userDoc = await _firestore
            .collection('usuarios')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          userData['uid'] = uid;
          voluntariosList.add(userData);
        }
      }

      setState(() {
        _voluntarios = voluntariosList;
        _isLoadingVoluntarios = false;
      });
    } catch (e) {
      print('Error al cargar voluntarios: $e');
      setState(() {
        _isLoadingVoluntarios = false;
      });
    }
  }

  // Cargar actividades del huerto
  Future<void> _cargarActividades() async {
    setState(() {
      _isLoadingActividades = true;
    });

    try {
      String huertoId = widget.huertoData['id'];

      QuerySnapshot snapshot = await _firestore
          .collection('actividades')
          .where('huertoId', isEqualTo: huertoId)
          .orderBy('fecha', descending: false)
          .get();

      _actividades = snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();

      setState(() {
        _isLoadingActividades = false;
      });
    } catch (e) {
      print('Error al cargar actividades: $e');
      setState(() {
        _isLoadingActividades = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String nombre = widget.huertoData['nombre'] ?? 'Sin nombre';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          nombre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTab(0, Icons.info, 'Información'),
                _buildTab(1, Icons.people, 'Voluntarios'),
                _buildTab(2, Icons.assignment, 'Actividades'),
              ],
            ),
          ),

          // Contenido según tab seleccionado
          Expanded(
            child: _selectedTab == 0
                ? _buildInfoTab()
                : _selectedTab == 1
                ? _buildVoluntariosTab()
                : _buildActividadesTab(),
          ),
        ],
      ),
    );
  }

  // Widget para cada tab
  Widget _buildTab(int index, IconData icon, String label) {
    bool isSelected = _selectedTab == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.green.shade700 : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.green.shade700
                    : Colors.grey.shade500,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tab de información del huerto
  Widget _buildInfoTab() {
    String nombre = widget.huertoData['nombre'] ?? 'Sin nombre';
    String tamano = widget.huertoData['tamaño'] ?? 'No especificado';
    String tipoCultivo = widget.huertoData['tipoCultivo'] ?? 'No especificado';
    String estado = widget.huertoData['estado'] ?? 'activo';
    String direccion = widget.huertoData['direccion'] ?? 'No especificada';
    String descripcion = widget.huertoData['descripcion'] ?? 'Sin descripción';
    int numVoluntarios = (widget.huertoData['voluntarios'] ?? []).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del huerto
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                Icons.eco,
                size: 100,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Información principal
          _buildInfoSection('Información General', [
            _buildInfoItem('Nombre', nombre, Icons.eco),
            _buildInfoItem('Tamaño', tamano, Icons.straighten),
            _buildInfoItem('Tipo de cultivo', tipoCultivo, Icons.grass),
            _buildInfoItem(
              'Estado',
              estado.toUpperCase(),
              Icons.info,
              statusColor: estado == 'activo' ? Colors.green : Colors.orange,
            ),
            _buildInfoItem(
              'Voluntarios',
              '$numVoluntarios personas',
              Icons.people,
            ),
          ]),
          const SizedBox(height: 24),

          // Ubicación
          _buildInfoSection('Ubicación', [
            _buildInfoItem('Dirección', direccion, Icons.location_on),
          ]),
          const SizedBox(height: 24),

          // Descripción
          _buildInfoSection('Descripción', [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                descripcion,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // Tab de voluntarios
  Widget _buildVoluntariosTab() {
    if (_isLoadingVoluntarios) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_voluntarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay voluntarios registrados',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarVoluntarios,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _voluntarios.length,
        itemBuilder: (context, index) {
          Map<String, dynamic> voluntario = _voluntarios[index];
          return _buildVoluntarioCard(voluntario);
        },
      ),
    );
  }

  // Tab de actividades
  Widget _buildActividadesTab() {
    if (_isLoadingActividades) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_actividades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay actividades disponibles',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'El administrador publicará actividades próximamente',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarActividades,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _actividades.length,
        itemBuilder: (context, index) {
          Map<String, dynamic> actividad = _actividades[index];
          return _buildActividadCard(actividad);
        },
      ),
    );
  }

  // Widget para sección de información
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // Widget para item de información
  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon, {
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (statusColor ?? Colors.green.shade700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: statusColor ?? Colors.green.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget para card de voluntario
  Widget _buildVoluntarioCard(Map<String, dynamic> voluntario) {
    String nombre = voluntario['nombre'] ?? 'Sin nombre';
    String correo = voluntario['correo'] ?? '';
    String telefono = voluntario['telefono'] ?? '';
    bool esYo = voluntario['uid'] == widget.userData['uid'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: esYo
            ? Border.all(color: Colors.green.shade700, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.green.shade100,
            child: Icon(Icons.person, color: Colors.green.shade700, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (esYo)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'TÚ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                if (correo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    correo,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
                if (telefono.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    telefono,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget para card de actividad
  Widget _buildActividadCard(Map<String, dynamic> actividad) {
    String tipo = actividad['tipo'] ?? 'Sin tipo';
    String descripcion = actividad['descripcion'] ?? 'Sin descripción';

    // Mapeo de iconos según tipo de actividad
    IconData icono;
    Color color;

    switch (tipo.toLowerCase()) {
      case 'siembra':
        icono = Icons.grass;
        color = Colors.green;
        break;
      case 'riego':
        icono = Icons.water_drop;
        color = Colors.blue;
        break;
      case 'poda':
        icono = Icons.content_cut;
        color = Colors.orange;
        break;
      case 'limpieza':
        icono = Icons.cleaning_services;
        color = Colors.purple;
        break;
      case 'cosecha':
        icono = Icons.shopping_basket;
        color = Colors.amber;
        break;
      default:
        icono = Icons.assignment;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, color: color, size: 28),
        ),
        title: Text(
          tipo,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          descripcion,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleActividadScreen(
                actividadData: actividad,
                userData: widget.userData,
                huertoData: widget.huertoData,
              ),
            ),
          );

          // Si se registró, recargar actividades
          if (resultado == true) {
            _cargarActividades();
          }
        },
      ),
    );
  }
}

// Pantalla de detalle de actividad para registrarse
class DetalleActividadScreen extends StatefulWidget {
  final Map<String, dynamic> actividadData;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> huertoData;

  const DetalleActividadScreen({
    Key? key,
    required this.actividadData,
    required this.userData,
    required this.huertoData,
  }) : super(key: key);

  @override
  State<DetalleActividadScreen> createState() => _DetalleActividadScreenState();
}

class _DetalleActividadScreenState extends State<DetalleActividadScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _horasController = TextEditingController();

  bool _yaRegistrado = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verificarRegistro();
  }

  // Verificar si el usuario ya está registrado en esta actividad
  Future<void> _verificarRegistro() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String uid = widget.userData['uid'];
      List<dynamic> participantes = widget.actividadData['participantes'] ?? [];

      _yaRegistrado = participantes.any((p) => p['uid'] == uid);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error al verificar registro: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Registrarse en la actividad
  Future<void> _registrarseEnActividad() async {
    String horas = _horasController.text.trim();

    // Validar horas
    if (horas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa las horas de trabajo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    double? horasNum = double.tryParse(horas);
    if (horasNum == null || horasNum <= 0 || horasNum > 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un número válido de horas (1-24)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Confirmar registro
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar registro'),
        content: Text(
          '¿Deseas registrarte en esta actividad con $horas horas de trabajo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String uid = widget.userData['uid'];
      String actividadId = widget.actividadData['id'];
      String nombreUsuario = widget.userData['nombre'] ?? 'Voluntario';
      String tipoActividad = widget.actividadData['tipo'] ?? 'Actividad';

      // Crear objeto de participante
      Map<String, dynamic> participante = {
        'uid': uid,
        'nombre': nombreUsuario,
        'horasComprometidas': horasNum,
        'fechaRegistro': DateTime.now().toIso8601String(), // ← CAMBIADO
        'estado': 'pendiente',
      };

      // Crear registro de actividad para el historial
      Map<String, dynamic> registroActividad = {
        'usuarioId': uid,
        'actividadId': actividadId,
        'huertoId': widget.huertoData['id'],
        'huertoNombre': widget.huertoData['nombre'],
        'tipoActividad': tipoActividad,
        'horasComprometidas': horasNum,
        'fechaRegistro': FieldValue.serverTimestamp(),
        'estado': 'pendiente',
      };

      // Batch write
      WriteBatch batch = _firestore.batch();

      // 1. Agregar participante a la actividad
      DocumentReference actividadRef = _firestore
          .collection('actividades')
          .doc(actividadId);
      batch.update(actividadRef, {
        'participantes': FieldValue.arrayUnion([participante]),
      });

      // 2. Agregar actividad al historial del usuario
      DocumentReference userRef = _firestore.collection('usuarios').doc(uid);
      batch.update(userRef, {
        'actividadesRegistradas': FieldValue.arrayUnion([actividadId]),
      });

      // 3. Crear registro en colección de registros
      DocumentReference registroRef = _firestore
          .collection('registrosActividades')
          .doc();
      batch.set(registroRef, registroActividad);

      // Ejecutar operaciones
      await batch.commit();

      // Cerrar loading
      Navigator.pop(context);

      // Mostrar éxito
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '¡Registro exitoso!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Te has registrado en la actividad',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                'Horas comprometidas: $horas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true); // Volver con resultado
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Cerrar loading
      Navigator.pop(context);

      print('Error al registrarse: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrarse: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String tipo = widget.actividadData['tipo'] ?? 'Sin tipo';
    String descripcion =
        widget.actividadData['descripcion'] ?? 'Sin descripción';
    String huertoNombre = widget.huertoData['nombre'] ?? 'Sin nombre';

    // Mapeo de iconos según tipo de actividad
    IconData icono;
    Color color;

    switch (tipo.toLowerCase()) {
      case 'siembra':
        icono = Icons.grass;
        color = Colors.green;
        break;
      case 'riego':
        icono = Icons.water_drop;
        color = Colors.blue;
        break;
      case 'poda':
        icono = Icons.content_cut;
        color = Colors.orange;
        break;
      case 'limpieza':
        icono = Icons.cleaning_services;
        color = Colors.purple;
        break;
      case 'cosecha':
        icono = Icons.shopping_basket;
        color = Colors.amber;
        break;
      default:
        icono = Icons.assignment;
        color = Colors.grey;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detalle de Actividad',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card principal de la actividad
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Ícono de la actividad
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icono, size: 60, color: color),
                          ),
                          const SizedBox(height: 20),

                          // Tipo de actividad
                          Text(
                            tipo,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // Huerto
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.eco,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                huertoNombre,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Descripción
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Descripción',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            descripcion,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Formulario de registro (solo si no está registrado)
                    if (!_yaRegistrado) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Registrarse en esta actividad',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _horasController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'Horas de trabajo',
                                hintText: 'Ej: 2.5',
                                prefixIcon: const Icon(Icons.access_time),
                                suffixText: 'horas',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.green.shade700,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Especifica las horas que dedicarás a esta actividad',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _registrarseEnActividad,
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Registrarme',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Mensaje de ya registrado
                    if (_yaRegistrado) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.blue.shade700,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ya estás registrado en esta actividad',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _horasController.dispose();
    super.dispose();
  }
}

class CrearHuertoScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CrearHuertoScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<CrearHuertoScreen> createState() => _CrearHuertoScreenState();
}

class _CrearHuertoScreenState extends State<CrearHuertoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final nombreController = TextEditingController();
  final tamanoController = TextEditingController();
  final direccionController = TextEditingController();
  final descripcionController = TextEditingController();

  String tipoCultivoSeleccionado = 'Hortalizas';
  String estadoSeleccionado = 'Activo';
  bool _isLoading = false;

  final List<String> tiposCultivo = [
    'Hortalizas',
    'Frutas',
    'Plantas Medicinales',
    'Flores',
    'Hierbas Aromáticas',
    'Mixto',
    'Otro',
  ];

  final List<String> estados = [
    'Activo',
    'En Preparación',
    'En Mantenimiento',
    'Inactivo',
  ];

  Future<void> _crearHuerto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String uid = widget.userData['uid'];

      // Crear documento del huerto en Firestore
      DocumentReference huertoRef = await _firestore.collection('huertos').add({
        'nombre': nombreController.text.trim(),
        'tamaño': tamanoController.text.trim(),
        'direccion': direccionController.text.trim(),
        'tipoCultivo': tipoCultivoSeleccionado,
        'estado': estadoSeleccionado.toLowerCase(),
        'descripcion': descripcionController.text.trim(),
        'creadorId': uid,
        'creadorNombre': widget.userData['nombre'] ?? 'Administrador',
        'fechaCreacion': FieldValue.serverTimestamp(),
        'voluntarios': [],
        'actividades': [],
      });

      // Actualizar lista de huertos del administrador
      await _firestore.collection('usuarios').doc(uid).update({
        'huertosCreados': FieldValue.arrayUnion([huertoRef.id]),
      });

      setState(() {
        _isLoading = false;
      });

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Huerto "${nombreController.text}" creado exitosamente!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Regresar a la pantalla anterior
      Navigator.pop(context, true); // true indica que se creó un huerto
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('Error al crear huerto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear huerto: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Crear Nuevo Huerto',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen/ícono
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
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
                    child: Icon(
                      Icons.add_business,
                      size: 50,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                const Text(
                  'Información del Huerto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // Campo Nombre
                TextFormField(
                  controller: nombreController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Nombre del Huerto *',
                    hintText: 'Ej: Huerto Comunitario Central',
                    prefixIcon: const Icon(Icons.park),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa el nombre del huerto';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Tamaño
                TextFormField(
                  controller: tamanoController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Tamaño *',
                    hintText: 'Ej: 50m², 100m², 1 hectárea',
                    prefixIcon: const Icon(Icons.straighten),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa el tamaño';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Dirección
                TextFormField(
                  controller: direccionController,
                  enabled: !_isLoading,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Dirección *',
                    hintText: 'Ej: Calle 45 #23-10, Barrio Centro',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa la dirección';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Dropdown Tipo de Cultivo
                DropdownButtonFormField<String>(
                  value: tipoCultivoSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Cultivo *',
                    prefixIcon: const Icon(Icons.grass),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: tiposCultivo.map((String tipo) {
                    return DropdownMenuItem<String>(
                      value: tipo,
                      child: Text(tipo),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            tipoCultivoSeleccionado = value!;
                          });
                        },
                ),
                const SizedBox(height: 16),

                // Dropdown Estado
                DropdownButtonFormField<String>(
                  value: estadoSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Estado Actual *',
                    prefixIcon: const Icon(Icons.flag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: estados.map((String estado) {
                    return DropdownMenuItem<String>(
                      value: estado,
                      child: Text(estado),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            estadoSeleccionado = value!;
                          });
                        },
                ),
                const SizedBox(height: 16),

                // Campo Descripción (Opcional)
                TextFormField(
                  controller: descripcionController,
                  enabled: !_isLoading,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Descripción (Opcional)',
                    hintText:
                        'Describe las características especiales del huerto...',
                    prefixIcon: const Icon(Icons.description),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),

                // Botón Crear Huerto
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _crearHuerto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Crear Huerto',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Nota informativa
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Una vez creado el huerto, podrás gestionar actividades y asignar voluntarios.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
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
    nombreController.dispose();
    tamanoController.dispose();
    direccionController.dispose();
    descripcionController.dispose();
    super.dispose();
  }
}

class DetalleHuertoScreen extends StatefulWidget {
  final Map<String, dynamic> huertoData;
  final Map<String, dynamic> userData;

  const DetalleHuertoScreen({
    Key? key,
    required this.huertoData,
    required this.userData,
  }) : super(key: key);

  @override
  State<DetalleHuertoScreen> createState() => _DetalleHuertoScreenState();
}

class _DetalleHuertoScreenState extends State<DetalleHuertoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _huertoActualizado;

  @override
  void initState() {
    super.initState();
    _cargarDatosHuerto();
  }

  Future<void> _cargarDatosHuerto() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot doc = await _firestore
          .collection('huertos')
          .doc(widget.huertoData['id'])
          .get();

      if (doc.exists) {
        setState(() {
          _huertoActualizado = {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        });
      }
    } catch (e) {
      print('Error al cargar datos del huerto: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> huerto = _huertoActualizado ?? widget.huertoData;
    String nombre = huerto['nombre'] ?? 'Sin nombre';
    String tamano = huerto['tamaño'] ?? 'No especificado';
    String direccion = huerto['direccion'] ?? 'No especificada';
    String tipoCultivo = huerto['tipoCultivo'] ?? 'No especificado';
    String estado = huerto['estado'] ?? 'activo';
    String descripcion = huerto['descripcion'] ?? 'Sin descripción';
    List voluntarios = huerto['voluntarios'] ?? [];
    List actividades = huerto['actividades'] ?? [];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          nombre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              //Editar huerto
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de edición en desarrollo'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatosHuerto,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    //Header con degradado
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade700,
                            Colors.green.shade500,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Column(
                          children: [
                            // Ícono del huerto
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.eco,
                                size: 50,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 20),

                            //Estado del huerto
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                estado.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    //Contenido
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Estadísticas rápidas
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  Icons.person,
                                  '${voluntarios.length}',
                                  'Voluntarios',
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  Icons.task_alt,
                                  '${actividades.length}',
                                  'Actividades',
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          //Información del huerto
                          const Text(
                            'Información del Huerto',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  Icons.straighten,
                                  'Tamaño',
                                  tamano,
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(
                                  Icons.location_on,
                                  'Dirección',
                                  direccion,
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(
                                  Icons.grass,
                                  'Tipo de Cultivo',
                                  tipoCultivo,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Descripción
                          const Text(
                            'Descripción',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              descripcion.isEmpty
                                  ? 'Sin descripción'
                                  : descripcion,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Opciones de Gestión
                          const Text(
                            'Gestión del Huerto',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Botón Publicar Actividades
                          _buildActionButton(
                            context,
                            icon: Icons.add_task,
                            title: 'Publicar Actividades',
                            subtitle: 'Crear nuevas tareas para voluntarios',
                            color: Colors.green,
                            onTap: () {
                              //Navegar a publicar actividades
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      GestionarActividadesScreen(
                                        huertoData: huerto,
                                        userData: widget.userData,
                                      ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          //Botón Ver Estado de Actividades
                          _buildActionButton(
                            context,
                            icon: Icons.list_alt,
                            title: 'Ver Estado de Actividades',
                            subtitle: 'Revisar progreso y completadas',
                            color: Colors.blue,
                            onTap: () {
                              //Ver estado de actividades
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      GestionarActividadesScreen(
                                        huertoData: huerto,
                                        userData: widget.userData,
                                      ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Botón Asignar Voluntarios
                          _buildActionButton(
                            context,
                            icon: Icons.person_add,
                            title: 'Asignar Voluntarios',
                            subtitle: 'Agregar voluntarios al huerto',
                            color: Colors.orange,
                            onTap: () {
                              //Asignar voluntarios
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AsignarVoluntariosScreen(
                                        huertoData: huerto,
                                        userData: widget.userData,
                                      ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Botón Ver Lista de Voluntarios
                          _buildActionButton(
                            context,
                            icon: Icons.group,
                            title: 'Ver Lista de Voluntarios',
                            subtitle:
                                '${voluntarios.length} voluntarios registrados',
                            color: Colors.purple,
                            onTap: () {
                              //Ver lista de voluntarios
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ListaVoluntariosScreen(
                                    huertoData: huerto,
                                    userData: widget.userData,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget para card de estadística
  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Widget para fila de información
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.green.shade700, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  //Widget para botón de acción
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

class GestionarActividadesScreen extends StatefulWidget {
  final Map<String, dynamic> huertoData;
  final Map<String, dynamic> userData;

  const GestionarActividadesScreen({
    Key? key,
    required this.huertoData,
    required this.userData,
  }) : super(key: key);

  @override
  State<GestionarActividadesScreen> createState() =>
      _GestionarActividadesScreenState();
}

class _GestionarActividadesScreenState
    extends State<GestionarActividadesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _actividades = [];

  @override
  void initState() {
    super.initState();
    _cargarActividades();
  }

  Future<void> _cargarActividades() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('actividades')
          .where('huertoId', isEqualTo: widget.huertoData['id'])
          .orderBy('fecha', descending: false)
          .get();

      _actividades = snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('Error al cargar actividades: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gestionar Actividades',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CrearActividadScreen(
                huertoData: widget.huertoData,
                userData: widget.userData,
              ),
            ),
          );

          if (resultado == true) {
            _cargarActividades();
          }
        },
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva Actividad',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarActividades,
              child: _actividades.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _actividades.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildActividadCard(_actividades[index]),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 100,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'No hay actividades publicadas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Crea la primera actividad para\neste huerto',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () async {
                  final resultado = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CrearActividadScreen(
                        huertoData: widget.huertoData,
                        userData: widget.userData,
                      ),
                    ),
                  );

                  if (resultado == true) {
                    _cargarActividades();
                  }
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Crear Actividad',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActividadCard(Map<String, dynamic> actividad) {
    String titulo = actividad['titulo'] ?? 'Sin título';
    String tipo = actividad['tipo'] ?? 'general';
    String fecha = actividad['fechaFormateada'] ?? 'Sin fecha';
    String estado = actividad['estado'] ?? 'pendiente';
    String descripcion = actividad['descripcion'] ?? '';
    List voluntariosAsignados = actividad['voluntariosAsignados'] ?? [];

    Color estadoColor = _getEstadoColor(estado);
    IconData tipoIcon = _getTipoIcon(tipo);
    Color tipoColor = _getTipoColor(tipo);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tipoColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tipoColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(tipoIcon, color: tipoColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fecha,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getEstadoTexto(estado),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: estadoColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (descripcion.isNotEmpty) ...[
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      '${voluntariosAsignados.length} voluntarios asignados',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _mostrarDetalleActividad(actividad);
                        },
                        icon: Icon(
                          Icons.visibility,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        label: Text(
                          'Ver Detalles',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.green.shade700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _cambiarEstadoActividad(actividad);
                        },
                        icon: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Cambiar Estado',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalleActividad(Map<String, dynamic> actividad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(actividad['titulo'] ?? 'Detalle'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Tipo', actividad['tipo'] ?? 'No especificado'),
              _buildDetailRow(
                'Fecha',
                actividad['fechaFormateada'] ?? 'No especificada',
              ),
              _buildDetailRow(
                'Estado',
                _getEstadoTexto(actividad['estado'] ?? 'pendiente'),
              ),
              _buildDetailRow(
                'Voluntarios',
                '${(actividad['voluntariosAsignados'] ?? []).length}',
              ),
              if (actividad['descripcion'] != null &&
                  actividad['descripcion'].isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Descripción:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(actividad['descripcion']),
              ],
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _cambiarEstadoActividad(Map<String, dynamic> actividad) {
    String estadoActual = actividad['estado'] ?? 'pendiente';
    String? nuevoEstado;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Pendiente'),
              leading: Radio<String>(
                value: 'pendiente',
                groupValue: estadoActual,
                onChanged: (value) {
                  nuevoEstado = value;
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('En Proceso'),
              leading: Radio<String>(
                value: 'en_proceso',
                groupValue: estadoActual,
                onChanged: (value) {
                  nuevoEstado = value;
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Completada'),
              leading: Radio<String>(
                value: 'completada',
                groupValue: estadoActual,
                onChanged: (value) {
                  nuevoEstado = value;
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Fallida'),
              leading: Radio<String>(
                value: 'fallida',
                groupValue: estadoActual,
                onChanged: (value) {
                  nuevoEstado = value;
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    ).then((_) async {
      if (nuevoEstado != null && nuevoEstado != estadoActual) {
        try {
          await _firestore
              .collection('actividades')
              .doc(actividad['id'])
              .update({'estado': nuevoEstado});

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estado actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );

          _cargarActividades();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'en_proceso':
        return Colors.blue;
      case 'completada':
        return Colors.green;
      case 'fallida':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'PENDIENTE';
      case 'en_proceso':
        return 'EN PROCESO';
      case 'completada':
        return 'COMPLETADA';
      case 'fallida':
        return 'FALLIDA';
      default:
        return 'SIN ESTADO';
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'riego':
        return Icons.water_drop;
      case 'siembra':
        return Icons.eco;
      case 'poda':
        return Icons.content_cut;
      case 'limpieza':
        return Icons.cleaning_services;
      case 'cosecha':
        return Icons.agriculture;
      default:
        return Icons.task_alt;
    }
  }

  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'riego':
        return Colors.blue;
      case 'siembra':
        return Colors.green;
      case 'poda':
        return Colors.orange;
      case 'limpieza':
        return Colors.purple;
      case 'cosecha':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}

class CrearActividadScreen extends StatefulWidget {
  final Map<String, dynamic> huertoData;
  final Map<String, dynamic> userData;

  const CrearActividadScreen({
    Key? key,
    required this.huertoData,
    required this.userData,
  }) : super(key: key);

  @override
  State<CrearActividadScreen> createState() => _CrearActividadScreenState();
}

class _CrearActividadScreenState extends State<CrearActividadScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final tituloController = TextEditingController();
  final descripcionController = TextEditingController();

  String tipoSeleccionado = 'Riego';
  DateTime? fechaSeleccionada;
  TimeOfDay? horaSeleccionada;
  bool _isLoading = false;

  final List<String> tiposActividad = [
    'Riego',
    'Siembra',
    'Poda',
    'Limpieza',
    'Cosecha',
  ];

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      //locale: const Locale('es', 'ES'),
    );

    if (picked != null) {
      setState(() {
        fechaSeleccionada = picked;
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        horaSeleccionada = picked;
      });
    }
  }

  String _formatearFecha() {
    if (fechaSeleccionada == null) return 'No seleccionada';
    return '${fechaSeleccionada!.day}/${fechaSeleccionada!.month}/${fechaSeleccionada!.year}';
  }

  String _formatearHora() {
    if (horaSeleccionada == null) return 'No seleccionada';
    return '${horaSeleccionada!.hour.toString().padLeft(2, '0')}:${horaSeleccionada!.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _crearActividad() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una fecha'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Combinar fecha y hora si se seleccionó hora
      DateTime fechaCompleta = fechaSeleccionada!;
      if (horaSeleccionada != null) {
        fechaCompleta = DateTime(
          fechaSeleccionada!.year,
          fechaSeleccionada!.month,
          fechaSeleccionada!.day,
          horaSeleccionada!.hour,
          horaSeleccionada!.minute,
        );
      }

      String fechaFormateada = _formatearFecha();
      if (horaSeleccionada != null) {
        fechaFormateada += ' - ${_formatearHora()}';
      }

      // Crear actividad en Firestore
      DocumentReference actividadRef = await _firestore
          .collection('actividades')
          .add({
            'titulo': tituloController.text.trim(),
            'descripcion': descripcionController.text.trim(),
            'tipo': tipoSeleccionado.toLowerCase(),
            'fecha': Timestamp.fromDate(fechaCompleta),
            'fechaFormateada': fechaFormateada,
            'estado': 'pendiente',
            'huertoId': widget.huertoData['id'],
            'huertoNombre': widget.huertoData['nombre'],
            'creadorId': widget.userData['uid'],
            'creadorNombre': widget.userData['nombre'],
            'fechaCreacion': FieldValue.serverTimestamp(),
            'voluntariosAsignados': [],
          });

      // Actualizar el huerto con la nueva actividad
      await _firestore
          .collection('huertos')
          .doc(widget.huertoData['id'])
          .update({
            'actividades': FieldValue.arrayUnion([actividadRef.id]),
          });

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Actividad "${tituloController.text}" creada exitosamente!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('Error al crear actividad: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear actividad: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Publicar Nueva Actividad',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información del huerto
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.eco, color: Colors.green.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Huerto',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.huertoData['nombre'] ?? 'Sin nombre',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                const Text(
                  'Información de la Actividad',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // Campo Título
                TextFormField(
                  controller: tituloController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Título de la Actividad *',
                    hintText: 'Ej: Riego del sector norte',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa el título';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Dropdown Tipo de Actividad
                DropdownButtonFormField<String>(
                  value: tipoSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Actividad *',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: tiposActividad.map((String tipo) {
                    return DropdownMenuItem<String>(
                      value: tipo,
                      child: Text(tipo),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            tipoSeleccionado = value!;
                          });
                        },
                ),
                const SizedBox(height: 16),

                // Selector de Fecha
                InkWell(
                  onTap: _isLoading ? null : _seleccionarFecha,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fecha *',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatearFecha(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: fechaSeleccionada == null
                                      ? Colors.grey.shade500
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                //Selector de Hora
                InkWell(
                  onTap: _isLoading ? null : _seleccionarHora,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.green.shade700),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hora',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatearHora(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: horaSeleccionada == null
                                      ? Colors.grey.shade500
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo descripción
                TextFormField(
                  controller: descripcionController,
                  enabled: !_isLoading,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Descripción (Opcional)',
                    hintText: 'Describe los detalles de la actividad...',
                    prefixIcon: const Icon(Icons.description),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),

                // Botón publicar actividad
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _crearActividad,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Publicar Actividad',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                //Nota informativa
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'La actividad será visible para todos los voluntarios del huerto.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
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
    tituloController.dispose();
    descripcionController.dispose();
    super.dispose();
  }
}

class AsignarVoluntariosScreen extends StatefulWidget {
  final Map<String, dynamic> huertoData;
  final Map<String, dynamic> userData;

  const AsignarVoluntariosScreen({
    Key? key,
    required this.huertoData,
    required this.userData,
  }) : super(key: key);

  @override
  State<AsignarVoluntariosScreen> createState() =>
      _AsignarVoluntariosScreenState();
}

class _AsignarVoluntariosScreenState extends State<AsignarVoluntariosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _todosVoluntarios = [];
  List<Map<String, dynamic>> _voluntariosFiltrados = [];
  List<String> _voluntariosAsignados = [];

  @override
  void initState() {
    super.initState();
    _cargarVoluntarios();
  }

  Future<void> _cargarVoluntarios() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener voluntarios ya asignados al huerto
      DocumentSnapshot huertoDoc = await _firestore
          .collection('huertos')
          .doc(widget.huertoData['id'])
          .get();

      if (huertoDoc.exists) {
        List voluntarios =
            (huertoDoc.data() as Map<String, dynamic>)['voluntarios'] ?? [];
        _voluntariosAsignados = voluntarios.cast<String>();
      }

      // Obtener todos los usuarios voluntarios
      QuerySnapshot snapshot = await _firestore
          .collection('usuarios')
          .where('tipoUsuario', isEqualTo: 'Voluntario')
          .get();

      _todosVoluntarios = snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'uid': doc.id})
          .toList();

      _voluntariosFiltrados = _todosVoluntarios;
    } catch (e) {
      print('Error al cargar voluntarios: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar voluntarios: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _filtrarVoluntarios(String query) {
    setState(() {
      if (query.isEmpty) {
        _voluntariosFiltrados = _todosVoluntarios;
      } else {
        _voluntariosFiltrados = _todosVoluntarios.where((voluntario) {
          String nombre = (voluntario['nombre'] ?? '').toLowerCase();
          String usuario = (voluntario['usuario'] ?? '').toLowerCase();
          String correo = (voluntario['correo'] ?? '').toLowerCase();
          String busqueda = query.toLowerCase();

          return nombre.contains(busqueda) ||
              usuario.contains(busqueda) ||
              correo.contains(busqueda);
        }).toList();
      }
    });
  }

  Future<void> _asignarVoluntario(Map<String, dynamic> voluntario) async {
    String uid = voluntario['uid'];

    try {
      // Agregar voluntario al huerto
      await _firestore
          .collection('huertos')
          .doc(widget.huertoData['id'])
          .update({
            'voluntarios': FieldValue.arrayUnion([uid]),
          });

      // Agregar huerto al voluntario
      await _firestore.collection('usuarios').doc(uid).update({
        'huertosRegistrados': FieldValue.arrayUnion([widget.huertoData['id']]),
      });

      setState(() {
        _voluntariosAsignados.add(uid);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${voluntario['nombre']} asignado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error al asignar voluntario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asignar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removerVoluntario(Map<String, dynamic> voluntario) async {
    String uid = voluntario['uid'];

    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Voluntario'),
        content: Text(
          '¿Estás seguro de remover a ${voluntario['nombre']} del huerto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      // Remover voluntario del huerto
      await _firestore
          .collection('huertos')
          .doc(widget.huertoData['id'])
          .update({
            'voluntarios': FieldValue.arrayRemove([uid]),
          });

      // Remover huerto del voluntario
      await _firestore.collection('usuarios').doc(uid).update({
        'huertosRegistrados': FieldValue.arrayRemove([widget.huertoData['id']]),
      });

      setState(() {
        _voluntariosAsignados.remove(uid);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${voluntario['nombre']} removido del huerto'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('Error al remover voluntario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al remover: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Asignar Voluntarios',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header con información del huerto
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Huerto',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.huertoData['nombre'] ?? 'Sin nombre',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_voluntariosAsignados.length} voluntarios asignados',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Buscador
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filtrarVoluntarios,
                    decoration: InputDecoration(
                      hintText: 'Buscar voluntarios...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filtrarVoluntarios('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),

                // Lista de voluntarios
                Expanded(
                  child: _voluntariosFiltrados.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _voluntariosFiltrados.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildVoluntarioCard(
                                _voluntariosFiltrados[index],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No se encontraron voluntarios'
                : 'No hay voluntarios disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Intenta con otra búsqueda'
                : 'Aún no hay voluntarios registrados',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildVoluntarioCard(Map<String, dynamic> voluntario) {
    String uid = voluntario['uid'];
    bool yaAsignado = _voluntariosAsignados.contains(uid);
    String nombre = voluntario['nombre'] ?? 'Sin nombre';
    String usuario = voluntario['usuario'] ?? 'usuario';
    String correo = voluntario['correo'] ?? 'No especificado';
    String telefono = voluntario['telefono'] ?? 'No especificado';
    String horario = voluntario['horario'] ?? 'No especificado';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: yaAsignado
            ? Border.all(color: Colors.green.shade300, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: yaAsignado ? Colors.green.shade50 : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: yaAsignado
                      ? Colors.green.shade100
                      : Colors.grey.shade300,
                  child: Icon(
                    Icons.person,
                    color: yaAsignado
                        ? Colors.green.shade700
                        : Colors.grey.shade600,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@$usuario',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (yaAsignado)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ASIGNADO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Información
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.email, correo),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone, telefono),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, 'Disponible: $horario'),
                const SizedBox(height: 16),

                // Botón de acción
                SizedBox(
                  width: double.infinity,
                  child: yaAsignado
                      ? OutlinedButton.icon(
                          onPressed: () => _removerVoluntario(voluntario),
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 18,
                          ),
                          label: const Text('Remover del Huerto'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _asignarVoluntario(voluntario),
                          icon: const Icon(
                            Icons.add_circle_outline,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Asignar al Huerto',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class ListaVoluntariosScreen extends StatefulWidget {
  final Map<String, dynamic> huertoData;
  final Map<String, dynamic> userData;

  const ListaVoluntariosScreen({
    Key? key,
    required this.huertoData,
    required this.userData,
  }) : super(key: key);

  @override
  State<ListaVoluntariosScreen> createState() => _ListaVoluntariosScreenState();
}

class _ListaVoluntariosScreenState extends State<ListaVoluntariosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _voluntarios = [];

  @override
  void initState() {
    super.initState();
    _cargarVoluntarios();
  }

  Future<void> _cargarVoluntarios() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener IDs de voluntarios del huerto
      DocumentSnapshot huertoDoc = await _firestore
          .collection('huertos')
          .doc(widget.huertoData['id'])
          .get();

      if (huertoDoc.exists) {
        List<String> voluntariosIds =
            ((huertoDoc.data() as Map<String, dynamic>)['voluntarios'] ?? [])
                .cast<String>();

        if (voluntariosIds.isEmpty) {
          setState(() {
            _voluntarios = [];
            _isLoading = false;
          });
          return;
        }

        // Obtener datos de cada voluntario
        List<Map<String, dynamic>> voluntariosData = [];
        for (String uid in voluntariosIds) {
          DocumentSnapshot userDoc = await _firestore
              .collection('usuarios')
              .doc(uid)
              .get();

          if (userDoc.exists) {
            voluntariosData.add({
              ...userDoc.data() as Map<String, dynamic>,
              'uid': userDoc.id,
            });
          }
        }

        setState(() {
          _voluntarios = voluntariosData;
        });
      }
    } catch (e) {
      print('Error al cargar voluntarios: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar voluntarios: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _removerVoluntario(Map<String, dynamic> voluntario) async {
    String uid = voluntario['uid'];

    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Voluntario'),
        content: Text(
          '¿Estás seguro de remover a ${voluntario['nombre']} del huerto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      // Remover voluntario del huerto
      await _firestore
          .collection('huertos')
          .doc(widget.huertoData['id'])
          .update({
            'voluntarios': FieldValue.arrayRemove([uid]),
          });

      // Remover huerto del voluntario
      await _firestore.collection('usuarios').doc(uid).update({
        'huertosRegistrados': FieldValue.arrayRemove([widget.huertoData['id']]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${voluntario['nombre']} removido del huerto'),
          backgroundColor: Colors.orange,
        ),
      );

      // Recargar lista
      _cargarVoluntarios();
    } catch (e) {
      print('Error al remover voluntario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al remover: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _verDetalleVoluntario(Map<String, dynamic> voluntario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.person, color: Colors.green.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voluntario['nombre'] ?? 'Sin nombre',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    '@${voluntario['usuario'] ?? 'usuario'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                'Correo',
                voluntario['correo'] ?? 'No especificado',
              ),
              _buildDetailRow(
                'Teléfono',
                voluntario['telefono'] ?? 'No especificado',
              ),
              _buildDetailRow(
                'Dirección',
                voluntario['direccion'] ?? 'No especificada',
              ),
              _buildDetailRow(
                'Horario disponible',
                voluntario['horario'] ?? 'No especificado',
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Estadísticas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Actividades completadas',
                '${(voluntario['actividadesCompletadas'] ?? []).length}',
              ),
              _buildDetailRow(
                'Huertos registrados',
                '${(voluntario['huertosRegistrados'] ?? []).length}',
              ),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Voluntarios del Huerto',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AsignarVoluntariosScreen(
                    huertoData: widget.huertoData,
                    userData: widget.userData,
                  ),
                ),
              );
              // Recargar después de asignar
              _cargarVoluntarios();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarVoluntarios,
              child: _voluntarios.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        // Header con estadísticas
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade700,
                                Colors.green.shade500,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Huerto',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.huertoData['nombre'] ?? 'Sin nombre',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.people,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_voluntarios.length} ${_voluntarios.length == 1 ? 'voluntario' : 'voluntarios'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Lista de voluntarios
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _voluntarios.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildVoluntarioCard(
                                  _voluntarios[index],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 100,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'No hay voluntarios asignados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Asigna voluntarios para comenzar\na trabajar en este huerto',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AsignarVoluntariosScreen(
                        huertoData: widget.huertoData,
                        userData: widget.userData,
                      ),
                    ),
                  );
                  _cargarVoluntarios();
                },
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: const Text(
                  'Asignar Voluntarios',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoluntarioCard(Map<String, dynamic> voluntario) {
    String nombre = voluntario['nombre'] ?? 'Sin nombre';
    String usuario = voluntario['usuario'] ?? 'usuario';
    String correo = voluntario['correo'] ?? 'No especificado';
    String telefono = voluntario['telefono'] ?? 'No especificado';
    int actividadesCompletadas =
        (voluntario['actividadesCompletadas'] ?? []).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.green.shade100,
                  child: Icon(
                    Icons.person,
                    color: Colors.green.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@$usuario',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$actividadesCompletadas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Información y botones
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.email, correo),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone, telefono),
                const SizedBox(height: 16),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _verDetalleVoluntario(voluntario),
                        icon: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.green.shade700,
                        ),
                        label: Text(
                          'Ver Detalles',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.green.shade700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _removerVoluntario(voluntario),
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Remover',
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

//Pantalla principal con drawer
class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomeScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _actividadesPendientes = [];
  bool _isLoadingActividades = true;

  @override
  void initState() {
    super.initState();
    _cargarActividadesPendientes();
  }

  // Cargar actividades pendientes según tipo de usuario
  Future<void> _cargarActividadesPendientes() async {
    setState(() {
      _isLoadingActividades = true;
    });

    try {
      String tipoUsuario = widget.userData['tipoUsuario'] ?? 'Voluntario';
      String uid = widget.userData['uid'];

      if (tipoUsuario == 'Administrador') {
        // Cargar actividades de los huertos del admin
        await _cargarActividadesAdmin(uid);
      } else {
        // Cargar actividades del voluntario
        await _cargarActividadesVoluntario(uid);
      }

      setState(() {
        _isLoadingActividades = false;
      });
    } catch (e) {
      print('Error al cargar actividades: $e');
      setState(() {
        _isLoadingActividades = false;
      });
    }
  }

  // Cargar actividades para Administrador
  Future<void> _cargarActividadesAdmin(String uid) async {
    List<Map<String, dynamic>> actividadesList = [];

    // Obtener huertos del admin
    QuerySnapshot huertosSnapshot = await _firestore
        .collection('huertos')
        .where('creadorId', isEqualTo: uid)
        .get();

    List<String> huertosIds = huertosSnapshot.docs
        .map((doc) => doc.id)
        .toList();

    // Obtener actividades de esos huertos
    if (huertosIds.isNotEmpty) {
      QuerySnapshot actividadesSnapshot = await _firestore
          .collection('actividades')
          .where('huertoId', whereIn: huertosIds)
          .where('estado', isEqualTo: 'pendiente')
          .orderBy('fecha', descending: false)
          .limit(10)
          .get();

      for (var doc in actividadesSnapshot.docs) {
        Map<String, dynamic> actividad = doc.data() as Map<String, dynamic>;
        actividad['id'] = doc.id;

        // Obtener nombre del huerto
        String huertoId = actividad['huertoId'];
        DocumentSnapshot huertoDoc = await _firestore
            .collection('huertos')
            .doc(huertoId)
            .get();
        if (huertoDoc.exists) {
          actividad['huertoNombre'] =
              (huertoDoc.data() as Map<String, dynamic>)['nombre'];
        }

        actividadesList.add(actividad);
      }
    }

    _actividadesPendientes = actividadesList;
  }

  // Cargar actividades para Voluntario
  Future<void> _cargarActividadesVoluntario(String uid) async {
    List<Map<String, dynamic>> actividadesList = [];

    try {
      // Obtener actividades donde el usuario está registrado
      QuerySnapshot actividadesSnapshot = await _firestore
          .collection('actividades')
          .get();

      for (var doc in actividadesSnapshot.docs) {
        Map<String, dynamic> actividad = doc.data() as Map<String, dynamic>;
        actividad['id'] = doc.id;

        // Verificar si el usuario está registrado en esta actividad
        List<dynamic> participantes = actividad['participantes'] ?? [];

        var participanteEncontrado = participantes.firstWhere(
          (p) => p['uid'] == uid,
          orElse: () => null,
        );

        if (participanteEncontrado != null) {
          // El usuario está registrado en esta actividad

          // Obtener nombre del huerto
          String huertoId = actividad['huertoId'] ?? '';
          if (huertoId.isNotEmpty) {
            DocumentSnapshot huertoDoc = await _firestore
                .collection('huertos')
                .doc(huertoId)
                .get();

            if (huertoDoc.exists) {
              actividad['huertoNombre'] =
                  (huertoDoc.data() as Map<String, dynamic>)['nombre'] ??
                  'Sin nombre';
            } else {
              actividad['huertoNombre'] = 'Huerto no encontrado';
            }
          } else {
            actividad['huertoNombre'] = 'Sin huerto';
          }

          // Obtener estado y horas del participante
          actividad['miEstado'] =
              participanteEncontrado['estado'] ?? 'pendiente';
          actividad['misHoras'] =
              participanteEncontrado['horasComprometidas'] ?? 0;

          // Solo agregar si el estado es pendiente o en proceso
          String miEstado = actividad['miEstado'];
          if (miEstado == 'pendiente' || miEstado == 'en_proceso') {
            actividadesList.add(actividad);
          }
        }
      }

      // Ordenar por fecha si existe el campo
      actividadesList.sort((a, b) {
        if (a['fecha'] == null || b['fecha'] == null) return 0;
        return a['fecha'].compareTo(b['fecha']);
      });

      _actividadesPendientes = actividadesList;

      print('Actividades cargadas: ${actividadesList.length}'); // Debug
    } catch (e) {
      print('Error detallado al cargar actividades: $e');
      _actividadesPendientes = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    String nombreUsuario = widget.userData['nombre'] ?? 'Usuario';
    String tipoUsuario = widget.userData['tipoUsuario'] ?? 'Voluntario';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text(
          'Greenhand App',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PerfilScreen(userData: widget.userData),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 35,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nombreUsuario,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tipoUsuario,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.green),
              title: const Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.eco, color: Colors.green),
              title: Text(
                tipoUsuario == 'Administrador' ? 'Mis Huertos' : 'Huertos',
              ),
              subtitle: Text(
                tipoUsuario == 'Administrador'
                    ? 'Gestiona tus huertos'
                    : 'Busca y únete',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HuertosScreen(userData: widget.userData),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.green),
              title: const Text('Estadísticas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EstadisticasScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.school, color: Colors.green),
              title: const Text('Educación'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EducacionScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PerfilScreen(userData: widget.userData),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                bool? confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cerrar Sesión'),
                    content: const Text(
                      '¿Estás seguro que deseas cerrar sesión?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Cerrar Sesión',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmar == true) {
                  await _authService.cerrarSesion();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WelcomeScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarActividadesPendientes,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Saludo personalizado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '¡Hola!',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        nombreUsuario,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tipoUsuario,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Título de actividades pendientes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tipoUsuario == 'Administrador'
                          ? 'Actividades de mis Huertos'
                          : 'Mis Actividades',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (_actividadesPendientes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_actividadesPendientes.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 15),

                // Lista de actividades
                _isLoadingActividades
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _actividadesPendientes.isEmpty
                    ? _buildEmptyState(tipoUsuario)
                    : Column(
                        children: _actividadesPendientes.map((actividad) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildActividadCard(actividad, tipoUsuario),
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget para estado vacío
  Widget _buildEmptyState(String tipoUsuario) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              tipoUsuario == 'Administrador'
                  ? 'No hay actividades pendientes'
                  : 'No tienes actividades registradas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              tipoUsuario == 'Administrador'
                  ? 'Crea actividades en tus huertos'
                  : 'Busca huertos y regístrate en actividades',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget para card de actividad
  Widget _buildActividadCard(
    Map<String, dynamic> actividad,
    String tipoUsuario,
  ) {
    String tipo = actividad['tipo'] ?? 'Sin tipo';
    String huertoNombre = actividad['huertoNombre'] ?? 'Sin huerto';
    String descripcion = actividad['descripcion'] ?? '';

    // Mapeo de iconos según tipo de actividad
    IconData icono;
    Color color;

    switch (tipo.toLowerCase()) {
      case 'siembra':
        icono = Icons.grass;
        color = Colors.green;
        break;
      case 'riego':
        icono = Icons.water_drop;
        color = Colors.blue;
        break;
      case 'poda':
        icono = Icons.content_cut;
        color = Colors.orange;
        break;
      case 'limpieza':
        icono = Icons.cleaning_services;
        color = Colors.purple;
        break;
      case 'cosecha':
        icono = Icons.shopping_basket;
        color = Colors.amber;
        break;
      default:
        icono = Icons.assignment;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          // Navegar a detalle de actividad
          String huertoId = actividad['huertoId'] ?? '';

          if (huertoId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se puede acceder a esta actividad'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // Obtener datos completos del huerto
          try {
            DocumentSnapshot huertoDoc = await _firestore
                .collection('huertos')
                .doc(huertoId)
                .get();

            if (!huertoDoc.exists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Huerto no encontrado'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            Map<String, dynamic> huertoData =
                huertoDoc.data() as Map<String, dynamic>;
            huertoData['id'] = huertoDoc.id;

            // Navegar según tipo de usuario
            if (tipoUsuario == 'Voluntario') {
              final resultado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalleActividadScreen(
                    actividadData: actividad,
                    userData: widget.userData,
                    huertoData: huertoData,
                  ),
                ),
              );

              // Si hubo cambios, recargar
              if (resultado == true) {
                _cargarActividadesPendientes();
              }
            } else {
              // Para administrador, ir a detalle del huerto
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalleHuertoScreen(
                    huertoData: huertoData,
                    userData: widget.userData,
                  ),
                ),
              );
            }
          } catch (e) {
            print('Error al cargar huerto: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tipo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.eco, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          huertoNombre,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (tipoUsuario == 'Voluntario' &&
                      actividad['misHoras'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${actividad['misHoras']} horas',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
