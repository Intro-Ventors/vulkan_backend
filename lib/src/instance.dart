import 'dart:ffi';

import 'package:vulkan/vulkan.dart';
import 'package:ffi/ffi.dart';

import 'backend_object.dart';
import 'device.dart';
import 'display.dart';
import 'utilities.dart';

class Instance extends BackendObject {
  late bool isValidationEnabled;
  late Pointer<VkInstance> vInstance;
  late Pointer<VkDebugUtilsMessengerEXT> vDebugMessenger;
  late int mLayerCount = 0;
  late Pointer<Pointer<Utf8>> pLayers;

  /// Construct the instance.
  /// If [enableValidation] is set to true, it will generate the required
  /// instance extensions and the validation layers along with the debug
  /// messenger. This might be slow and is not recommended when deploying the
  /// application, as its not needed then.
  Instance(bool enableValidation) {
    isValidationEnabled = enableValidation && _checkValidationLayerSupport();

    // Create the application info structure.
    final vApplicationInfo = calloc<VkApplicationInfo>();
    vApplicationInfo.ref
      ..sType = VK_STRUCTURE_TYPE_APPLICATION_INFO
      ..pNext = nullptr
      ..pApplicationName = 'Reality Core'.toNativeUtf8()
      ..applicationVersion = makeVersion(1, 0, 0)
      ..pEngineName = 'Re-Co'.toNativeUtf8()
      ..engineVersion = makeVersion(1, 0, 0)
      ..apiVersion = makeVersion(1, 1, 0);

    // Setup the instance extensions.
    final extensionCount = calloc<Uint8>();
    validateResult(
        vkEnumerateInstanceExtensionProperties(
            nullptr, extensionCount, nullptr),
        'Failed to get instance extension count!');

    final pExtensions = calloc<VkExtensionProperties>(extensionCount.value);
    validateResult(
        vkEnumerateInstanceExtensionProperties(
            nullptr, extensionCount, pExtensions),
        'Failed to get the instance extensions!');

    // Convert them to extensions which can be given to the create info
    // structure.
    final instanceExtensions = calloc<Pointer<Utf8>>(extensionCount.value);
    for (var i = 0; i < extensionCount.value; i++) {
      final extension = pExtensions.elementAt(i).ref.extensionName;
      var extensionName = '';

      for (var j = 0; j < 256; j++) {
        final value = extension[j];

        // If the value is 0, that means that we can terminate.
        if (value == 0) {
          break;
        }

        extensionName += String.fromCharCode(value);
      }

      instanceExtensions.elementAt(i).value = extensionName.toNativeUtf8();
    }

    // Create the instance create info structure.
    final vInstanceCreateInfo = calloc<VkInstanceCreateInfo>();
    vInstanceCreateInfo.ref
      ..sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO
      ..pNext = nullptr
      ..flags = 0
      ..pApplicationInfo = vApplicationInfo
      ..enabledExtensionCount = extensionCount.value
      ..ppEnabledExtensionNames = instanceExtensions;

    // These are the validation layers we would need.
    const layers = ['VK_LAYER_KHRONOS_validation'];

    // Get the length and create the layers using the layer strings.
    mLayerCount = layers.length;
    pLayers = calloc<Pointer<Utf8>>(mLayerCount);
    for (var i = 0; i < mLayerCount; i++) {
      pLayers[i] = layers[i].toNativeUtf8();
    }

    // Setup the validation layers if needed.
    if (isValidationEnabled) {
      // Fill the required data to the create info structure.
      vInstanceCreateInfo.ref
        ..pNext = _createDebugMessengerCreateInfo()
        ..enabledLayerCount = mLayerCount
        ..ppEnabledLayerNames = pLayers;
    }

    // Create the instance.
    final instance = calloc<Pointer<VkInstance>>();
    validateResult(vkCreateInstance(vInstanceCreateInfo, nullptr, instance),
        'Failed to create the Vulkan instance!');

    // Assign the created instance to the instance object.
    vInstance = instance.value;

    // Create the debug messenger if validation is enabled.
    if (isValidationEnabled) {
      vkCreateDebugUtilsMessengerEXT = Pointer<
                  NativeFunction<
                      VkCreateDebugUtilsMessengerEXTNative>>.fromAddress(
              vkGetInstanceProcAddr(
                      nullptr, 'vkCreateDebugUtilsMessengerEXT'.toNativeUtf8())
                  .address)
          .asFunction<VkCreateDebugUtilsMessengerEXT>();

      final vDebugger = calloc<Pointer<VkDebugUtilsMessengerEXT>>();
      validateResult(
          vkCreateDebugUtilsMessengerEXT(
              vInstance, _createDebugMessengerCreateInfo(), nullptr, vDebugger),
          'Failed to create the Vulkan debug messenger!');
    }
  }

  /// Get the Vulkan instance pointer.
  Pointer<VkInstance> getInstance() {
    return vInstance;
  }

  /// Get the debug messenger.
  Pointer<VkDebugUtilsMessengerEXT> getDebugger() {
    return vDebugMessenger;
  }

  /// Get the stored layer count.
  int getLayerCount() {
    return mLayerCount;
  }

  /// Get the layers.
  Pointer<Pointer<Utf8>> getLayers() {
    return pLayers;
  }

  /// Create a new device.
  Device createDevice() {
    return Device(this);
  }

  /// Create a new display with the [extent].
  Display createDisplay(Extent2D extent) {
    return Display(this, extent);
  }

  /// Destroy the instance.
  @override
  void destroy() {
    // Destroy the debug messenger if validation is enabled.
    if (isValidationEnabled) {
      vkDestroyDebugUtilsMessengerEXT = Pointer<
                  NativeFunction<
                      VkDestroyDebugUtilsMessengerEXTNative>>.fromAddress(
              vkGetInstanceProcAddr(
                      nullptr, 'vkDestroyDebugUtilsMessengerEXT'.toNativeUtf8())
                  .address)
          .asFunction<VkDestroyDebugUtilsMessengerEXT>();

      vkDestroyDebugUtilsMessengerEXT(vInstance, vDebugMessenger, nullptr);
    }

    vkDestroyInstance(vInstance, nullptr);
  }

  /// Debug callback function.
  // int _debugCallback(
  //     int severity, int type, Pointer callbackData, Pointer useData) {
  //   return VK_FALSE;
  // }

  /// Create the debug messenger create info structure.
  Pointer<VkDebugUtilsMessengerCreateInfoEXT>
      _createDebugMessengerCreateInfo() {
    final vCreteInfo = calloc<VkDebugUtilsMessengerCreateInfoEXT>();
    vCreteInfo.ref
      ..sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT
      ..pNext = nullptr
      ..flags = 0
      ..pUserData = nullptr
      ..messageSeverity = VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT |
          VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT |
          VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT
      ..messageType = VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT |
          VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
          VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT
      ..pfnUserCallback /* = _debugCallback */;

    return vCreteInfo;
  }

  /// Check if the platform supports validation layers.
  bool _checkValidationLayerSupport() {
    final layerCount = calloc<Uint8>();
    validateResult(vkEnumerateInstanceLayerProperties(layerCount, nullptr),
        'Failed to enumerate Vulkan instance layer count!');

    // Here, we basically test if the layer count is more than 0. This is
    // because, if layers are present, this will be greater than 0.
    return layerCount.value > 0;
  }
}
