import 'package:flutter/material.dart';
import 'bottom_sheet_types.dart';

class BottomSheetModel extends ChangeNotifier {
  ReportCardType? _currentType;
  bool _isVisible = false;

  ReportCardType? get currentType => _currentType;
  bool get isVisible => _isVisible;

  void showBottomSheet(ReportCardType type) {
    _currentType = type;
    _isVisible = true;
    notifyListeners();
  }

  void hideBottomSheet() {
    _isVisible = false;
    _currentType = null;
    notifyListeners();
  }
}
