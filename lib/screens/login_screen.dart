import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async'; //4.1 Importar librería para temporizador

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;

  //Cerebro de la animación
  StateMachineController? _controller;
  //State Machine Input
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  //3.1 Variable para recorrer la mirada
  SMINumber? _numLook;

  //4.2 Variable para temporizador
  Timer? _typingDebounce;

  //5.1 Controllers para manipular el texto escrito por el usuario
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  //Errores para mostrar en la UI
  String? emailError;
  String? passwordError;

  //5.3 Validadores
  bool isValidEmail(String email) {
    final regularExp = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regularExp.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    final regularExp = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');
    return regularExp.hasMatch(pass);
  }

  //5.4 Accion al boton
  void _onLogin() {
    // quitar los espacios al inicio y final del texto
    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    // recalcular errores
    final emailMsgError = isValidEmail(email) ? null : 'Email inválido';
    final passMsgError = isValidPassword(password) ? null :
      '8 caracteres, 1 mayúscula, 1 minúscula, 1 número y 1 caracter especial';

    //5.5 Notificar cambios en la UI
    setState(() {
      emailError = emailMsgError;
      passwordError = passMsgError;
    });

    //5.6 Cerrar el teclado y bajar manos
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    //5.7 Activar trigger 
    bool isValid = emailMsgError == null && passMsgError == null;
    if (isValid) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }
  }


  //2.1 Crear variables para focusNode
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        // Verifica que no sea nulo
        if (_isHandsUp != null) {
          // Manos abajo en el email
          _isHandsUp?.change(false);
          // Mirada neutral
          _numLook?.value = 50;
        }
      }
    });
    _passwordFocusNode.addListener(() {
      // Manos arriba en password
        _isHandsUp?.change(_passwordFocusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {

    //para obtener el tamaño de la pantalla
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: 200,
                child: RiveAnimation.asset(
                  'animated_login_bear.riv',
                  stateMachines: const ['Login Machine'],
                  //al iniciar la animación
                  onInit: (artboard) {
                    _controller = StateMachineController.fromArtboard(
                      artboard,
                      'Login Machine',
                    );
                    // Verifica que inció bien la animación
                    if (_controller == null) return;
                    artboard.addController(_controller!);
                    // Vincular los inputs de la animación con las variables de la clase
                    _isChecking = _controller?.findSMI('isChecking');
                    _isHandsUp = _controller?.findSMI('isHandsUp');
                    _trigSuccess = _controller?.findSMI('trigSuccess');
                    _trigFail = _controller?.findSMI('trigFail');

                    //3.3 vincular numLook con la variable de la clase
                    _numLook = _controller?.findSMI('numLook');
                  },
                  ),
              ),
            // Para separar elementos
            SizedBox(height: 10),
            // Campo de texto para email
            TextField(
              //5.8 Enlazar controller
              controller: _emailController,
              focusNode: _emailFocusNode,
              // 1.3 Vincular SMIs a inputs de UI
              onChanged: (value) {
                //if (_isHandsUp != null) {
                //  _isHandsUp?.change(false);
                //}
                // Si ischecking es null
                if (_isChecking != null) {
                  // Activa el modo chismos
                  _isChecking?.change(true);
                  //3.4 Implementar numlok. Ajustar limites de 0 a 100
                  //80 es la medida de calibracion
                  final look = (value.length / 80.0 * 100).clamp(
                    0.0,
                    100.0
                    ); // Clamp es un rango. Traduccion abrazadera
                  _numLook?.value = look;

                  //4.3 Implementar temporizador para que deje de mirar
                  _typingDebounce?.cancel();
                  _typingDebounce = Timer(const Duration(seconds: 3), () {
                    // si se cierra la pantalla
                    if (!mounted) return;
                    // Mirada neutral
                    _isChecking?.change(false);
                  });
                }
              },
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                //5.9 Mostrar error en la UI
                errorText: emailError,
                hintText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 10),
            // Campo de texto para contraseña
            TextField(
              //5.8 Enlazar controller
              controller: _passController,
              focusNode: _passwordFocusNode,
              onChanged: (value) {
                if (_isChecking != null) {
                  // no tapes los ojos al ver email
                  _isChecking?.change(false);
                }
                //if (_isHandsUp != null) {
                //  _isHandsUp?.change(true);
                //}
              },
              obscureText: _obscureText,
              decoration: InputDecoration(
                //5.9 Mostrar error en la UI
                errorText: passwordError,
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 10),
            MaterialButton(
              minWidth: size.width,
              height: 50,

              onPressed: _onLogin,
              color: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              textColor: Colors.white,
              child: const Text('Login', style: TextStyle(color: Colors.white, fontSize: 18)),


            )
            ]
          ),
        )
      )
    );
  }

  //2.4 Liberar recursos de memoria
  @override
  void dispose() {
    // 5.10 Liberar controllers
    super.dispose();
    _emailController.dispose();
    _passController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _typingDebounce?.cancel(); //4.4 Cancelar temporizador
  }
}