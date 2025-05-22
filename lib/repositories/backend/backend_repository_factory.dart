import 'backend_repository_interface.dart';
import 'backend_repository.dart';
import 'stub_backend_repository.dart';

class BackendRepositoryFactory {
  static bool _useStub = true;
  static BackendRepositoryInterface? _instance;

  static BackendRepositoryInterface get instance {
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
