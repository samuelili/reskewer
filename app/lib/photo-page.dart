import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:paper_cropper/process-page.dart';
import 'package:photo_gallery/photo_gallery.dart';

class CapturePage extends StatefulWidget {
  final void Function(int)? onChangeSelectedPage;
  const CapturePage({super.key, this.onChangeSelectedPage});

  @override
  State<CapturePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<CapturePage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                  child: CameraCapture(
                onChangeSelectedPage: widget.onChangeSelectedPage,
              )),
              const SizedBox(height: 16),
              Gallery(
                onChangeSelectedPage: widget.onChangeSelectedPage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CameraCapture extends StatefulWidget {
  final void Function(int)? onChangeSelectedPage;
  const CameraCapture({super.key, this.onChangeSelectedPage});

  @override
  State<CameraCapture> createState() => _CameraCaptureState();
}

class _CameraCaptureState extends State<CameraCapture> {
  late CameraDescription camera;
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  Future<void> initializeCamera() async {
    // Obtain a list of the available cameras on the device.
    final cameras = await availableCameras();

    // Get a specific camera from the list of available cameras.
    camera = cameras.first;

    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    await _controller.initialize();
  }

  Future<void> captureImage(BuildContext context) async {
    // Take the Picture in a try / catch block. If anything goes wrong,
    // catch the error.
    try {
      // Ensure that the camera is initialized.
      await _initializeControllerFuture;

      // Attempt to take a picture and then get the location
      // where the image file is saved.
      final imageFile = await _controller.takePicture();

      if (!context.mounted) {
        return;
      }

      await precacheImage(FileImage(File(imageFile.path)), context);

      if (!context.mounted) {
        return;
      }

      var result = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProcessPage(imageFile: imageFile)));

      if (result != null && widget.onChangeSelectedPage != null) {
        widget.onChangeSelectedPage?.call(1);
      }
    } catch (e) {
      // If an error occurs, log the error to the console.
      print("error ${e}");
    }
  }

  @override
  void initState() {
    super.initState();

    _initializeControllerFuture = initializeCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Card.filled(
            clipBehavior: Clip.antiAlias,
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // If the Future is complete, display the preview.
                  return CameraPreview(_controller);
                } else {
                  // Otherwise, display a loading indicator.
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 64,
          height: 64,
          child: IconButton.filled(
            onPressed: () {
              captureImage(context);
            },
            icon: const Icon(Icons.camera),
          ),
        )
      ],
    );
  }
}

class Gallery extends StatefulWidget {
  final void Function(int)? onChangeSelectedPage;
  const Gallery({super.key, this.onChangeSelectedPage});

  @override
  State<Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  List<Image?>? _images;
  List<File?>? _files;

  Timer? timer;

  Future<void> _getImages() async {
    print("Checking for images");
    final Album imageAlbum = (await PhotoGallery.listAlbums()).first;
    List<Medium> allImages = (await imageAlbum.listMedia()).items;

    allImages.sort((a, b) {
      if (a.creationDate == null && b.creationDate == null) {
        return 0;
      } else if (a.creationDate == null) {
        return -1;
      } else if (b.creationDate == null) {
        return 1;
      } else {
        return b.creationDate!.millisecondsSinceEpoch -
            a.creationDate!.millisecondsSinceEpoch;
      }
    });

    List<Image?> images = [null, null, null];
    List<File?> files = [null, null, null];

    for (var i = 0; i < min(allImages.length, 3); i++) {
      files[i] = await allImages[i].getFile();
      images[i] = Image.file(await allImages[i].getFile());
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _files = files;
      _images = images;
    });
  }

  @override
  void initState() {
    super.initState();

    timer =
        Timer.periodic(const Duration(seconds: 3), (Timer t) => _getImages());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> selectImage(int i) async {
    var file = _files![i];
    if (file == null) {
      return;
    }

    var result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProcessPage(imageFile: XFile(file.path))));

    if (result != null && widget.onChangeSelectedPage != null) {
      widget.onChangeSelectedPage?.call(1);
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);

    if (!mounted) {
      return;
    }

    if (result != null) {
      File file = File(result.files.single.path!);
      var navigateResult = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProcessPage(imageFile: XFile(file.path))));

      if (navigateResult != null && widget.onChangeSelectedPage != null) {
        widget.onChangeSelectedPage?.call(1);
      }
    } else {
      // User canceled the picker
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_images == null) {
      return LayoutBuilder(builder: (context, BoxConstraints constraints) {
        const scale = 1 / 4;

        return SizedBox(
          width: constraints.maxWidth,
          child: Row(
            children: [
              SizedBox(
                width: constraints.maxWidth * scale,
                height: constraints.maxWidth * scale,
                child: const Card.filled(),
              ),
              SizedBox(
                width: constraints.maxWidth * scale,
                height: constraints.maxWidth * scale,
                child: const Card.filled(),
              ),
              SizedBox(
                width: constraints.maxWidth * scale,
                height: constraints.maxWidth * scale,
                child: const Card.filled(),
              ),
              SizedBox(
                width: constraints.maxWidth * scale,
                height: constraints.maxWidth * scale,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: IconButton.filled(
                      onPressed: pickFile, icon: const Icon(Icons.library_add)),
                ),
              ),
            ],
          ),
        );
      });
    } else {
      return LayoutBuilder(builder: (context, BoxConstraints constraints) {
        final scale = 1 / (_images!.length + 1);

        return SizedBox(
          width: constraints.maxWidth,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => selectImage(0),
                child: SizedBox(
                  width: constraints.maxWidth * scale,
                  height: constraints.maxWidth * scale,
                  child: DeviceImage(
                    image: _images![0],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => selectImage(1),
                child: SizedBox(
                  width: constraints.maxWidth * scale,
                  height: constraints.maxWidth * scale,
                  child: DeviceImage(
                    image: _images![1],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => selectImage(2),
                child: SizedBox(
                  width: constraints.maxWidth * scale,
                  height: constraints.maxWidth * scale,
                  child: DeviceImage(
                    image: _images![2],
                  ),
                ),
              ),
              SizedBox(
                width: constraints.maxWidth * scale,
                height: constraints.maxWidth * scale,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: IconButton.filled(
                      onPressed: pickFile, icon: const Icon(Icons.library_add)),
                ),
              ),
            ],
          ),
        );
      });
    }
  }
}

class DeviceImage extends StatelessWidget {
  final Image? image;

  const DeviceImage({super.key, this.image});

  @override
  Widget build(BuildContext context) {
    if (image == null) {
      return const Card.filled(
          child: Center(child: Icon(Icons.image_not_supported_rounded)));
    } else {
      return Card.filled(
          clipBehavior: Clip.antiAlias,
          child: FittedBox(fit: BoxFit.cover, child: image));
    }
  }
}
