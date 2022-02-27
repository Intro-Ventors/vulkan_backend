import 'device.dart';
import 'device_reference.dart';
import 'image.dart';
import 'utilities.dart';

abstract class RenderTarget extends DeviceReference {
  int mFrameIndex = 0;
  final int mFrameCount;
  final Extent2D mExtent;
  List<Image> mImages = List.empty(growable: true);

  /// Construct the render target using the [device], [frameCount] and the [extent].
  RenderTarget(Device device, int frameCount, Extent2D extent)
      : mFrameCount = frameCount,
        mExtent = extent,
        super(device);

  void getFrameBuffers() {}
  void getRenderPass() {}

  /// Register a new image to the render target.
  void registerAttachment(Image image) {
    mImages.add(image);
  }

  /// Get the image attachments registered in this render target.
  List<Image> getAttachments() {
    return mImages;
  }

  void getCommandPool() {}
  void getCommandBuffers() {}
  void getFences() {}
  void getImageAvailableSemaphores() {}
  void getRenderFinishedSemaphores() {}

  /// Get the current frame index.
  int getCurrentFrameIndex() {
    return mFrameIndex;
  }

  /// Get the frame count. This represents the number of frame buffers in the render target.
  int getFrameCount() {
    return mFrameCount;
  }

  void prepareFrame() {}
  void renderFrame() {}
}
