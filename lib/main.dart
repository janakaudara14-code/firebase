
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Car Remote',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF212121),
      ),
      home: const CarRemote(),
    );
  }
}

class CarRemote extends StatelessWidget {
  const CarRemote({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 220,
          height: 600,
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.grey[800]!, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 15,
                offset: Offset(5, 5),
              ),
              BoxShadow(
                color: Colors.white10,
                blurRadius: 10,
                offset: Offset(-3, -3),
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CarRemoteButton(assetName: 'assets/icons/lock.svg', command: 'lock', isMovementButton: false),
              CarRemoteButton(assetName: 'assets/icons/unlock.svg', command: 'unlock', isMovementButton: false),
              CarRemoteButton(assetName: 'assets/icons/trunk.svg', command: 'trunk', isMovementButton: false),
              CarRemoteButton(assetName: 'assets/icons/panic.svg', command: 'panic', isMovementButton: false),
              SizedBox(height: 20),
              Column(
                children: [
                  CarRemoteButton(assetName: 'assets/icons/forward.svg', command: 'forward'),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CarRemoteButton(assetName: 'assets/icons/left.svg', command: 'left'),
                      CarRemoteButton(assetName: 'assets/icons/right.svg', command: 'right'),
                    ],
                  ),
                  SizedBox(height: 10),
                  CarRemoteButton(assetName: 'assets/icons/backward.svg', command: 'backward'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CarRemoteButton extends StatefulWidget {
  final String assetName;
  final String command;
  final bool isMovementButton;

  const CarRemoteButton({super.key, required this.assetName, required this.command, this.isMovementButton = true});

  @override
  git createState() => _CarRemoteButtonState();
}

class _CarRemoteButtonState extends State<CarRemoteButton> {
  bool _isPressed = false;

  void _sendCommand(String command) {
    DatabaseReference remoteRef = FirebaseDatabase.instance.ref('car/command');
    remoteRef.set(command);
  }

  @override
  Widget build(BuildContext context) {
    final double buttonSize = widget.isMovementButton ? 60 : 80;
    final double iconSize = widget.isMovementButton ? 30 : 35;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
        _sendCommand(widget.command);
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        if (widget.isMovementButton) {
          _sendCommand('stop');
        }
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
        if (widget.isMovementButton) {
          _sendCommand('stop');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          shape: BoxShape.circle,
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(4, 4),
                  ),
                  const BoxShadow(
                    color: Colors.white24,
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(-4, -4),
                  ),
                ],
        ),
        child: Center(
          child: SvgPicture.asset(
            widget.assetName,
            width: iconSize,
            height: iconSize,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
