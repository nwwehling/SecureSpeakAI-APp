import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'mfcc_extraction.dart';
import 'package:url_launcher/url_launcher.dart';


class ResultsPage extends StatefulWidget {
  final List<String> receivedLinks;

  ResultsPage({required this.receivedLinks});

  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  String _inferenceResult = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _processLinks();
  }

  Future<void> _processLinks() async {
    for (String link in widget.receivedLinks) {
      try {
        String videoUrl = await _getVideoUrl(link);
        if (videoUrl.isNotEmpty) {
          String videoPath = await _downloadVideo(videoUrl);
          if (videoPath.isNotEmpty) {
            String audioPath = await _extractAudio(videoPath);
            List<List<double>> mfcc = await extractMFCC(audioPath);
            Interpreter interpreter = await _downloadModel();
            await _runInference(interpreter, mfcc);
          }
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  Future<String> _getVideoUrl(String pageUrl) async {
    try {
      final response = await http.get(
        Uri.parse(pageUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3',
        },
      );
      if (response.statusCode == 200) {
        final regExp = RegExp(r'"video_url":"([^"]+)"');
        final match = regExp.firstMatch(response.body);
        if (match != null) {
          final videoUrl = match.group(1)!.replaceAll(r'\u0026', '&');
          return videoUrl;
        } else {
          throw Exception('Video URL not found');
        }
      } else {
        throw Exception('Failed to load page');
      }
    } catch (e) {
      print('Error extracting video URL: $e');
      return '';
    }
  }

  Future<String> _downloadVideo(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Directory tempDir = await getTemporaryDirectory();
        String tempPath = tempDir.path;
        String filePath = '$tempPath/video.mp4';
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Verify if the file is a valid video
        final session = await FFmpegKit.execute('-i $filePath -hide_banner');
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          return filePath;
        } else {
          throw Exception('Invalid video file');
        }
      } else {
        throw Exception('Failed to download video');
      }
    } catch (e) {
      print('Error downloading video: $e');
      return '';
    }
  }

  Future<String> _extractAudio(String videoPath) async {
    Directory tempDir = await getTemporaryDirectory();
    String audioPath = '${tempDir.path}/audio.wav';

    // Ensure the audio file does not already exist
    File audioFile = File(audioPath);
    if (audioFile.existsSync()) {
      audioFile.deleteSync();
    }

    await FFmpegKit.execute('-i $videoPath -vn -acodec pcm_s16le -ar 16000 -ac 1 $audioPath');
    return audioPath;
  }

  Future<Interpreter> _downloadModel() async {
    final conditions = FirebaseModelDownloadConditions(
      iosAllowsBackgroundDownloading: true,
      iosAllowsCellularAccess: true,
    );

    final model = await FirebaseModelDownloader.instance.getModel(
      'SecureSpeakModel',
      FirebaseModelDownloadType.localModelUpdateInBackground,
      conditions,
    );

    final modelPath = model.file?.path ?? '';
    if (modelPath.isEmpty) {
      throw Exception('Model path is null or empty');
    }

    return Interpreter.fromFile(File(modelPath));
  }

  Future<void> _runInference(Interpreter interpreter, List<List<double>> mfcc) async {
    if (mfcc.isEmpty || mfcc.any((frame) => frame.length != 13)) {
      setState(() {
        _errorMessage = 'Invalid MFCC data';
      });
      return;
    }

    final flatMfcc = mfcc.expand((i) => i).toList();
    final input = ReshapeListExtension(flatMfcc).reshapeCustom([1, 1071, 13, 1]);

    // Run inference
    final output = ReshapeListExtension(List.filled(1, 0.0)).reshapeCustom([1, 1]);
    interpreter.run(input, output);

    final prediction = output[0][0];
    final label = prediction > 0.5 ? "AI" : "Human";
    final confidence = label == "AI" ? prediction : 1 - prediction;

    setState(() {
      _inferenceResult = "The audio is predicted to be: $label\nConfidence: $confidence";
      _errorMessage = '';
    });

    interpreter.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results Page'),
        backgroundColor: Color(0xFF22223B),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Results Page',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            if (_inferenceResult.isNotEmpty)
              Text(
                _inferenceResult,
                style: TextStyle(fontSize: 16),
              ),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.receivedLinks.length,
                itemBuilder: (context, index) {
                  final link = widget.receivedLinks[index];
                  return ListTile(
                    title: Text(link),
                    onTap: () => _launchURL(link),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

extension ReshapeListExtension on List {
  List reshapeCustom(List<int> dims) {
    if (dims.length == 1) {
      return this;
    } else {
      int dim = dims.first;
      List result = [];
      int step = (this.length / dim).ceil();
      for (int i = 0; i < dim; i++) {
        result.add(this.sublist(i * step, (i + 1) * step).reshapeCustom(dims.sublist(1)));
      }
      return result;
    }
  }
}
