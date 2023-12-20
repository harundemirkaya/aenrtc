// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart';
import 'package:web_socket_channel/io.dart';
import 'package:image/image.dart' as imglib;

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraApp(),
    );
  }
}

class CameraApp extends StatefulWidget {
  const CameraApp({super.key});

  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool isStreaming = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      cameras![1],
      ResolutionPreset.low,
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      listenCamera();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void listenCamera() {
    final channel = IOWebSocketChannel.connect(
        'ws://192.168.2.210:7001/CommunicationServer',
        headers: {
          'Authorization':
              "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhLnRvbGdhLm96IiwibmFtZWlkIjoiYS50b2xnYS5veiIsImp0aSI6IjRmY2U0MmVjLTZkYzMtNDhmNC04OWUxLWZkMjc2NDY1NWVhNSIsImh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vd3MvMjAwOC8wNi9pZGVudGl0eS9jbGFpbXMvcm9sZSI6IkhPU1BJVEFMIiwiQXBwbGljYXRpb25UeXBlIjoiSE9TUElUQUwiLCJleHAiOjE3MDMyMzQzMjcsImlzcyI6Imh0dHBzOi8vaGFzdGFuZS5jb20iLCJhdWQiOiJIYXN0YW5lQXBpIn0.fWgeH-jHkzaQgNrfqTwACdmO0pO78mK-734um9d3eN4"
        });

    channel.sink.add('{"protocol":"json","version":1}');
    cameras != null && isStreaming
        ? _controller.startImageStream((CameraImage availableImage) {
            if (availableImage.planes.isEmpty) {
              print('availableImage must not be null');
              return;
            } else {
              imglib.Image im = imglib.Image.fromBytes(
                  height: availableImage.height,
                  width: availableImage.width,
                  bytes: (availableImage.planes[0].bytes).buffer,
                  format: imglib.Format.uint8,
                  order: ChannelOrder.bgra);
              List<int> jpegBytes = imglib.encodeJpg(im);

              int chunkSize = 4096; // Parça boyutu
              int offset = 0;

              while (offset < jpegBytes.length) {
                int end = (offset + chunkSize < jpegBytes.length)
                    ? offset + chunkSize
                    : jpegBytes.length;
                List<int> chunk = jpegBytes.sublist(offset, end);
                channel.sink.add(
                    '{"arguments": [{"messageType": 4,"fromUser": "a.tolga.oz","ToUser": "admin","data": $chunk, "limit": ${(jpegBytes.length == end) ? 1 : 0}, "offset": $offset}],"target": "Video","type": 1}');
                if (offset == jpegBytes.length) {
                  print("aaa");
                }
                if (jpegBytes.length < 20000 && (jpegBytes.length == end)) {
                  print("aaa");
                }
                offset = end;
              }
            }
          })
        // ignore: avoid_print
        : print("Kamera bulunamadı");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WEB RTC'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                CameraPreview(_controller),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isStreaming = !isStreaming;
                      });
                      !isStreaming
                          ? _controller.stopImageStream()
                          : listenCamera();
                    },
                    child: Text("Durdur - Başlat"))
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
