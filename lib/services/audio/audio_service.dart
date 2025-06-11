import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// 앱에서 사용되는 오디오를 관리하는 서비스
class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  final AudioPlayer _player = AudioPlayer();
  String? _currentAudioAsset;
  bool _isLooping = false;

  AudioService._internal();

  /// 현재 재생 중인 오디오가 완료될 때까지 기다립니다.
  Future<void> _waitForCompletion() async {
    if (_player.playing) {
      // 현재 재생이 완료될 때까지 기다림
      await _player.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );
    }
  }

  /// 특정 오디오 파일을 한 번 재생합니다.
  Future<void> playOnce(String audioAsset) async {
    try {
      if (isLooping) {
        await stop();
      } else {
        await _waitForCompletion();
      }

      if (_currentAudioAsset != audioAsset) {
        await _player.setAsset(audioAsset);
        _currentAudioAsset = audioAsset;
      }

      _isLooping = false;
      await _player.setLoopMode(LoopMode.off);
      await _player.seek(Duration.zero);
      await _player.play();

      debugPrint('[AudioService] 오디오 재생: $audioAsset');
    } catch (e) {
      debugPrint('[AudioService] 오디오 재생 오류: $e');
    }
  }

  /// 특정 오디오 파일을 반복 재생합니다.
  Future<void> playLooping(String audioAsset) async {
    try {
      if (isLooping) {
        await stop();
      } else {
        await _waitForCompletion();
      }

      if (_currentAudioAsset != audioAsset) {
        await _player.setAsset(audioAsset);
        _currentAudioAsset = audioAsset;
      }

      _isLooping = true;
      await _player.setLoopMode(LoopMode.all);
      await _player.seek(Duration.zero);
      await _player.play();

      debugPrint('[AudioService] 반복 재생: $audioAsset');
    } catch (e) {
      debugPrint('[AudioService] 반복 재생 오류: $e');
    }
  }

  /// 현재 재생 중인 오디오를 정지합니다.
  Future<void> stop() async {
    try {
      await _player.stop();
      _isLooping = false;
      debugPrint('[AudioService] 재생 정지');
    } catch (e) {
      debugPrint('[AudioService] 재생 정지 오류: $e');
    }
  }

  /// 현재 오디오가 반복 재생 중인지 여부
  bool get isLooping => _isLooping;

  /// 현재 재생 중인 오디오 에셋 경로
  String? get currentAudioAsset => _currentAudioAsset;

  /// 현재 재생 중인지 여부
  Future<bool> get isPlaying async => _player.playing;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
