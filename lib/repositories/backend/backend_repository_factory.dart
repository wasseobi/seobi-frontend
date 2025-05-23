import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'i_backend_repository.dart';
import 'backend_repository.dart';
import 'stub_backend_repository.dart';

class BackendRepositoryFactory {
  static bool get _useStub =>
      dotenv.get('USE_STUB_BACKEND', fallback: 'true') == 'true';
  static IBackendRepository? _instance;

  static IBackendRepository get instance {
    _instance ??= _useStub ? StubBackendRepository() : BackendRepository();
    return _instance!;
  }

  static void useStubRepository() {
    _instance = StubBackendRepository();
  }

  static void useRealRepository() {
    _instance = BackendRepository();
  }
}
