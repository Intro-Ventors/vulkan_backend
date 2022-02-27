import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:vulkan/vulkan.dart';

import 'device.dart';
import 'utilities.dart';
import 'device_reference.dart';

abstract class DeviceBoundObject extends DeviceReference {
  late Pointer<VkDeviceMemory> vDeviceMemory;

  /// Construct the device bound object using the parent [device].
  DeviceBoundObject(Device device) : super(device);

  /// Initialize the device memory using an image and its memory properties.
  void createImageMemory(Pointer<VkImage> vImage,
      [int memoryProperties = VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT]) {
    // Get the image memory requirements.
    final vMemoryRequirements = calloc<VkMemoryRequirements>();
    vkGetImageMemoryRequirements(
        mDevice.getLogicalDevice(), vImage, vMemoryRequirements);

    // Create the memory allocate info.
    final vAllocateInfo = calloc<VkMemoryAllocateInfo>();
    vAllocateInfo.ref
      ..sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO
      ..pNext = nullptr
      ..allocationSize = vMemoryRequirements.ref.size
      ..memoryTypeIndex = _findMemoryType(
          vMemoryRequirements.ref.memoryTypeBits, memoryProperties);

    // Allocate memory.
    final pDeviceMemory = calloc<Pointer<VkDeviceMemory>>();
    validateResult(
        vkAllocateMemory(
            mDevice.getLogicalDevice(), vAllocateInfo, nullptr, pDeviceMemory),
        "Failed to allocate the image memory!");

    vDeviceMemory = pDeviceMemory.value;

    // Bind the allocated memory to the image.
    validateResult(
        vkBindImageMemory(mDevice.getLogicalDevice(), vImage, vDeviceMemory, 0),
        "Failed to bind the image and its memory!");
  }

  /// Initialize the device memory using a buffer and its memory properties.
  void createBufferMemory(Pointer<VkBuffer> vBuffer,
      [int memoryProperties = VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT |
          VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
          VK_MEMORY_PROPERTY_HOST_COHERENT_BIT]) {
    // Get the image memory requirements.
    final vMemoryRequirements = calloc<VkMemoryRequirements>();
    vkGetBufferMemoryRequirements(
        mDevice.getLogicalDevice(), vBuffer, vMemoryRequirements);

    // Create the memory allocate info.
    final vAllocateInfo = calloc<VkMemoryAllocateInfo>();
    vAllocateInfo.ref
      ..sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO
      ..pNext = nullptr
      ..allocationSize = vMemoryRequirements.ref.size
      ..memoryTypeIndex = _findMemoryType(
          vMemoryRequirements.ref.memoryTypeBits, memoryProperties);

    // Allocate memory.
    final pDeviceMemory = calloc<Pointer<VkDeviceMemory>>();
    validateResult(
        vkAllocateMemory(
            mDevice.getLogicalDevice(), vAllocateInfo, nullptr, pDeviceMemory),
        "Failed to allocate the image memory!");

    vDeviceMemory = pDeviceMemory.value;

    // Bind the allocated memory to the image.
    validateResult(
        vkBindBufferMemory(
            mDevice.getLogicalDevice(), vBuffer, vDeviceMemory, 0),
        "Failed to bind the buffer and its memory!");
  }

  /// Find the most suitable memory type using a [typeFilter] and its memory
  /// [properties].
  int _findMemoryType(int typeFilter, int properties) {
    // Get the physical device memory properties.
    final vMemoryProperties = calloc<VkPhysicalDeviceMemoryProperties>();
    vkGetPhysicalDeviceMemoryProperties(
        mDevice.getPhysicalDevice(), vMemoryProperties);

    // Iterate through the memory types to find the most suitable one.
    for (int i = 0; i < vMemoryProperties.ref.memoryTypeCount; i++) {
      // If the memory types contain the required property flags, we choose that
      // index as the memory type.
      final filter = typeFilter & (1 << i);
      final memoryType = vMemoryProperties.ref.memoryTypes[i];
      final propertyFlags = memoryType.propertyFlags & properties;

      if (filter != 0 && propertyFlags == properties) {
        return i;
      }
    }

    throw BackendError("Failed to find a suitable memory type!");
  }

  /// Get the device memory.
  Pointer<VkDeviceMemory> getDeviceMemory() {
    return vDeviceMemory;
  }

  // Free the memory.
  void freeMemory() {
    // Free the device memory.
    vkFreeMemory(mDevice.getLogicalDevice(), vDeviceMemory, nullptr);
  }
}
