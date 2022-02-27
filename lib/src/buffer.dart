import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:vulkan/vulkan.dart';

import 'device.dart';
import 'device_bound_object.dart';
import 'utilities.dart';

class Buffer extends DeviceBoundObject {
  final int mSize;
  final int mType;
  late Pointer<VkBuffer> vBuffer;
  late bool mIsBufferMapped = false;

  static const int BUFFER_TYPE_VERTEX = 0;
  static const int BUFFER_TYPE_INDEX = 1;
  static const int BUFFER_TYPE_UNIFORM = 2;
  static const int BUFFER_TYPE_STAGING = 4;

  /// Construct the buffer using its parent [device], [size] and its [type].
  Buffer(Device device, int size, int type)
      : mSize = size,
        mType = type,
        super(device) {
    var bufferUsage = 0;
    var memoryType = 0;

    // Resolve the buffer usage and memory type.
    switch (mType) {
      case BUFFER_TYPE_VERTEX:
        bufferUsage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT |
            VK_BUFFER_USAGE_TRANSFER_DST_BIT;

        memoryType = VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT;
        break;

      case BUFFER_TYPE_INDEX:
        bufferUsage =
            VK_BUFFER_USAGE_INDEX_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;

        memoryType = VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT;
        break;

      case BUFFER_TYPE_UNIFORM:
        bufferUsage = VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT |
            VK_BUFFER_USAGE_TRANSFER_SRC_BIT |
            VK_BUFFER_USAGE_TRANSFER_DST_BIT;

        memoryType = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
            VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;
        break;

      case BUFFER_TYPE_STAGING:
        bufferUsage =
            VK_BUFFER_USAGE_TRANSFER_SRC_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;

        memoryType = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
            VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;
        break;

      default:
        throw BackendError('Invalid buffer type!');
    }

    // Create the buffer.
    _createBuffer(bufferUsage);

    // Create the buffer memory.
    createBufferMemory(vBuffer, memoryType);
  }

  /// Get the Vulkan buffer.
  Pointer<VkBuffer> getBuffer() {
    return vBuffer;
  }

  /// Get the type of this buffer.
  int getType() {
    return mType;
  }

  Pointer<Uint8> mapMemory([int size = -1, int offset = 0]) {
    // Check if the buffer type is able to handle mapping.
    if (mType & BUFFER_TYPE_STAGING | BUFFER_TYPE_UNIFORM == 0) {
      throw BackendError('Buffers of this type cannot be mapped!');
    }

    // If the size is less than 0, we set the actual buffer size.
    else if (size < 0) {
      size = mSize;
      offset = 0;
    }

    // Validate and check if the incoming size and/ of offset is requesting
    // out of bound memory.
    else if (size + offset > mSize) {
      throw BackendError('Invalid size and/ or offset!');
    }

    // Map memory to the local address space.
    final pointer = calloc<Pointer<Uint8>>();
    validateResult(
        vkMapMemory(mDevice.getLogicalDevice(), getDeviceMemory(), offset, size,
            0, pointer),
        'Failed to map the buffer memory to the local address space!');

    mIsBufferMapped = true;
    return pointer.value;
  }

  /// Unmap the host mapped memory.
  void unmapMemory() {
    // Check if we need to unmap the memory. If not, we don't have to (duh...).
    if (!mIsBufferMapped) {
      return;
    }

    // Unmap the memory.
    mIsBufferMapped = false;
    vkUnmapMemory(mDevice.getLogicalDevice(), getDeviceMemory());
  }

  /// Get the size of the buffer.
  int getSize() {
    return mSize;
  }

  /// Destroy the buffer.
  @override
  void destroy() {
    // Unmap the memory if mapped.
    if (mIsBufferMapped) {
      unmapMemory();
    }

    // Free the buffer memory.
    freeMemory();

    // Destroy the buffer.
    vkDestroyBuffer(mDevice.getLogicalDevice(), vBuffer, nullptr);
  }

  /// Create the buffer.
  void _createBuffer(int usage) {
    // Create the create info structure.
    final vCreateInfo = calloc<VkBufferCreateInfo>();
    vCreateInfo.ref
      ..sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO
      ..pNext = nullptr
      ..flags = 0
      ..sharingMode = VK_SHARING_MODE_EXCLUSIVE
      ..size = mSize
      ..usage = usage
      ..queueFamilyIndexCount = 0
      ..pQueueFamilyIndices = nullptr;

    // Create the Vulkan buffer.
    final pBuffer = calloc<Pointer<VkBuffer>>();
    validateResult(
        vkCreateBuffer(
            mDevice.getLogicalDevice(), vCreateInfo, nullptr, pBuffer),
        'Failed to create the Vulkan buffer!');

    vBuffer = pBuffer.value;
  }
}
