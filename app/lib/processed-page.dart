import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProcessedPage extends StatefulWidget {
  const ProcessedPage({super.key});

  @override
  State<ProcessedPage> createState() => _ProcessedPageState();
}

class _ProcessedPageState extends State<ProcessedPage> {
  static const platform = MethodChannel('com.example.paper_cropper/battery');
  List<String> processed = [];

  getProcessed() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getStringList("processed") != null) {
      setState(() {
        processed = prefs.getStringList("processed")!;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    getProcessed();
  }

  Future<void> delete(int i) async {
    var file = File(processed[i]);

    try {
      await file.delete();

      final prefs = await SharedPreferences.getInstance();

      if (prefs.getStringList("processed") != null) {
        var newProcessed = prefs.getStringList("processed");
        newProcessed!.removeAt(i);
        prefs.setStringList("processed", newProcessed);

        setState(() {
          processed = newProcessed;
        });
      }
    } catch (e) {
      return;
    }
  }

  void share(File file) {
    Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> copy(File file) async {
    print("copy");
    // final paths = [file.path];
    // await Pasteboard.writeFiles(paths);
    // await Clipboard.setData(ClipboardData(text: "hi"));

    file.copy((await getApplicationCacheDirectory()).path + "/" + basename(file.path));

    try {
      final result = await platform.invokeMethod<int>('copyImage', basename(file.path));
      print(result);
    } finally {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: ListView.builder(
        itemCount: processed.length,
        itemBuilder: (context, int index) {
          var imageFile = File(processed[index]);
          final dateFormatter = DateFormat.yMMMEd();
          final timeFormatter = DateFormat("jms");
          final dateCreated =
              dateFormatter.format(imageFile.lastModifiedSync());
          final timeCreated =
              timeFormatter.format(imageFile.lastModifiedSync());

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  ClipRRect(
                    clipBehavior: Clip.antiAlias,
                    borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: Image.file(imageFile),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateCreated,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            timeCreated,
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton(
                              child: const Icon(Icons.delete),
                              onPressed: () => delete(index)),
                          const SizedBox(width: 8),
                          TextButton(
                              child: const Icon(Icons.share),
                              onPressed: () => share(imageFile)),
                          const SizedBox(width: 8),
                          TextButton(
                              child: const Icon(Icons.copy),
                              onPressed: () => copy(imageFile)),
                        ],
                      )
                      // ],
                      // ),
                      // ),
                      // Row(
                      //   children: [Text("delete")],
                      // )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    ));
  }
}
