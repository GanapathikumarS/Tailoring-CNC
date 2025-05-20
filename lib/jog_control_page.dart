import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CNC Jog Control',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  void sendDummyCommand(String command) {
    print("Sent: $command"); // Simulate sending command
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: Center(
        child: ElevatedButton(
          child: Text("Open Jog Control"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JogControlPage(sendCommand: sendDummyCommand),
              ),
            );
          },
        ),
      ),
    );
  }
}

class JogControlPage extends StatefulWidget {
  final Function(String) sendCommand;
  JogControlPage({required this.sendCommand});

  @override
  _JogControlPageState createState() => _JogControlPageState();
}

class _JogControlPageState extends State<JogControlPage> {
  bool showResume = false;
  double jogStepXY = 1.0;

  @override
  void initState() {
    super.initState();
    _loadJogStepXY();
  }

  Future<void> _loadJogStepXY() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      jogStepXY = prefs.getDouble('jogStepXY') ?? 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = jogStepXY.toStringAsFixed(3);

    return Scaffold(
      body: Column(
        children: [
          GradientTitleBar(icon: Icons.gamepad, title: 'Jog Control'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text("Jog Step: $step mm", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildRow([
                          jogButton("↖️", () => widget.sendCommand("G91 G0 X-$step Y$step")),
                          jogButton("⬆️", () => widget.sendCommand("G91 G0 Y$step")),
                          jogButton("↗️", () => widget.sendCommand("G91 G0 X$step Y$step")),
                        ]),
                        buildRow([
                          jogButton("⬅️", () => widget.sendCommand("G91 G0 X-$step")),
                          jogButton("🏠", () => widget.sendCommand("G90 G0 X0 Y0 Z0")),
                          jogButton("➡️", () => widget.sendCommand("G91 G0 X$step")),
                        ]),
                        buildRow([
                          jogButton("↙️", () => widget.sendCommand("G91 G0 X-$step Y-$step")),
                          jogButton("⬇️", () => widget.sendCommand("G91 G0 Y-$step")),
                          jogButton("↘️", () => widget.sendCommand("G91 G0 X$step Y-$step")),
                        ]),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      jogButton("Z+", () => widget.sendCommand("G91 G0 Z10")),
                      jogButton("Z-", () => widget.sendCommand("G91 G0 Z-10")),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      widget.sendCommand("!"); // Emergency stop
                      setState(() {
                        showResume = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    ),
                    child: Text(
                      "EMERGENCY STOP",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (showResume)
                    ElevatedButton(
                      onPressed: () {
                        widget.sendCommand("~"); // Resume
                        setState(() {
                          showResume = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      child: Text(
                        "RESUME",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      widget.sendCommand("!");           // Emergency stop
                      await Future.delayed(Duration(milliseconds: 500));

                      widget.sendCommand("\x18");        // Ctrl+X soft reset
                      await Future.delayed(Duration(seconds: 1));

                      widget.sendCommand("\$X");         // Unlock GRBL
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    ),
                    child: Text(
                      "RESET",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),


                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRow(List<Widget> buttons) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: buttons,
      ),
    );
  }

  Widget jogButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(20),
        shape: CircleBorder(),
        backgroundColor: Colors.teal,
      ),
      child: Text(label, style: TextStyle(fontSize: 20, color: Colors.white)),
    );
  }
}

class GradientTitleBar extends StatelessWidget {
  final IconData icon;
  final String title;

  const GradientTitleBar({
    Key? key,
    required this.icon,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 50, left: 10, right: 20, bottom: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0BE1CC), Color(0xFF2CDBC9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Icon(icon, color: Colors.white, size: 30),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
