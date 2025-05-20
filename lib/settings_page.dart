import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/gradient_title_bar.dart';

class SettingsPage extends StatefulWidget {
  final void Function(String command) onSendCommand;

  const SettingsPage({Key? key, required this.onSendCommand}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  // Jog Settings
  double jogStepXY = 1.0, jogStepZ = 10.0, jogFeedRate = 1000, jogMultiplier = 1.0;
  bool invertXY = false, invertZ = false;

  // Cut Settings
  double laserPower = 800, feedRate = 1000, materialThickness = 1.0;
  bool autoHome = false, useInches = false;

  // Calibration
  double stepsPerMM_X = 100.0, stepsPerMM_Y = 100.0, stepsPerMM_Z = 100.0;
  double maxTravel_X = 100.0, maxTravel_Y = 100.0, maxTravel_Z = 100.0;
  bool softLimitsEnabled = false, hardLimitsEnabled = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      jogStepXY = prefs.getDouble('jogStepXY') ?? 1.0;
      jogStepZ = prefs.getDouble('jogStepZ') ?? 10.0;
      jogFeedRate = prefs.getDouble('jogFeedRate') ?? 1000;
      jogMultiplier = prefs.getDouble('jogMultiplier') ?? 1.0;
      invertXY = prefs.getBool('invertXY') ?? false;
      invertZ = prefs.getBool('invertZ') ?? false;

      laserPower = prefs.getDouble('laserPower') ?? 800;
      feedRate = prefs.getDouble('feedRate') ?? 1000;
      materialThickness = prefs.getDouble('materialThickness') ?? 1.0;
      autoHome = prefs.getBool('autoHome') ?? false;
      useInches = prefs.getBool('useInches') ?? false;

      stepsPerMM_X = prefs.getDouble('stepsPerMM_X') ?? 100.0;
      stepsPerMM_Y = prefs.getDouble('stepsPerMM_Y') ?? 100.0;
      stepsPerMM_Z = prefs.getDouble('stepsPerMM_Z') ?? 100.0;
      maxTravel_X = prefs.getDouble('maxTravel_X') ?? 100.0;
      maxTravel_Y = prefs.getDouble('maxTravel_Y') ?? 100.0;
      maxTravel_Z = prefs.getDouble('maxTravel_Z') ?? 100.0;
      softLimitsEnabled = prefs.getBool('softLimitsEnabled') ?? false;
      hardLimitsEnabled = prefs.getBool('hardLimitsEnabled') ?? false;
    });
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble('jogStepXY', jogStepXY);
    await prefs.setDouble('jogStepZ', jogStepZ);
    await prefs.setDouble('jogFeedRate', jogFeedRate);
    await prefs.setDouble('jogMultiplier', jogMultiplier);
    await prefs.setBool('invertXY', invertXY);
    await prefs.setBool('invertZ', invertZ);

    await prefs.setDouble('laserPower', laserPower);
    await prefs.setDouble('feedRate', feedRate);
    await prefs.setDouble('materialThickness', materialThickness);
    await prefs.setBool('autoHome', autoHome);
    await prefs.setBool('useInches', useInches);

    await prefs.setDouble('stepsPerMM_X', stepsPerMM_X);
    await prefs.setDouble('stepsPerMM_Y', stepsPerMM_Y);
    await prefs.setDouble('stepsPerMM_Z', stepsPerMM_Z);
    await prefs.setDouble('maxTravel_X', maxTravel_X);
    await prefs.setDouble('maxTravel_Y', maxTravel_Y);
    await prefs.setDouble('maxTravel_Z', maxTravel_Z);
    await prefs.setBool('softLimitsEnabled', softLimitsEnabled);
    await prefs.setBool('hardLimitsEnabled', hardLimitsEnabled);

    widget.onSendCommand("SETTINGS_UPDATED");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Settings saved")),
    );
  }

  void resetAxisPositionToZero() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Zero X and Y"),
        content: const Text("Set current machine position as X=0 and Y=0? (G92 X0 Y0)"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text("Zero Now"),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      widget.onSendCommand("G92 X0 Y0");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Current X and Y set to 0")),
      );
    }
  }

  Widget sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF2CDBC9), size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget numberField(String label, double value, Function(double) onChanged, {String? suffix}) {
    final controller = TextEditingController(text: value.toString());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (suffix != null ? ' ($suffix)' : ''),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (val) {
          final d = double.tryParse(val ?? '');
          if (d == null || d < 0) return 'Enter a valid positive number';
          return null;
        },
        onChanged: (val) => onChanged(double.tryParse(val) ?? 0),
      ),
    );
  }

  Widget buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle(title, icon),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: GradientTitleBar(
          title: '⚙️ Settings',
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Apply Settings',
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  saveSettings();
                }
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildSection("Jog Settings", Icons.directions_run, [
                numberField("Jog Step XY", jogStepXY, (v) => jogStepXY = v, suffix: "mm"),
                numberField("Jog Step Z", jogStepZ, (v) => jogStepZ = v, suffix: "mm"),
                numberField("Jog Feedrate", jogFeedRate, (v) => jogFeedRate = v, suffix: "mm/min"),
                numberField("Jog Multiplier", jogMultiplier, (v) => jogMultiplier = v),
                SwitchListTile(title: const Text("Invert XY Axis"), value: invertXY, onChanged: (v) => setState(() => invertXY = v)),
                SwitchListTile(title: const Text("Invert Z Axis"), value: invertZ, onChanged: (v) => setState(() => invertZ = v)),
              ]),
              buildSection("Cut Settings", Icons.cut, [
                numberField("Laser Power", laserPower, (v) => laserPower = v, suffix: "S value"),
                numberField("Feedrate", feedRate, (v) => feedRate = v, suffix: "mm/min"),
                numberField("Material Thickness", materialThickness, (v) => materialThickness = v, suffix: "mm"),
                SwitchListTile(title: const Text("Auto Home"), value: autoHome, onChanged: (v) => setState(() => autoHome = v)),
                SwitchListTile(title: const Text("Use Inches"), value: useInches, onChanged: (v) => setState(() => useInches = v)),
              ]),
              buildSection("Calibration", Icons.tune, [
                numberField("Steps/mm X", stepsPerMM_X, (v) => stepsPerMM_X = v),
                numberField("Steps/mm Y", stepsPerMM_Y, (v) => stepsPerMM_Y = v),
                numberField("Steps/mm Z", stepsPerMM_Z, (v) => stepsPerMM_Z = v),
                numberField("Max Travel X", maxTravel_X, (v) => maxTravel_X = v, suffix: "mm"),
                numberField("Max Travel Y", maxTravel_Y, (v) => maxTravel_Y = v, suffix: "mm"),
                numberField("Max Travel Z", maxTravel_Z, (v) => maxTravel_Z = v, suffix: "mm"),
                SwitchListTile(title: const Text("Enable Soft Limits"), value: softLimitsEnabled, onChanged: (v) => setState(() => softLimitsEnabled = v)),
                SwitchListTile(title: const Text("Enable Hard Limits"), value: hardLimitsEnabled, onChanged: (v) => setState(() => hardLimitsEnabled = v)),
              ]),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.my_location),
                label: const Text("Set X & Y to Zero"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: resetAxisPositionToZero,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
