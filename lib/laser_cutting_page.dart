import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class LaserCuttingPage extends StatefulWidget {
  final BluetoothConnection? connection;
  final Function(String) sendCommand;

  const LaserCuttingPage({Key? key, this.connection, required this.sendCommand}) : super(key: key);

  @override
  _LaserCuttingPageState createState() => _LaserCuttingPageState();
}

class _LaserCuttingPageState extends State<LaserCuttingPage> {
  BluetoothConnection? connection;

  String? selectedDressType;
  String? selectedSize;
  String? selectedMaterial;

  String? modifiedGCode = '';
  bool isLoadingGCode = false;
  bool isSendingGCode = false; // Track if G-code is currently being sent

  final dressTypes = ['Half Sleeve Shirt', 'Full Sleeve Shirt'];
  final sizes = ['S', 'M', 'L', 'XL'];
  final materials = ['Cotton', 'Polyester', 'Nylon', 'Linen'];

  final Map<String, Map<String, int>> materialSettings = {
    'Cotton': {'S': 1000, 'F': 100},
    'Nylon': {'S': 800, 'F': 150},
    'Polyester': {'S': 900, 'F': 120},
    'Linen': {'S': 1100, 'F': 90},
  };

  @override
  void initState() {
    super.initState();
    connection = widget.connection;

    if (connection != null) {
      print("Connection received, isConnected: ${connection!.isConnected}");
    } else {
      print("No Bluetooth connection passed.");
    }
  }

  Future<void> loadAndModifyGCode() async {
    if (selectedDressType == null || selectedSize == null || selectedMaterial == null) return;

    setState(() => isLoadingGCode = true);

    final settings = materialSettings[selectedMaterial]!;
    final int power = settings['S']!;
    final int feed = settings['F']!;

    try {
      String rawGCode = await rootBundle.loadString('assets/gcode/s_gcode.gcode');
      List<String> lines = rawGCode.split('\n');
      List<String> modifiedLines = lines.map((line) {
        if (line.contains(RegExp(r'\bS\d+\b'))) {
          line = line.replaceAllMapped(RegExp(r'\bS\d+\b'), (match) => 'S$power');
        }
        if (line.contains(RegExp(r'\bF\d+\b'))) {
          line = line.replaceAllMapped(RegExp(r'\bF\d+\b'), (match) => 'F$feed');
        }
        return line;
      }).toList();

      setState(() {
        modifiedGCode = modifiedLines.join('\n');
        isLoadingGCode = false;
      });
    } catch (e) {
      setState(() => isLoadingGCode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading G-code file.")),
      );
      print("Error loading G-code: $e");
    }
  }

  Future<void> sendGCodeToBluetooth() async {
    if (modifiedGCode == null || modifiedGCode!.isEmpty || isSendingGCode) {
      if (isSendingGCode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("G-code sending in progress.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No G-code generated.")),
        );
      }
      return;
    }

    setState(() => isSendingGCode = true);

    List<String> lines = modifiedGCode!.split('\n');

    for (var line in lines) {
      widget.sendCommand(line.trim()); // Trim whitespace to avoid issues
      await Future.delayed(Duration(milliseconds: 150)); // Increased delay for reliability
    }

    setState(() => isSendingGCode = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("G-code sent to device!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool allSelected = selectedDressType != null && selectedSize != null && selectedMaterial != null;

    return Scaffold(
      backgroundColor: Color(0xFFF0FAF9),
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildDropdown(
                    label: "Dress Type",
                    value: selectedDressType,
                    items: dressTypes,
                    onChanged: (val) {
                      setState(() {
                        selectedDressType = val;
                      });
                      loadAndModifyGCode();
                    },
                  ),
                  Text("Select Size", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 10),
                  buildSizeChips(),
                  SizedBox(height: 20),
                  buildDropdown(
                    label: "Material",
                    value: selectedMaterial,
                    items: materials,
                    onChanged: (val) {
                      setState(() {
                        selectedMaterial = val;
                      });
                      loadAndModifyGCode();
                    },
                  ),
                  if (allSelected) ...[
                    SizedBox(height: 20),
                    Text("PATTERN (${selectedSize!} size):", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    _buildSvgPreview(),
                    SizedBox(height: 20),
                    Text("G-code:", style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildGCodeDisplay(),
                    SizedBox(height: 30),
                    _buildStartButton(),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 4),
          Icon(Icons.cut, color: Colors.white, size: 30),
          SizedBox(width: 12),
          Text(
            'Laser Cutting',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSvgPreview() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: SvgPicture.asset(
        'assets/svg/s_svg.svg',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildGCodeDisplay() {
    return Container(
      height: 150,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: isLoadingGCode
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(child: SelectableText(modifiedGCode ?? '')),
    );
  }

  Widget _buildStartButton() {
    return Center(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isSendingGCode)
              BoxShadow(color: Colors.tealAccent, blurRadius: 20, spreadRadius: 1),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: isSendingGCode ? null : sendGCodeToBluetooth, // Disable button while sending
          icon: Icon(Icons.play_arrow),
          label: Text(
            isSendingGCode ? "Sending..." : "Start Laser Cutting",
            style: TextStyle(color: Colors.black87),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0BE1CC),
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Widget buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            hint: Text("Select $label"),
            icon: Icon(Icons.keyboard_arrow_down),
            decoration: InputDecoration(border: InputBorder.none),
            onChanged: onChanged,
            items: items
                .map((item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: TextStyle(fontSize: 15)),
            ))
                .toList(),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget buildSizeChips() {
    return Wrap(
      spacing: 10,
      children: sizes.map((size) {
        final selected = size == selectedSize;
        return ChoiceChip(
          label: Text(
            size,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          selected: selected,
          onSelected: (_) {
            setState(() => selectedSize = size);
            loadAndModifyGCode();
          },
          selectedColor: Color(0xFF0BE1CC),
          backgroundColor: Colors.white,
        );
      }).toList(),
    );
  }
}