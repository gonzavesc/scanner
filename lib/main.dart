import 'dart:async';
import 'dart:io' show Platform;
import 'dart:io';
import 'dart:convert';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(_MyApp());
}

class _MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<_MyApp> {
  ScanResult scanResult;
  String _host = "IP";
  String path = 'api/order-candidate';

  Map jsonData = {
    'orderAmount': '',
    'lat': '41.1',
    'lon': '0.3',
    'contactIdentifier': ''
  };

  Future apiTest() async {
    HttpClientRequest request = await HttpClient().post(_host, 8080, path) /*1*/
      ..headers.contentType = ContentType.json /*2*/
      ..write(jsonEncode(jsonData)); /*3*/
    HttpClientResponse response = await request.close(); /*4*/
    await utf8.decoder.bind(response /*5*/).forEach(print);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Barcode Scanner Example'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.camera),
              tooltip: "Scan",
              onPressed: scan,
            )
          ],
        ),
        body: Text(scanResult.rawContent ?? ""),
      ),
    );
  }

  Future scan() async {
    try {
      var result = await BarcodeScanner.scan();

      setState(() => scanResult = result);
    } on PlatformException catch (e) {
      var result = ScanResult(
        type: ResultType.Error,
        format: BarcodeFormat.unknown,
      );

      if (e.code == BarcodeScanner.cameraAccessDenied) {
        setState(() {
          result.rawContent = 'The user did not grant the camera permission!';
        });
      } else {
        result.rawContent = 'Unknown error: $e';
      }
      setState(() {
        scanResult = result;
      });
    }
  }
}
