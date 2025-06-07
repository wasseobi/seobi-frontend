import 'report_card_types.dart';

/// Report 데이터 모델
class ReportCardModel {
  final String id;
  final ReportCardType type;
  final String title;
  final String subtitle;
  final int activeDots;
  final double progress;
  final String? imageUrl;

  const ReportCardModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.activeDots = 3,
    this.progress = 0.0,
    this.imageUrl,
  });

  /// Map에서 ReportCardModel 객체로 변환하는 팩토리 메소드
  factory ReportCardModel.fromMap(Map<String, dynamic> map) {
    return ReportCardModel(
      id: map['id']?.toString() ?? '',
      type: ReportCardType.values.firstWhere(
        (type) => type.toString() == map['type'],
        orElse: () => ReportCardType.daily,
      ),
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      activeDots: map['activeDots'] as int? ?? 3,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl']?.toString(),
    );
  }

  /// ReportCardModel을 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'subtitle': subtitle,
      'activeDots': activeDots,
      'progress': progress,
      'imageUrl': imageUrl,
    };
  }

  /// ReportCardModel 복사본 생성 (상태 변경용)
  ReportCardModel copyWith({
    String? id,
    ReportCardType? type,
    String? title,
    String? subtitle,
    int? activeDots,
    double? progress,
    String? imageUrl,
  }) {
    return ReportCardModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      activeDots: activeDots ?? this.activeDots,
      progress: progress ?? this.progress,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
