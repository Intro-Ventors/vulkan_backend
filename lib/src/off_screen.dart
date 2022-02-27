import 'device.dart';
import 'render_target.dart';
import 'utilities.dart';

class OffScreen extends RenderTarget {
  /// Construct the off screen render target using its parent [device], [frameCount] and its [extent].
  OffScreen(Device device, int frameCount, Extent2D extent)
      : super(device, frameCount, extent);

  void getRenderedImage() {}

  @override
  void destroy() {}
}
