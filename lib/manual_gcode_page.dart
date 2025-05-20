import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ManualGcodePage extends StatefulWidget {
  final BluetoothDevice? device;
  final bool isConnected;
  final Function(String) sendCommand;
  final VoidCallback onBluetoothTap;

  const ManualGcodePage({
    Key? key,
    required this.device,
    required this.isConnected,
    required this.sendCommand,
    required this.onBluetoothTap,
  }) : super(key: key);

  @override
  _ManualGcodePageState createState() => _ManualGcodePageState();
}

class _ManualGcodePageState extends State<ManualGcodePage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _sentCommands = [];
  final List<String> _pendingCommands = [];

  BluetoothConnection? _connection;
  bool _waitingForOk = false;

  @override
  void initState() {
    super.initState();
    if (widget.device != null && widget.isConnected) {
      BluetoothConnection.toAddress(widget.device!.address).then((conn) {
        _connection = conn;
        _connection!.input!.listen(_onDataReceived).onDone(() {
          print('Bluetooth disconnected');
        });
      }).catchError((error) {
        print('Connection error: $error');
      });
    }
  }

  String _buffer = "";

  void _onDataReceived(Uint8List data) {
    _buffer += ascii.decode(data);

    while (_buffer.contains('\n')) {
      final newlineIndex = _buffer.indexOf('\n');
      final line = _buffer.substring(0, newlineIndex).trim();
      _buffer = _buffer.substring(newlineIndex + 1);

      if (line.isNotEmpty) {
        print("Received line: $line");
        if (line == "ok") {
          _waitingForOk = false;
          _sendNextCommand();
        }
      }
    }
  }


  void _send() {
    String text = _controller.text.trim();
    if (text.isNotEmpty) {
      List<String> lines = LineSplitter.split(text)
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      setState(() {
        _pendingCommands.addAll(lines);
        _sentCommands.addAll(lines);
        _controller.clear();
      });

      _sendNextCommand();
    }
  }

  void _sendNextCommand() {
    if (_pendingCommands.isNotEmpty && !_waitingForOk) {
      String command = _pendingCommands.removeAt(0);
      print("Sending: $command");
      widget.sendCommand(command + '\n'); // Always end with newline for GRBL
      _waitingForOk = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF9),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, left: 10, right: 20, bottom: 30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0BE1CC), Color(0xFF2CDBC9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(" 🛠️ Manual G-code",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: "Enter G-code (multiple lines supported)",
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: _send),
                  ),
                  onSubmitted: (_) => _send(),
                ),
                const SizedBox(height: 10),
                const Text("Sent Commands", style: TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: ListView.builder(
                    itemCount: _sentCommands.length,
                    itemBuilder: (context, index) => Text(_sentCommands[index]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
