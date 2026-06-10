import 'package:audioplayers/audioplayers.dart';

/// Layanan audio global untuk memutar notifikasi suara
/// Menggunakan singleton pattern agar hanya ada satu instance AudioPlayer
class AudioService {
  static final AudioService _instance = AudioService._internal();

  late final AudioPlayer _audioPlayer;
  final Map<String, String> _lastQueueStatuses = {};

  AudioService._internal() {
    _audioPlayer = AudioPlayer();
  }

  factory AudioService() {
    return _instance;
  }

  /// Putar suara bell ketika antrean berubah menjadi dipanggil
  Future<void> handleQueueStatus(String queueIdentifier, String queueStatus) async {
    if (queueIdentifier.isEmpty) return;

    final previousStatus = _lastQueueStatuses[queueIdentifier];
    final isCurrentlyCalled = queueStatus.contains('dipanggil');
    final wasPreviouslyCalled = previousStatus?.contains('dipanggil') ?? false;

    if (isCurrentlyCalled && !wasPreviouslyCalled) {
      try {
        await _audioPlayer.play(AssetSource('sounds/bell.wav'));
      } catch (e) {
        // Ignore playback errors to avoid crashing the UI
        print('Error playing notification sound: $e');
      }
    }

    _lastQueueStatuses[queueIdentifier] = queueStatus;
  }

  void clearLastCalledNotification(String queueIdentifier) {
    _lastQueueStatuses.remove(queueIdentifier);
  }

  /// Dispose audio player (panggil saat aplikasi shutdown)
  void dispose() {
    _audioPlayer.dispose();
  }
}
