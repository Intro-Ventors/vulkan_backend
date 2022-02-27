import 'buffer.dart';
import 'image.dart';

abstract class Resource {
  final int mBinding;

  /// Construct the resource using its binding.
  Resource(int binding) : mBinding = binding;
}

class ImageResource extends Resource {
  final Image mImage;

  /// Create the image resource using its [image] and its respective [binding].
  ImageResource(Image image, int binding)
      : mImage = image,
        super(binding) {}
}

class BufferResource extends Resource {
  final Buffer mBuffer;

  /// Create the buffer resource using its [buffer] and its respective [binding].
  BufferResource(Buffer buffer, int binding)
      : mBuffer = buffer,
        super(binding);
}

class DescriptorSet {
  List<ImageResource> mImageResources = List.empty(growable: true);
  List<BufferResource> mBufferResources = List.empty(growable: true);

  /// Construct the descriptor set using the image and buffer resources.
  DescriptorSet(List<ImageResource> images, List<BufferResource> buffers)
      : mImageResources = images,
        mBufferResources = buffers;
}
