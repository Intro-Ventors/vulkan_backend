import 'device.dart';
import 'instance.dart';
import 'instance_bound_object.dart';
import 'utilities.dart';

class Display extends InstanceBoundObject {
  final Extent2D mExtent;

  /// Construct the display using the [instance] and [extent].
  Display(Instance instance, Extent2D extent)
      : mExtent = extent,
        super(instance) {}

  /// Get the extent of the display.
  Extent2D getExtent() {
    return mExtent;
  }

  void getSurface() {}
  void getWindows() {}

  /// Check if the [device] and this object is compatible.
  bool isDeviceCompatible(Device device) {
    return true;
  }

  @override
  void destroy() {}
}
