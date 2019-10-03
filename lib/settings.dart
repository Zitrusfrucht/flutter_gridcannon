class Settings {
  static final Settings _singleton = Settings._internal();

  bool showHighlights = true;

  factory Settings() {
    return _singleton;
  }

  Settings._internal();
}