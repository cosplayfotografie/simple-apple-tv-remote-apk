import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/tv_service.dart';
import 'ui/remote_tab.dart';
import 'ui/touchpad_tab.dart';
import 'ui/apps_tab.dart';

void main() {
  runApp(const AppleTvRemoteApp());
}

class AppleTvRemoteApp extends StatelessWidget {
  const AppleTvRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ATV-RC',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: Color(0xFF1C1C1E),
        ),
      ),
      home: const RemoteScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  final TvService _tvService = TvService();
  List<TvDevice> _devices = [];
  bool _isScanning = false;
  TvDevice? _connectedDevice;
  
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _scanForDevices();
  }

  Future<void> _scanForDevices({String? manualIp}) async {
    setState(() {
      _isScanning = true;
    });
    
    try {
      final devices = await _tvService.scanDevices(manualIp: manualIp);
      setState(() {
        _devices = devices;
        _isScanning = false;
        if (_devices.isNotEmpty && _connectedDevice == null) {
          _connectToDevice(_devices.first, manualIp: manualIp);
        }
      });
      
      if (manualIp != null && devices.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kein Apple TV unter dieser IP gefunden')),
        );
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      if (mounted) {
        _showErrorDialog('Fehler beim Suchen', e.toString());
      }
    }
  }

  Future<void> _connectToDevice(TvDevice device, {String? manualIp}) async {
    try {
      bool success = await _tvService.connect(device.identifier, address: manualIp ?? device.address);
      
      if (!success) {
        bool pairingStarted = await _tvService.startPairing(device.identifier, address: manualIp ?? device.address);
        if (pairingStarted && mounted) {
          final pin = await _showPinDialog();
          if (pin != null && pin.isNotEmpty) {
            success = await _tvService.finishPairing(device.identifier, pin);
            if (success) {
              success = await _tvService.connect(device.identifier, address: manualIp ?? device.address);
            }
          }
        }
      }

      if (success) {
        setState(() {
          _connectedDevice = device;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verbunden mit ${device.name}')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verbindung fehlgeschlagen')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Fehler beim Verbinden', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(message, style: const TextStyle(fontSize: 12)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<String?> _showPinDialog() {
    String pin = "";
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text('Koppelung (Pairing)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bitte gib den 4-stelligen PIN ein, der gerade auf deinem Apple TV angezeigt wird:'),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                maxLength: 4,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: const InputDecoration(
                  counterText: "",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => pin = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Abbrechen', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, pin),
              child: const Text('Koppeln', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

  Future<void> _showManualIpDialog() async {
    String ip = "";
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text('Manuelle IP-Eingabe'),
          content: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'z.B. 192.168.1.50',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => ip = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Abbrechen', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ip),
              child: const Text('Suchen', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
    
    if (result != null && result.isNotEmpty) {
      _scanForDevices(manualIp: result);
    }
  }

  void _sendCommand(String cmd) {
    HapticFeedback.lightImpact();
    if (_connectedDevice != null) {
      _tvService.sendCommand(cmd);
    } else {
      _showNotConnectedMessage();
    }
  }

  void _sendText(String text) {
    if (_connectedDevice != null) {
      _tvService.sendText(text);
    } else {
      _showNotConnectedMessage();
    }
  }

  Future<List<Map<String, String>>> _fetchApps() async {
    if (_connectedDevice != null) {
      return await _tvService.getApps();
    } else {
      _showNotConnectedMessage();
      return [];
    }
  }

  void _launchApp(String identifier) {
    if (_connectedDevice != null) {
      _tvService.launchApp(identifier);
    } else {
      _showNotConnectedMessage();
    }
  }
  
  void _showNotConnectedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kein Apple TV verbunden')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  RemoteTab(onCommand: _sendCommand),
                  TouchpadTab(
                    onCommand: _sendCommand,
                    onSendText: _sendText,
                  ),
                  AppsTab(
                    onFetchApps: _fetchApps,
                    onLaunchApp: _launchApp,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1C1C1E),
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_remote),
            label: 'Fernbedienung',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.touch_app),
            label: 'Touchpad',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apps),
            label: 'Anwendungen',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.tv, color: Colors.white70),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showDevicePicker,
                child: Row(
                  children: [
                    Text(
                      _connectedDevice?.name ?? (_isScanning ? 'Suche...' : 'Wähle ein Apple TV'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.white),
            onPressed: () => _sendCommand('power'),
          ),
        ],
      ),
    );
  }

  void _showDevicePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_devices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text("Keine Geräte gefunden", style: TextStyle(color: Colors.white54)),
            ),
          ..._devices.map((dev) => ListTile(
            title: Text(dev.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(dev.address, style: const TextStyle(color: Colors.white54)),
            trailing: _connectedDevice?.identifier == dev.identifier 
                ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              Navigator.pop(context);
              _connectToDevice(dev);
            },
          )),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.add, color: Colors.white),
            title: const Text('IP manuell eingeben...', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showManualIpDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.white),
            title: const Text('Erneut suchen', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _scanForDevices();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
