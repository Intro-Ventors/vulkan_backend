import 'device.dart';
import 'device_reference.dart';
import 'render_target.dart';
import 'shader.dart';

class GraphicsPipeline extends DeviceReference {
  var mSpecification;
  final List<Shader> mShaders;
  final RenderTarget mRenderTarget;

  /// Construct the graphics pipeline using its parent [device], [specification], [shaders] and [renderTarget] to which the rendered images are presented to.
  GraphicsPipeline(Device device, var specification, List<Shader> shaders,
      RenderTarget renderTarget)
      : mSpecification = specification,
        mShaders = shaders,
        mRenderTarget = renderTarget,
        super(device);

  void getPipeline() {}
  void getPipelineLayout() {}
  void getPipelineCache() {}

  /// Get the render target to which the pipeline renders to.
  RenderTarget getRenderTarget() {
    return mRenderTarget;
  }

  @override
  void destroy() {}
}
