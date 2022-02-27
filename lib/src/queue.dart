import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:vulkan/vulkan.dart';

import 'device.dart';
import 'device_reference.dart';

class Queue extends DeviceReference {
  late int mGraphicsFamily;
  late int mTransferFamily;
  late Pointer<VkQueue> vGraphicsQueue;
  late Pointer<VkQueue> vTransferQueue;

  /// Create the queue using the [device] its bound to.
  Queue(Device device) : super(device) {
    // Get the physical device queue family property count.
    final count = calloc<Int32>();
    vkGetPhysicalDeviceQueueFamilyProperties(
        device.getPhysicalDevice(), count, nullptr);

    // Get the physical device queue family properties.
    final vQueueFamilyProps = calloc<VkQueueFamilyProperties>(count.value);
    vkGetPhysicalDeviceQueueFamilyProperties(
        device.getPhysicalDevice(), count, vQueueFamilyProps);

    // Iterate over the queue family properties and check if it contains the
    // required queues.
    for (var i = 0; i < count.value; i++) {
      final queueFamily = vQueueFamilyProps.elementAt(i).ref;

      // If the queue flags contain the graphics bit, we use this index as the
      // graphics family.
      if (queueFamily.queueFlags & VK_QUEUE_GRAPHICS_BIT > 0) {
        mGraphicsFamily = i;
      }

      // if the queue flags contain the transfer bit, we use this index as the
      // transfer bit.
      if (queueFamily.queueFlags & VK_QUEUE_TRANSFER_BIT > 0) {
        mTransferFamily = i;
      }

      // If its complete, we can break and return.
      if (isComplete()) {
        break;
      }
    }
  }

  /// Get the queues from the device. Make sure to call this AFTER creating the
  /// logical device.
  void getQueues() {
    // Get the graphics queue.
    final pGraphicsQueue = calloc<Pointer<VkQueue>>();
    vkGetDeviceQueue(
        mDevice.getLogicalDevice(), mGraphicsFamily, 0, pGraphicsQueue);
    vGraphicsQueue = pGraphicsQueue.value;

    // Get the transfer queue.
    final pTransferQueue = calloc<Pointer<VkQueue>>();
    vkGetDeviceQueue(
        mDevice.getLogicalDevice(), mTransferFamily, 0, pTransferQueue);
    vTransferQueue = pTransferQueue.value;
  }

  /// Get the graphics queue.
  Pointer<VkQueue> getGraphicsQueue() {
    return vGraphicsQueue;
  }

  /// Get the transfer queue.
  Pointer<VkQueue> getTransferQueue() {
    return vTransferQueue;
  }

  /// Get the graphics family.
  int getGraphicsFamily() {
    return mGraphicsFamily;
  }

  /// Get the transfer family.
  int getTransferFamily() {
    return mTransferFamily;
  }

  /// Check if the queue is complete and contains the data we need.
  /// A queue is considered as complete if both the graphics and transfer
  /// families are greater than or equal to 0.
  bool isComplete() {
    return mGraphicsFamily >= 0 && mTransferFamily >= 0;
  }

  @override
  void destroy() {}
}
