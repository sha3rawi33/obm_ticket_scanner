import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MaterialApp(home: MyHome()));

class MyHome extends StatelessWidget {
  const MyHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Flutter Demo Home Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => QRViewExample(),
            ));
          },
          child: Text('qrView'),
        ),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey();
  Widget status = Icon(
    Icons.camera_rounded,
    color: Colors.white,
  );
  Color buttonColor = Colors.blueAccent;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(backgroundColor: buttonColor, onPressed: () {}, child: status),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.flash_on),
              color: Colors.black,
              onPressed: () async {
                await controller?.toggleFlash();
                setState(() {});
              },
            ),
            IconButton(
              icon: Icon(Icons.camera_front),
              color: Colors.black,
              onPressed: () async {
                await controller?.flipCamera();
                setState(() {});
              },
            ),
            SizedBox(
              width: 40,
            ),
            IconButton(
              icon: Icon(Icons.stop),
              color: Colors.black,
              onPressed: () async {
                await controller?.pauseCamera();
              },
            ),
            IconButton(
              icon: Icon(Icons.play_arrow),
              color: Colors.black,
              onPressed: () async {
                await controller?.resumeCamera();
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  SizedBox(
                    height: 10,
                  ),
                  // status,
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400) ? 200.0 : 300.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.white,
        borderRadius: 30,
        borderLength: 40,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) async {
      print("SCANNED: ${scanData.code}");
      await controller.pauseCamera();
      await checkCode(scanData.code, null).then((value) {
        print(value);
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future checkCode(String? code, String? url) async {
    url = "http://gradesaver.xyz/api/users/event";
    try {
      String body = code!.replaceAll("code", "ticket");
      var response = await http.post(
        Uri.parse(url),
        body: body,
        headers: {"Accept": "*", "Content-Type": "application/json"},
      );
      final responseData = await (jsonDecode(response.body));
      final result = responseData['works'];
      print(result);
      setState(() {
        status = Icon(
          result == "True"
              ? Icons.add
              : result == "Entered"
                  ? Icons.replay_circle_filled
                  : result == "Hold"
                      ? Icons.pause
                      : Icons.error_outline,
        );
        buttonColor = result == "True"
            ? Colors.green
            : result == "Entered"
                ? Colors.black
                : result == "Hold"
                    ? Colors.yellowAccent
                    : Colors.red;
      });
      return result;
    } catch (e) {
      print(e);
    }
  }
}

// child: Row(
//   children: [
//     Text(
//       result == "True"
//           ? "Welcome! You can enter."
//           : result == "Entered"
//               ? "You've entered once before :("
//               : result == "Hold"
//                   ? "Ticket is still in hold"
//                   : "Invalid ticket!",
//       style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//     ),
//   ],
// ),
