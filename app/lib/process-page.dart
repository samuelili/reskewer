import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProcessPage extends StatefulWidget {
  final XFile imageFile;

  const ProcessPage({super.key, required this.imageFile});

  @override
  State<ProcessPage> createState() => _ProcessPageState();
}

class _ProcessPageState extends State<ProcessPage> {
  var processed = false;
  XFile? processedImageFile;

  Future<void> processImage() async {
    print("=================DOING SOMETHING================");
    // var result = await http.post(Uri.parse("http://104.248.74.122:5000/"), headers:<String, String>{

    // });
    var request = http.MultipartRequest("POST", Uri.parse("http://104.248.74.122:5000/process_image"));
    request.files.add(await http.MultipartFile.fromPath('file', widget.imageFile.path));
    var response = await request.send();
    print(response.statusCode);
    if (response.statusCode == 200) {
      var bytes = await response.stream.toBytes();

      File file = File("${(await getTemporaryDirectory()).path}/temp.png");
      file = await file.writeAsBytes(bytes);
      
      setState(() {
        processed = true;
        processedImageFile = XFile(file.path);
      });
    }
    print("=================DONE================");
  }

  confirmImage() async {
    String dirPath;
    if (Platform.isAndroid) {
      dirPath = "/storage/emulated/0/Download/";
    } else {
      dirPath = (await getDownloadsDirectory())!.path;
    }

    final imageFileName = widget.imageFile.name.split(".")[0];
    final imageFileExt = widget.imageFile.name.split(".")[1];
    final newFilePath = "$dirPath/${imageFileName}_cropped.$imageFileExt";

    await processedImageFile!.saveTo(newFilePath);

    final prefs = await SharedPreferences.getInstance();

    List<String> currProcessed = [];
    try {
      currProcessed = prefs.getStringList("processed") ?? [];
    } catch (e) {
      prefs.setStringList("processed", []);
    }

    currProcessed = [newFilePath, ...currProcessed];

    prefs.setStringList("processed", currProcessed);

    if (context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void initState() {
    super.initState();

    processImage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);

    var image = Image.file(File(widget.imageFile.path));
    if (processedImageFile != null) {
      image = Image.file(File(processedImageFile!.path));
    }
    precacheImage(image.image, context);

    Widget confirmButton;
    if (processed) {
      confirmButton = FilledButton.tonalIcon(
        style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32)),
        onPressed: confirmImage,
        icon: const Icon(Icons.check),
        label: const Text("Confirm"),
      );
    } else {
      confirmButton = FilledButton.tonalIcon(
        style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32)),
        onPressed: () {},
        icon: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeCap: StrokeCap.round,
            )),
        label: const Text("Confirm"),
      );
    }

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0),
            child: Center(
                child: Column(
              children: [
                Card.filled(
                  clipBehavior: Clip.antiAlias,
                  child: image,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 32)),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text("Cancel"),
                    ),
                    const SizedBox(width: 16),
                    confirmButton
                  ],
                )
              ],
            )),
          ),
        ),
      ),
    );
  }
}
