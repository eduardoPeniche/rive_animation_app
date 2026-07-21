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
            ]
          ),
        )
      )
    );
  }

  //2.4 Liberar recursos de memoria
  @override
  void dispose() {
    super.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _typingDebounce?.cancel(); //4.4 Cancelar temporizador
  }
}