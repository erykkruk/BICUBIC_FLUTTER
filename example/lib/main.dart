import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bicubic_resize/flutter_bicubic_resize.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bicubic Resize Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ResizeDemo(),
    );
  }
}

class ResizeDemo extends StatefulWidget {
  const ResizeDemo({super.key});

  @override
  State<ResizeDemo> createState() => _ResizeDemoState();
}

class _ResizeDemoState extends State<ResizeDemo> {
  Uint8List? _originalBytes;
  Uint8List? _resizedBytes;
  bool _isLoading = false;
  int _resizeTimeMs = 0;
  int _outputWidth = 224;
  int _outputHeight = 224;
  double _crop = 1.0;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final format = BicubicResizer.detectFormat(bytes);

    debugPrint('Image format: ${format?.name ?? "unsupported"}, size: ${bytes.length} bytes');

    if (format == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unsupported format! Please select JPEG or PNG image.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _originalBytes = bytes;
      _resizedBytes = null;
      _resizeTimeMs = 0;
    });
  }

  Future<void> _resizeImage() async {
    if (_originalBytes == null) return;

    setState(() {
      _isLoading = true;
    });

    final stopwatch = Stopwatch()..start();

    try {
      final resized = BicubicResizer.resize(
        bytes: _originalBytes!,
        outputWidth: _outputWidth,
        outputHeight: _outputHeight,
        quality: 95,
        crop: _crop,
      );

      stopwatch.stop();

      setState(() {
        _resizedBytes = resized;
        _resizeTimeMs = stopwatch.elapsedMilliseconds;
        _isLoading = false;
      });
    } on UnsupportedImageFormatException catch (e) {
      stopwatch.stop();
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Bicubic Resize Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Pick Image'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Output Width',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: '$_outputWidth'),
                    onChanged: (value) {
                      _outputWidth = int.tryParse(value) ?? 224;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Output Height',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: '$_outputHeight'),
                    onChanged: (value) {
                      _outputHeight = int.tryParse(value) ?? 224;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Crop: ${(_crop * 100).toStringAsFixed(0)}%'),
                Expanded(
                  child: Slider(
                    value: _crop,
                    min: 0.1,
                    max: 1.0,
                    divisions: 18,
                    label: '${(_crop * 100).toStringAsFixed(0)}%',
                    onChanged: (value) {
                      setState(() {
                        _crop = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _originalBytes != null && !_isLoading
                  ? _resizeImage
                  : null,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.transform),
              label: Text(_isLoading ? 'Resizing...' : 'Resize to ${_outputWidth}x$_outputHeight${_crop < 1.0 ? ' (crop ${(_crop * 100).toStringAsFixed(0)}%)' : ''}'),
            ),
            if (_resizeTimeMs > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Resize time: $_resizeTimeMs ms',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            if (_originalBytes != null) ...[
              Text(
                'Original (${_originalBytes!.length} bytes)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _originalBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
            if (_resizedBytes != null) ...[
              const SizedBox(height: 24),
              Text(
                'Resized ${_outputWidth}x$_outputHeight (${_resizedBytes!.length} bytes)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _resizedBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
