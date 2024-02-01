import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:flutter_serial_communication/models/device_info.dart';

class FlutterSerialCom extends StatefulWidget {
  const FlutterSerialCom({super.key});

  @override
  State<FlutterSerialCom> createState() => _MyAppState();
}

class _MyAppState extends State<FlutterSerialCom> {
  final _flutterSerialCommunicationPlugin = FlutterSerialCommunication();
  bool isConnected = false;
  List<DeviceInfo> connectedDevices = [];
  String response = "check";

  @override
  void initState() {
    super.initState();

    _flutterSerialCommunicationPlugin
        .getSerialMessageListener()
        .receiveBroadcastStream()
        .listen((event) {
          setState(() {
            response=response+event.toString();
          });
      debugPrint("Received From Native:  $event");
    });

    _flutterSerialCommunicationPlugin
        .getDeviceConnectionListener()
        .receiveBroadcastStream()
        .listen((event) {
      setState(() {
        isConnected = event;
      });
    });
  }

  _getAllConnectedDevicedButtonPressed() async {
    List<DeviceInfo> newConnectedDevices =
    await _flutterSerialCommunicationPlugin.getAvailableDevices();
    setState(() {
      connectedDevices = newConnectedDevices;
    });
  }

  _connectButtonPressed(DeviceInfo deviceInfo) async {
    bool isConnectionSuccess =
    await _flutterSerialCommunicationPlugin.connect(deviceInfo, 115200);
    debugPrint("Is Connection Success:  $isConnectionSuccess");

    String cmd = "CMDSTATUSX";

    bool isMessageSent = await _flutterSerialCommunicationPlugin
        .write(Uint8List.fromList(cmd.codeUnits));

    debugPrint("Is Message Sent:  $isMessageSent");
    print(response);
  }

  _disconnectButtonPressed() async {
    await _flutterSerialCommunicationPlugin.disconnect();
  }

  _sendMessageButtonPressed() async {
    bool isMessageSent = await _flutterSerialCommunicationPlugin
        .write(Uint8List.fromList([0xBB, 0x00, 0x22, 0x00, 0x00, 0x22, 0x7E]));
    debugPrint("Is Message Sent:  $isMessageSent");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Serial Communication Example App'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text("Is Connected: $isConnected"),
              const SizedBox(height: 16.0),
              FilledButton(
                onPressed: _getAllConnectedDevicedButtonPressed,
                child: const Text("Get All Connected Devices"),
              ),
              const SizedBox(height: 16.0),
              ...connectedDevices.asMap().entries.map((entry) {
                return Row(
                  children: [
                    Flexible(child: Text(entry.value.productName)),
                    const SizedBox(width: 16.0),
                    FilledButton(
                      onPressed: () {
                        _connectButtonPressed(entry.value);
                      },
                      child: const Text("Connect"),
                    ),
                  ],
                );
              }).toList(),
              const SizedBox(height: 16.0),
              FilledButton(
                onPressed: isConnected ? _disconnectButtonPressed : null,
                child: const Text("Disconnect"),
              ),
              const SizedBox(height: 16.0),
              FilledButton(
                onPressed: isConnected ? _sendMessageButtonPressed : null,
                child: const Text("Send Message To Connected Device"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}