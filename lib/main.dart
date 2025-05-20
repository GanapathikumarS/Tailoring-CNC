import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'jog_control_page.dart';
import 'laser_cutting_page.dart';
import 'settings_page.dart';
import 'manual_gcode_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Color backgroundColor = Color(0xFFF0FAF9);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LASER CNC',
      home: HomePage(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: backgroundColor,
      ),
    );
  }
}

class GradientTitleBar extends StatelessWidget {
  final IconData icon;
  final String title;
  final BluetoothDevice? device;
  final bool isConnected;
  final VoidCallback onBluetoothTap;
  final VoidCallback onMenuTap;

  const GradientTitleBar({
    Key? key,
    required this.icon,
    required this.title,
    required this.device,
    required this.isConnected,
    required this.onBluetoothTap,
    required this.onMenuTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 50, left: 10, right: 20, bottom: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0BE1CC), Color(0xFF0BE1CC), Color(0xFF2CDBC9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onMenuTap,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  device != null ? "Connected to: ${device!.name}" : "No device connected",
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.bluetooth,
              size: 28,
              color: isConnected ? Colors.green : Colors.red,
            ),
            onPressed: onBluetoothTap,
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? connection;
  BluetoothDevice? selectedDevice;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _enableBluetooth();
    requestPermissions();
  }

  void requestPermissions() async {
    await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
  }

  Future<void> _enableBluetooth() async {
    bool isEnabled = await _bluetooth.isEnabled ?? false;
    if (!isEnabled) {
      await _bluetooth.requestEnable();
    }
  }

  Future<void> _showBluetoothDialog() async {
    List<BluetoothDevice> bondedDevices = [];
    List<BluetoothDiscoveryResult> discoveredDevices = [];

    try {
      bondedDevices = await _bluetooth.getBondedDevices();
    } catch (e) {
      print("Error getting bonded devices: $e");
    }

    _bluetooth.startDiscovery().listen((result) {
      setState(() {
        if (!discoveredDevices.any((d) => d.device.address == result.device.address)) {
          discoveredDevices.add(result);
        }
      });
    });

    await Future.delayed(Duration(milliseconds: 50));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select Bluetooth Device"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...bondedDevices.map((device) {
                  return ListTile(
                    title: Text(device.name ?? "Unknown"),
                    subtitle: Text("Paired: ${device.address}"),
                    onTap: () {
                      Navigator.pop(context);
                      _connectToDevice(device);
                    },
                  );
                }),
                ...discoveredDevices.map((result) {
                  final device = result.device;
                  return ListTile(
                    title: Text(device.name ?? "Unknown"),
                    subtitle: Text("Available: ${device.address}"),
                    onTap: () {
                      Navigator.pop(context);
                      _connectToDevice(device);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      BluetoothConnection newConnection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        selectedDevice = device;
        connection = newConnection;
        isConnected = true;
      });
      print('Connected to the device');
      connection!.input!.listen((data) {
        print("Data received: ${String.fromCharCodes(data)}");
      }).onDone(() {
        setState(() {
          isConnected = false;
        });
        print('Disconnected by remote device');
      });
    } catch (e) {
      print("Connection error: $e");
    }
  }

  void sendCommand(String command) {
    if (connection != null && connection!.isConnected) {
      connection!.output.add(Uint8List.fromList(utf8.encode(command + "\n")));
      connection!.output.allSent.then((_) {
        print("Sent: $command");
      });
    } else {
      print("Not connected to any device");
    }
  }

  Widget buildTile(IconData icon, String label, VoidCallback onTap) {
    return MouseRegion(
      onEnter: (_) => setState(() {}),
      onExit: (_) => setState(() {}),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            splashColor: Colors.teal.withOpacity(0.2),
            highlightColor: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Colors.teal),
                SizedBox(height: 10),
                Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx > 10) {
          _scaffoldKey.currentState?.openDrawer();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.8,
        drawerEnableOpenDragGesture: false,
        drawer: Drawer(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0BE1CC), Color(0xFF2CDBC9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.person, size: 48, color: Colors.white),
                    SizedBox(height: 8),
                    Text("Developer", style: TextStyle(fontSize: 16, color: Colors.white70)),
                    Text("Ganapathikumar S", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text("About"),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: "LASER CNC",
                    applicationVersion: "1.0.0",
                    applicationIcon: Icon(Icons.cut),
                    children: [
                      Text("Laser cutting controller app for tailoring patterns."),
                    ],
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text("Settings"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsPage(onSendCommand: sendCommand),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        backgroundColor: Color(0xFFF0FAF9),
        body: Column(
          children: [
            GradientTitleBar(
              icon: Icons.menu,
              title: 'LASER CNC',
              device: selectedDevice,
              isConnected: isConnected,
              onBluetoothTap: _showBluetoothDialog,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    buildTile(Icons.gamepad, "Jog Control", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JogControlPage(sendCommand: sendCommand),
                        ),
                      );
                    }),
                    buildTile(Icons.cut, "Laser Cutting", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LaserCuttingPage(sendCommand: sendCommand),
                        ),
                      );
                    }),
                    buildTile(Icons.code, "Manual G-code", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManualGcodePage(
                            sendCommand: sendCommand,
                            isConnected: isConnected,
                            device: selectedDevice,
                            onBluetoothTap: _showBluetoothDialog,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


