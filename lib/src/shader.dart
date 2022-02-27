import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:vulkan/vulkan.dart';

import 'device.dart';
import 'device_reference.dart';
import 'utilities.dart';

class ResourceInfo {
  final int mSet;
  final int mBinding;
  final int mType;

  /// Construct the resource info class using the resource details.
  ResourceInfo(int set, int binding, int type)
      : mSet = set,
        mBinding = binding,
        mType = type;
}

class Shader extends DeviceReference {
  final int mType;
  late Pointer<VkShaderModule> vShaderModule;
  late Pointer<VkDescriptorSetLayout> vDescriptorSetLayout;
  late List<ResourceInfo> mResourceInfo = List.empty(growable: true);

  /// Construct the shader using its parent [device], the shader [file] and its [type].
  Shader(Device device, String file, int type)
      : mType = type,
        super(device) {
    // Load the shader code from the file.
    final shaderCode = File(file).readAsBytesSync();

    // Convert the shader code to a native buffer compatible type.
    final pShaderCode = calloc<Uint32>(shaderCode.length);
    for (int i = 0, j = 0; i < shaderCode.length; i += 4, j++) {
      final int data = shaderCode[i + 0] << 24 |
          shaderCode[i + 1] << 16 |
          shaderCode[i + 2] << 8 |
          shaderCode[i + 3] << 0;

      pShaderCode.elementAt(j).value = data;
    }

    // Create the shader module create info structure.
    final vCreateInfo = calloc<VkShaderModuleCreateInfo>();
    vCreateInfo.ref
      ..sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO
      ..pNext = nullptr
      ..flags = 0
      ..codeSize = shaderCode.length
      ..pCode = pShaderCode;

    // Create the shader module.
    final pShaderModule = calloc<Pointer<VkShaderModule>>();
    validateResult(
        vkCreateShaderModule(
            mDevice.getLogicalDevice(), vCreateInfo, nullptr, pShaderModule),
        "Failed to create the Vulkan shader module!");

    vShaderModule = pShaderModule.value;
  }

  /// Add resource info to the shader.
  /// These info consists of a [set] number, [binding] and its [type].
  void addResourceInfo(int set, int binding, int type) {
    mResourceInfo.add(ResourceInfo(set, binding, type));
  }

  /// Create the descriptor set layout.
  /// Make sure that all the resources are added before calling this function.
  void createDescriptorSetLayout() {
    // Create the descriptor set bindings.
    final pBindings =
        calloc<VkDescriptorSetLayoutBinding>(mResourceInfo.length);
    for (int i = 0; i < mResourceInfo.length; i++) {
      final resource = mResourceInfo[i];

      pBindings.elementAt(i).ref
        ..binding = resource.mBinding
        ..descriptorCount = 1 // TODO
        ..descriptorType = resource.mType
        ..pImmutableSamplers = nullptr
        ..stageFlags = mType;
    }

    // Create the create info structure.
    final vCreateInfo = calloc<VkDescriptorSetLayoutCreateInfo>();
    vCreateInfo.ref
      ..sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO
      ..pNext = nullptr
      ..flags = 0
      ..bindingCount = mResourceInfo.length
      ..pBindings = pBindings;

    // Create the descriptor set layout.
    final pDescriptorSetLayout = calloc<Pointer<VkDescriptorSetLayout>>();
    validateResult(
        vkCreateDescriptorSetLayout(mDevice.getLogicalDevice(), vCreateInfo,
            nullptr, pDescriptorSetLayout),
        "Failed to create the Vulkan descriptor set layout!");

    vDescriptorSetLayout = pDescriptorSetLayout.value;
  }

  /// Get the shader module.
  Pointer<VkShaderModule> getModule() {
    return vShaderModule;
  }

  /// Get the descriptor set layout.
  Pointer<VkDescriptorSetLayout> getDescriptorLayout() {
    return vDescriptorSetLayout;
  }

  /// Destroy the shader object.
  @override
  void destroy() {
    // Destroy the shader module.
    vkDestroyShaderModule(mDevice.getLogicalDevice(), vShaderModule, nullptr);

    // Destroy the descriptor set layout.
    vkDestroyDescriptorSetLayout(
        mDevice.getLogicalDevice(), vDescriptorSetLayout, nullptr);
  }
}
