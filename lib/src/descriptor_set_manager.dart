import 'descriptor_set.dart';
import 'device.dart';
import 'device_reference.dart';
import 'shader.dart';

class DescriptorSetManager extends DeviceReference {
  List<DescriptorSet> mDescriptorSets = List.empty(growable: true);

  /// Construct the descriptor set manager using its parent [device].
  DescriptorSetManager(Device device) : super(device);

  void getDescriptorPool() {}

  /// Create a new descriptor set using its shader.
  DescriptorSet createDescriptorSet(Shader shader) {
    return DescriptorSet([], []);
  }

  /// Bind resources to the descriptor set present in the given [shader].
  /// These resources can be either [images], [buffers] or both.
  DescriptorSet bindResources(Shader shader,
      [var images = List<ImageResource>, var buffers = List<BufferResource>]) {
    return DescriptorSet(images, buffers);
  }

  @override
  void destroy() {}
}
