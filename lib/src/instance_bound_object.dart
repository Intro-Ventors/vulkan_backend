import 'backend_object.dart';
import 'instance.dart';

abstract class InstanceBoundObject extends BackendObject {
  final Instance mInstance;

  /// Construct the [instance] bound object.
  InstanceBoundObject(Instance instance) : mInstance = instance;

  /// Get the instance to which this object is bound to.
  Instance getInstance() {
    return mInstance;
  }
}
