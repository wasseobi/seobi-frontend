class Extension {
  final String name;
  final String description;
  final String guideText;
  bool isConnected;

  Extension({
    required this.name,
    required this.description,
    this.guideText = 'Guide Text',
    this.isConnected = false,
  });
}
