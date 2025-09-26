
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'dart:async';

enum CameraAction {
  takePicture,
  startVideo,
  stopVideo,
  switchCamera,
  toggleFlash,
  toggleHarmonizer,
  togglePhotoMode,
  toggleVideoMode,
}

class VoiceCommandService {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  Timer? _timer;

  final StreamController<CameraAction> _actionController = StreamController<CameraAction>.broadcast();
  Stream<CameraAction> get actionStream => _actionController.stream;

  final StreamController<bool> _listeningStateController = StreamController<bool>.broadcast();
  Stream<bool> get listeningStateStream => _listeningStateController.stream;

  Future<void> init() async {
    _speechEnabled = await _speechToText.initialize();
  }

  void startListening() {
    if (!_speechEnabled) {
      return;
    }
    _speechToText.listen(onResult: _onSpeechResult);
    _listeningStateController.add(true);
  }

  void stopListening() {
    _speechToText.stop();
    _listeningStateController.add(false);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      _lastWords = result.recognizedWords.toLowerCase();
      _processCommand(_lastWords);
    }
  }

  void _processCommand(String command) {
    if (command.contains('take picture') || command.contains('capture') || command.contains('photo')) {
      _actionController.add(CameraAction.takePicture);
      stopListening();
    } else if (command.contains('start video') || command.contains('record video')) {
      _actionController.add(CameraAction.startVideo);
      stopListening();
    } else if (command.contains('stop video')) {
      _actionController.add(CameraAction.stopVideo);
      stopListening();
    } else if (command.contains('switch camera') || command.contains('front camera') || command.contains('back camera')) {
      _actionController.add(CameraAction.switchCamera);
      stopListening();
    } else if (command.contains('toggle flash') || command.contains('flash on') || command.contains('flash off')) {
      _actionController.add(CameraAction.toggleFlash);
      stopListening();
    } else if (command.contains('toggle harmonizer') || command.contains('harmonizer on') || command.contains('harmonizer off') || command.contains('turn on harmoniser') || command.contains('turn off harmoniser') || command.contains('harmoniser on') || command.contains('harmoniser off')) {
      _actionController.add(CameraAction.toggleHarmonizer);
      stopListening();
    } else if (command.contains('photo mode')) {
      _actionController.add(CameraAction.togglePhotoMode);
      stopListening();
    } else if (command.contains('video mode')) {
      _actionController.add(CameraAction.toggleVideoMode);
      stopListening();
    }
  }

  void dispose() {
    _actionController.close();
    _listeningStateController.close();
    _timer?.cancel();
  }
}
