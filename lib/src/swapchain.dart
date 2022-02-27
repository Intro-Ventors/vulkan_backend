import 'device.dart';
import 'device_reference.dart';
import 'display.dart';
import 'image.dart';

class Swapchain extends DeviceReference {
  final Display mDisplay;
  var mPresentMode;
  List<Image> mImages = List.empty(growable: true);

  /// Construct the swapchain using the parent [device] and the [display] to which the frames are presented to as specified by the [presentMode]
  Swapchain(Device device, Display display, var presentMode)
      : mDisplay = display,
        mPresentMode = presentMode,
        super(device) {}

  /// Get the number of images stored in the images vector.
  int getImageCount() {
    return mImages.length;
  }

  void getSwapChain() {}

  /// Get the swapchain images.
  List<Image> getSwapChainImages() {
    return mImages;
  }

  void getDisplay() {}

  @override
  void destroy() {}
}
