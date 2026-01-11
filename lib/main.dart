import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_joystick/flutter_joystick.dart'; // Import the joystick package
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Force Landscape for a "Controller" feel
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pro Car Remote',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: const CarRemote(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CarRemote extends StatefulWidget {
  const CarRemote({super.key});

  @override
  State<CarRemote> createState() => _CarRemoteState();
}

class _CarRemoteState extends State<CarRemote> {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('car/command');
  
  // We use a timer to prevent spamming Firebase with Joystick data
  Timer? _debounceTimer;
  String _lastCommand = "stop";

  void _sendCommand(String command) {
    if (_lastCommand != command) {
      _ref.set(command);
      _lastCommand = command;
      print("Sent: $command"); // Debug log
    }
  }

  // Translates Joystick X/Y to your existing simple commands
  // You can upgrade this later to send raw X/Y to the car for speed control
  void _handleJoystickChange(StickDragDetails details) {
    if (_debounceTimer?.isActive ?? false) return;

    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (details.y < -0.5) {
        _sendCommand('forward');
      } else if (details.y > 0.5) {
        _sendCommand('backward');
      } else if (details.x < -0.5) {
        _sendCommand('left');
      } else if (details.x > 0.5) {
        _sendCommand('right');
      } else {
        _sendCommand('stop');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Subtle dark radial gradient background
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF2C2C2C), Color(0xFF000000)],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // --- LEFT SIDE: JOYSTICK ---
            Expanded(
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Joystick(
                    mode: JoystickMode.all,
                    listener: _handleJoystickChange,
                    base: Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E1E1E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white10,
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                    ),
                    stick: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(4, 4),
                          ),
                        ],
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4A4A4A), Color(0xFF222222)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // --- CENTER: DASHBOARD (Optional Status) ---
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi, color: Colors.green, size: 24),
                const SizedBox(height: 8),
                Text(
                  "ONLINE",
                  style: TextStyle(
                    color: Colors.green.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),

            // --- RIGHT SIDE: ACTION BUTTONS ---
            const Expanded(
              child: Center(
                child: ActionGrid(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionGrid extends StatelessWidget {
  const ActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220, // Constrain width to keep buttons tight
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: const [
          // Blue: Headlights
          CyberButton(
            color: Color(0xFF1976D2), // Blue
            icon: Icons.highlight,
            command: 'lights',
          ),
          // Yellow: Horn
          CyberButton(
            color: Color(0xFFFBC02D), // Yellow
            icon: Icons.volume_up_rounded,
            command: 'horn',
          ),
          // Red: Lock
          CyberButton(
            color: Color(0xFFD32F2F), // Red
            icon: Icons.lock_outline,
            command: 'lock',
          ),
          // Green: Start/Engine
          CyberButton(
            color: Color(0xFF388E3C), // Green
            icon: Icons.power_settings_new,
            command: 'start',
          ),
        ],
      ),
    );
  }
}

class CyberButton extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String command;

  const CyberButton({
    super.key,
    required this.color,
    required this.icon,
    required this.command,
  });

  @override
  State<CyberButton> createState() => _CyberButtonState();
}

class _CyberButtonState extends State<CyberButton> {
  bool _isPressed = false;

  void _triggerAction() {
    // Send simple toggle commands or press events
    FirebaseDatabase.instance.ref('car/action').set(widget.command);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _triggerAction();
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isPressed
                ? [
                    widget.color.withOpacity(0.7),
                    widget.color.withOpacity(0.9)
                  ] // Darker when pressed
                : [
                    widget.color.withOpacity(0.8),
                    widget.color
                  ], // Lighter normally
          ),
          boxShadow: _isPressed
              ? [] // No shadow when pressed (looks like it's inside)
              : [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(2, 2),
                  )
                ],
        ),
        child: Center(
          child: Icon(
            widget.icon,
            size: 32,
            color: Colors.white.withOpacity(0.95),
          ),
        ),
      ),
    );
  }
}