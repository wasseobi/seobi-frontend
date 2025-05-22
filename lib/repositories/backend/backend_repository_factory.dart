import 'i_backend_repository.dart';
import 'backend_repository.dart';
import 'stub_backend_repository.dart';

class BackendRepositoryFactory {
  static bool _useStub = true;
  static IBackendRepository? _instance;

  static IBackendRepository get instance {
    _instance ??= _useStub ? StubBackendRepository() : BackendRepository();
    return _instance!;
  }

  static void useStubRepository() {
    _useStub = true;
    _instance = null;
  }

  static void useRealRepository() {
    _useStub = false;
    _instance = null;
  }
}
