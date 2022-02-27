import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:vulkan/vulkan.dart';

import 'buffer.dart';
import 'device.dart';
import 'device_bound_object.dart';
import 'utilities.dart';

class Image extends DeviceBoundObject {
  final Extent3D mExtent;
  final int mLayers;
  final int mMipLevel;
  final int mImageType;
  final int mImageFormat;
  late Pointer<VkImage> vImage;
  late Pointer<VkImageView> vImageView;
  late Pointer<VkSampler> vImageSampler;

  /// Construct the image using the parent [device], [extent], [imageType], [layers] and [mipLevel].
  Image(Device device, Extent3D extent, int format, int imageType, int layers,
      int mipLevel)
      : mExtent = extent,
        mImageFormat = format,
        mImageType = imageType,
        mLayers = layers,
        mMipLevel = mipLevel,
        super(device) {
    // Create the Vulkan image.
    _createImage();

    // Create the image memory.
    createImageMemory(vImage);

    // Create the image view [TODO].
    _createImageView(
        VK_IMAGE_ASPECT_COLOR_BIT, 0, 0, 1, 1, VK_IMAGE_VIEW_TYPE_2D);

    // Create the image sampler [TODO].
    _createSampler(VK_SAMPLER_ADDRESS_MODE_REPEAT);
  }

  /// Get the Vulkan image.
  Pointer<VkImage> getImage() {
    return vImage;
  }

  /// Get the Vulkan image view.
  Pointer<VkImageView> getImageView() {
    return vImageView;
  }

  /// Get the Vulkan image sampler.
  Pointer<VkSampler> getImageSampler() {
    return vImageSampler;
  }

  /// Copy the data from a [buffer] to this image.
  void copyFromStagingBugger(Buffer buffer) {}

  /// Create image.
  void _createImage() {
    // Create the image create info structure.
    final vCreateInfo = calloc<VkImageCreateInfo>();
    vCreateInfo.ref
      ..sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO
      ..pNext = nullptr
      ..initialLayout = VK_IMAGE_LAYOUT_UNDEFINED
      ..sharingMode = VK_SHARING_MODE_EXCLUSIVE
      ..usage = VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
          VK_IMAGE_USAGE_TRANSFER_DST_BIT |
          VK_IMAGE_USAGE_SAMPLED_BIT
      ..samples = VK_SAMPLE_COUNT_1_BIT
      ..tiling = VK_IMAGE_TILING_OPTIMAL
      ..arrayLayers = mLayers
      ..extent_width = mExtent.mWidth
      ..extent_height = mExtent.mHeight
      ..extent_depth = mExtent.mDepth
      ..format = mImageFormat
      ..imageType = mImageType
      ..mipLevels = mMipLevel
      ..queueFamilyIndexCount = 0
      ..pQueueFamilyIndices = nullptr;

    // Create the Vulkan image.
    final pImage = calloc<Pointer<VkImage>>();
    validateResult(
        vkCreateImage(mDevice.getLogicalDevice(), vCreateInfo, nullptr, pImage),
        "Failed to create the Vulkan image!");

    vImage = pImage.value;
  }

  /// Create the image view using the [aspectMask], [baseArrayLayer],
  /// [baseMipLevel], [layerCount], [levelCount] and [viewType].
  void _createImageView(int aspectMask, int baseArrayLayer, int baseMipLevel,
      int layerCount, int levelCount, int viewType) {
    // Create the image view create info structure.
    final vCreateInfo = calloc<VkImageViewCreateInfo>();
    vCreateInfo.ref
      ..sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO
      ..pNext = nullptr
      ..image = vImage
      ..format = mImageFormat
      ..subresourceRange_aspectMask = aspectMask
      ..subresourceRange_baseArrayLayer = baseArrayLayer
      ..subresourceRange_baseMipLevel = baseMipLevel
      ..subresourceRange_layerCount = layerCount
      ..subresourceRange_levelCount = levelCount
      ..viewType = viewType;

    final pImageView = calloc<Pointer<VkImageView>>();
    validateResult(
        vkCreateImageView(
            mDevice.getLogicalDevice(), vCreateInfo, nullptr, pImageView),
        "Failed to create the Vulkan image view!");

    vImageView = pImageView.value;
  }

  // Crete the image sampler.
  void _createSampler(int addressMode) {
    // Get the physical device properties.
    final vPhysicalDeviceProperties = calloc<VkPhysicalDeviceProperties>();
    vkGetPhysicalDeviceProperties(
        mDevice.getPhysicalDevice(), vPhysicalDeviceProperties);

    // Create the sampler create info structure.
    final vCreateInfo = calloc<VkSamplerCreateInfo>();
    vCreateInfo.ref
      ..sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO
      ..pNext = nullptr
      ..magFilter = VK_FILTER_LINEAR
      ..minFilter = VK_FILTER_LINEAR
      ..addressModeU = addressMode
      ..addressModeV = addressMode
      ..addressModeW = addressMode
      ..anisotropyEnable = VK_TRUE
      ..maxAnisotropy =
          vPhysicalDeviceProperties.ref.limits_maxSamplerAnisotropy
      ..borderColor = VK_BORDER_COLOR_INT_OPAQUE_BLACK
      ..unnormalizedCoordinates = VK_FALSE
      ..compareEnable = VK_FALSE
      ..compareOp = VK_COMPARE_OP_ALWAYS
      ..mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR
      ..minLod = 0.0
      ..maxLod = mMipLevel.toDouble()
      ..mipLodBias = 0.0;

    // Create the sampler
    final pSampler = calloc<Pointer<VkSampler>>();
    validateResult(
        vkCreateSampler(
            mDevice.getLogicalDevice(), vCreateInfo, nullptr, pSampler),
        "Failed to create the Vulkan image sampler!");

    vImageSampler = pSampler.value;
  }

  /// Destroy the Vulkan objects in this object.
  @override
  void destroy() {
    // Make sure to free the allocated memory.
    freeMemory();

    // Destroy the image.
    vkDestroyImage(mDevice.getLogicalDevice(), vImage, nullptr);

    // Destroy the image view.
    vkDestroyImageView(mDevice.getLogicalDevice(), vImageView, nullptr);

    // Destroy the image sampler.
    vkDestroySampler(mDevice.getLogicalDevice(), vImageSampler, nullptr);
  }
}
