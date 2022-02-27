import 'device.dart';
import 'device_bound_object.dart';

class Buffer extends DeviceBoundObject {
  final int mSize;
  var mType;

  /// Construct the buffer using its parent [device], [size] and its [type].
  Buffer(Device device, int size, var type)
      : mSize = size,
        mType = type,
        super(device) {}

  void getBuffer() {}
  void mapBuffer(int size, int offset) {}
  void unmapBuffer() {}

  /// Get the size of the buffer.
  int getSize() {
    return mSize;
  }

  @override
  void destroy() {}

  /// Get the type of this buffer.
  // var getType() {
  //   return mType;
  // }
}
