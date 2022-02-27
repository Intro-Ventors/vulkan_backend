import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:vulkan/vulkan.dart';

import 'device.dart';
import 'device_reference.dart';
import 'utilities.dart';

class OneTimeCommandBuffer extends DeviceReference {
  late Pointer<VkCommandBuffer> vCommandBuffer;
  late Pointer<VkCommandPool> vCommandPool;
  late bool mIsRecording = false;

  /// Construct the one time command buffer using its parent [device].
  OneTimeCommandBuffer(Device device) : super(device) {
    // Create the command pool.
    _createCommandPool();

    // Allocate the command buffer.
    _allocateCommandBuffer();
  }

  /// Begin command buffer recording.
  void begin() {
    mIsRecording = true;

    // Create the command buffer begin info structure.
    final vBeginInfo = calloc<VkCommandBufferBeginInfo>();
    vBeginInfo.ref
      ..sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO
      ..pNext = nullptr
      ..pInheritanceInfo = nullptr
      ..flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;

    // Begin recording.
    validateResult(vkBeginCommandBuffer(vCommandBuffer, vBeginInfo),
        'Failed to begin command buffer recording!');
  }

  /// End command buffer recording.
  void end() {
    mIsRecording = false;

    // End recording.
    vkEndCommandBuffer(vCommandBuffer);
  }

  /// Execute the recorded commands.
  /// If [waitExecution] is set to false, this function will not wait until the
  /// recorded commands finishes execution. If set to true, this function will
  /// wait until the GPU finished all the recorded commands.
  ///
  /// If it's not waiting, make sure that you wait until the queue finishes
  /// executing the commands before submitting or doing any other operation with
  /// this command buffer.
  void execute([bool waitExecution = true]) {
    // Check and end the command buffer recording if the command buffer is still
    //on the recording state.
    if (mIsRecording) {
      end();
    }

    // Get the command buffer as a pointer.
    final pCommandBuffer = calloc<Pointer<VkCommandBuffer>>();
    pCommandBuffer.elementAt(0).value = vCommandBuffer;

    // Create the submit info structure.
    final vSubmitInfo = calloc<VkSubmitInfo>();
    vSubmitInfo.ref
      ..sType = VK_STRUCTURE_TYPE_SUBMIT_INFO
      ..commandBufferCount = 1
      ..pCommandBuffers = pCommandBuffer;

    // Create the synchronization fence.
    final pFence = calloc<Pointer<VkFence>>();

    // If we need to wait, create the Vulkan fence.
    if (waitExecution) {
      // Create the create info structure.
      final vFenceCreateInfo = calloc<VkFenceCreateInfo>();
      vFenceCreateInfo.ref
        ..sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO
        ..pNext = nullptr
        ..flags = 0;

      // Create the fence.
      validateResult(
          vkCreateFence(
              mDevice.getLogicalDevice(), vFenceCreateInfo, nullptr, pFence),
          'Failed to create the Vulkan fence!');
    }

    // Submit the queue.
    validateResult(
        vkQueueSubmit(mDevice.getQueue().getTransferQueue(), 1, vSubmitInfo,
            pFence.value),
        'Failed to submit the queue!');

    // If enabled, wait till the GPU finishes the queue execution and destroy
    // the fence.
    if (waitExecution) {
      validateResult(
          vkWaitForFences(mDevice.getLogicalDevice(), 1, pFence, VK_TRUE, -1),
          'Failed to wait till the queue finished execution!');

      // Destroy the fence.
      vkDestroyFence(mDevice.getLogicalDevice(), pFence.value, nullptr);
    }
  }

  /// Get the command buffer.
  Pointer<VkCommandBuffer> getCommandBuffer() {
    return vCommandBuffer;
  }

  /// Get the command pool.
  Pointer<VkCommandPool> getCommandPool() {
    return vCommandPool;
  }

  /// Create the command pool.
  void _createCommandPool() {
    // Create the command pool create info structure.
    final vCreateInfo = calloc<VkCommandPoolCreateInfo>();
    vCreateInfo.ref
      ..sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO
      ..pNext = nullptr
      ..flags = 0
      ..queueFamilyIndex = mDevice.getQueue().getTransferFamily();

    // Create the command pool.
    final pCommandPool = calloc<Pointer<VkCommandPool>>();
    validateResult(
        vkCreateCommandPool(
            mDevice.getLogicalDevice(), vCreateInfo, nullptr, pCommandPool),
        'Failed to create the Vulkan command pool!');

    vCommandPool = pCommandPool.value;
  }

  /// Allocate the command buffer.
  void _allocateCommandBuffer() {
    // Create the allocate info structure.
    final vAllocateInfo = calloc<VkCommandBufferAllocateInfo>();
    vAllocateInfo.ref
      ..sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO
      ..pNext = nullptr
      ..commandBufferCount = 1
      ..commandPool = vCommandPool
      ..level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;

    // Allocate the command buffer.
    final pCommandBuffer = calloc<Pointer<VkCommandBuffer>>();
    validateResult(
        vkAllocateCommandBuffers(
            mDevice.getLogicalDevice(), vAllocateInfo, pCommandBuffer),
        'Failed to allocate the Vulkan one time command buffer!');

    vCommandBuffer = pCommandBuffer.value;
  }

  /// Destroy the one time command buffer.
  @override
  void destroy() {
    // If the command buffer is in the recording state, make sure to end it
    // first.
    if (mIsRecording) {
      end();
    }

    // Free the command buffer.
    final pCommandBuffer = calloc<Pointer<VkCommandBuffer>>();
    pCommandBuffer.elementAt(0).value = vCommandBuffer;
    vkFreeCommandBuffers(
        mDevice.getLogicalDevice(), vCommandPool, 1, pCommandBuffer);

    // Destroy the command pool.
    vkDestroyCommandPool(mDevice.getLogicalDevice(), vCommandPool, nullptr);
  }
}
