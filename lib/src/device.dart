import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:vulkan/vulkan.dart';

import 'buffer.dart';
import 'descriptor_set_manager.dart';
import 'display_bound.dart';
import 'graphics_pipeline.dart';
import 'image.dart';
import 'instance.dart';
import 'instance_bound_object.dart';
import 'off_screen.dart';
import 'one_time_command_buffer.dart';
import 'queue.dart';
import 'render_target.dart';
import 'shader.dart';
import 'display.dart';
import 'utilities.dart';

class Device extends InstanceBoundObject {
  late Pointer<VkDevice> vLogicalDevice;
  late Pointer<VkPhysicalDevice> vPhysicalDevice;
  late Queue mQueue;
  late OneTimeCommandBuffer mOneTimeCommandBuffer;

  /// Construct the device using its parent [instance].
  Device(Instance instance) : super(instance) {
    // First, get the required physical device.
    _getPhysicalDevice();

    // Create a new logical device.
    _createLogicalDevice();

    // Create the one time command buffer.
    mOneTimeCommandBuffer = OneTimeCommandBuffer(this);
  }

  /// Get the logical device.
  Pointer<VkDevice> getLogicalDevice() {
    return vLogicalDevice;
  }

  /// Get the physical device.
  Pointer<VkPhysicalDevice> getPhysicalDevice() {
    return vPhysicalDevice;
  }

  /// Get the queue object.
  Queue getQueue() {
    return mQueue;
  }

  /// Get the one time command buffer.
  /// This can be used to send a burst of commands to the GPU to be executed.
  ///
  /// The normal usage would be,
  /// ```dart
  /// final commandBuffer = mDevice.getCommandBuffer();
  /// commandBuffer.begin();
  ///
  /// // Record all your commands.
  ///
  /// commandBuffer.end();  // Optional
  /// commandBuffer.execute();  // Execute the recorded commands.
  /// ```
  ///
  /// Note that this command buffer cannot be used to carry out graphics
  /// commands!
  OneTimeCommandBuffer getCommandBuffer() {
    return mOneTimeCommandBuffer;
  }

  /// Create a new buffer object.
  Buffer createBuffer(int size, int bufferType) {
    return Buffer(this, size, bufferType);
  }

  /// Create a new image object.
  Image createImage(
      Extent3D extent, int format, int imageType, int layers, int mipLevel) {
    return Image(this, extent, format, imageType, layers, mipLevel);
  }

  /// Create a new shader.
  Shader createShader(String file, int type) {
    return Shader(this, file, type);
  }

  /// Create a new graphics pipeline.
  GraphicsPipeline createGraphicsPipeline(
      var specification, List<Shader> shaders, RenderTarget renderTarget) {
    return GraphicsPipeline(this, specification, shaders, renderTarget);
  }

  /// Create a new one time command buffer.
  /// These command buffers are scope based and is intended to be used as a single shot.
  OneTimeCommandBuffer createOneTimeCommandBuffer() {
    return OneTimeCommandBuffer(this);
  }

  /// Create an off screen render target.
  OffScreen createOffScreenRenderTarget(int imageCount, Extent2D extent) {
    return OffScreen(this, imageCount, extent);
  }

  /// Create a display bound render target.
  DisplayBound createDisplayBoundRenderTarget(
      Display display, int frameCount, int presentMode) {
    return DisplayBound(this, frameCount, display, presentMode);
  }

  /// Create a descriptor set manager.
  DescriptorSetManager createDescriptorSetManager() {
    return DescriptorSetManager(this);
  }

  /// Create the physical device.
  void _getPhysicalDevice() {
    // Get the candidate physical device count.
    final candidateCount = calloc<Int32>();
    validateResult(
        vkEnumeratePhysicalDevices(
            mInstance.getInstance(), candidateCount, nullptr),
        'Failed to enumerate candidate physical device count.');

    // Get the candidate physical devices.
    final vCandidatePhysicalDevices =
        calloc<Pointer<VkPhysicalDevice>>(candidateCount.value);
    validateResult(
        vkEnumeratePhysicalDevices(
            mInstance.getInstance(), candidateCount, vCandidatePhysicalDevices),
        'Failed to enumerate candidate physical devices.');

    // Iterate over the candidate physical devices to pick the right one.
    for (var i = 0; i < candidateCount.value; i++) {
      final vCandidateDevice = vCandidatePhysicalDevices.elementAt(i).value;
      final vPhysicalDeviceProperties = calloc<VkPhysicalDeviceProperties>();

      // Get the physical device properties.
      vkGetPhysicalDeviceProperties(
          vCandidateDevice, vPhysicalDeviceProperties);

      // Check if the physical device is suitable and if so, we can use it as
      // the physical device.
      if (_isPhysicalDeviceSuitable(vCandidateDevice)) {
        vPhysicalDevice = vCandidateDevice;
        break;
      }
    }

    // Validate if a physical device is selected.
    if (vPhysicalDevice == nullptr) {
      validateResult(
          VK_ERROR_UNKNOWN, 'Failed to find a suitable physical device!');
    }

    // Create the queue.
    mQueue = Queue(this);
  }

  /// Check if the physical device is suitable for our use.
  bool _isPhysicalDeviceSuitable(Pointer<VkPhysicalDevice> vCandidate) {
    var graphicsFamily = -1;
    var transferFamily = -1;

    // Get the physical device queue family property count.
    final count = calloc<Int32>();
    vkGetPhysicalDeviceQueueFamilyProperties(vCandidate, count, nullptr);

    // Get the physical device queue family properties.
    final vQueueFamilyProps = calloc<VkQueueFamilyProperties>(count.value);
    vkGetPhysicalDeviceQueueFamilyProperties(
        vCandidate, count, vQueueFamilyProps);

    // Iterate over the queue family properties and check if it contains the
    // required queues.
    for (var i = 0; i < count.value; i++) {
      final queueFamily = vQueueFamilyProps.elementAt(i).ref;
      // Check if the queue family supports graphics commands. If so, select it.
      if (queueFamily.queueFlags & VK_QUEUE_GRAPHICS_BIT > 0) {
        graphicsFamily = i;
      }

      // Check if the queue family supports transfer commands. If so, select it.
      if (queueFamily.queueFlags & VK_QUEUE_TRANSFER_BIT > 0) {
        transferFamily = i;
      }

      // If its complete, we can break and return.
      if (graphicsFamily >= 0 && transferFamily >= 0) {
        break;
      }
    }

    return graphicsFamily >= 0 && transferFamily >= 0;
  }

  void _createLogicalDevice() {
    // Specify the required features.
    final vRequiredFeatures = calloc<VkPhysicalDeviceFeatures>();

    // Set the queue priority.
    final priority = calloc<Float>();
    priority.value = 1.0;

    // Setup the queue create info structure.
    final vQueueCreateInfos = calloc<VkDeviceQueueCreateInfo>(2);
    vQueueCreateInfos.elementAt(0).ref
      ..sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO
      ..pNext = nullptr
      ..pQueuePriorities = priority
      ..queueCount = 1
      ..queueFamilyIndex = mQueue.getGraphicsFamily();

    vQueueCreateInfos.elementAt(1).ref
      ..sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO
      ..pNext = nullptr
      ..pQueuePriorities = priority
      ..queueCount = 1
      ..queueFamilyIndex = mQueue.getTransferFamily();

    // Create the required extension names.
    const pExtensionNames = ['VK_KHR_swapchain'];

    // Iterate through the extension names and create the native compatible
    // strings.
    final pExtensions = calloc<Pointer<Utf8>>(pExtensionNames.length);
    for (var i = 0; i < pExtensionNames.length; i++) {
      pExtensions.elementAt(i).value = pExtensionNames[i].toNativeUtf8();
    }

    // Create the device create info structure.
    final vCreateInfo = calloc<VkDeviceCreateInfo>();
    vCreateInfo.ref
      ..sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO
      ..pNext = nullptr
      ..queueCreateInfoCount = 2
      ..pQueueCreateInfos = vQueueCreateInfos
      ..enabledLayerCount = mInstance.getLayerCount()
      ..ppEnabledLayerNames = mInstance.getLayers()
      ..enabledExtensionCount = pExtensionNames.length
      ..ppEnabledExtensionNames = pExtensions
      ..pEnabledFeatures = vRequiredFeatures;

    // Create the logical device.
    final pLogicalDevice = calloc<Pointer<VkDevice>>();
    validateResult(
        vkCreateDevice(vPhysicalDevice, vCreateInfo, nullptr, pLogicalDevice),
        'Failed to create the Vulkan logical device!');

    vLogicalDevice = pLogicalDevice.value;

    // Finally, get the queues.
    mQueue.getQueues();
  }

  /// Destroy the device.
  @override
  void destroy() {
    // Destroy the one time command buffer.
    mOneTimeCommandBuffer.destroy();

    // Destroy just the logical device. We cant destroy the hardware we're
    // running on :)
    vkDestroyDevice(vLogicalDevice, nullptr);
  }
}
