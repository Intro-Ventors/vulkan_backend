import 'backend_object.dart';
import 'device.dart';

abstract class DeviceReference extends BackendObject {
  final Device mDevice;

  /// Construct the device reference using the parent [device].
  DeviceReference(Device device) : mDevice = device;

  /// Get the parent device.
  Device getDevice() {
    return mDevice;
  }
}
