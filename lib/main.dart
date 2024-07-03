import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: VibrationControlScreen(),
    );
  }
}

class VibrationControlScreen extends StatefulWidget {
  const VibrationControlScreen({super.key});

  @override
  VibrationControlScreenState createState() => VibrationControlScreenState();
}

class VibrationControlScreenState extends State<VibrationControlScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? device;
  BluetoothCharacteristic? characteristic;
  bool isVibrating = false;

  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }

void _connectToDevice() async {
  try {
    // First, check if the device is already connected
    List<BluetoothDevice> connectedDevices = await flutterBlue.connectedDevices;
    device = connectedDevices.firstWhere(
      (device) => device.id.toString() == 'd3:24:15:35:3f:b5',
      // orElse: () => print('Hi'),
    );

    if (device == null) {
      // If device is not already connected, start scanning for devices
      flutterBlue.startScan(timeout: const Duration(seconds: 4));
      var scanSubscription = flutterBlue.scanResults.listen((results) async {
        // Iterate through scan results to find the desired device
        for (ScanResult result in results) {
          if (result.device.id.toString() == 'd3:24:15:35:3f:b5') {
            device = result.device;
            flutterBlue.stopScan();
            try {
              await device!.connect();
              device!.state.listen((state) {
                if (state == BluetoothDeviceState.connected) {
                  device!.discoverServices().then((services) {
                    for (var service in services) {
                      for (var char in service.characteristics) {
                        if (char.uuid.toString() == '00002002-0000-1000-8000-00805f9b34fb') {
                          characteristic = char;
                          break;
                        }
                      }
                    }
                  });
                }
              });
            } catch (e) {
              if (kDebugMode) {
                print('Error connecting to device: $e');
              }
            }
            break;
          }
        }
      });

      // Cancel scanning after 4 seconds
      await Future.delayed(const Duration(seconds: 4));
      await scanSubscription.cancel();
    }

    setState(() {
      device = device; // Redundant line, you may remove it
    });
  } catch (e) {
    if (kDebugMode) {
      print('Error scanning/connecting to device: $e');
    }
  }
}


  void _startVibration() async {
    if (characteristic != null) {
      try {
        await characteristic!.write([1]);
        setState(() {
          isVibrating = true;
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error starting vibration: $e');
        }
      }
    }
  }

  void _stopVibration() async {
    if (characteristic != null) {
      try {
        await characteristic!.write([0]);
        setState(() {
          isVibrating = false;
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error stopping vibration: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nosiefit Watch Control'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => _startVibration(),
              onLongPress: () => _stopVibration(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: Text(
                isVibrating ? 'Vibrating...' : 'Vibe',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
