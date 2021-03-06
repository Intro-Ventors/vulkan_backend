import 'dart:ffi';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vulkan/vulkan.dart';
import 'package:vulkan_backend/vulkan_backend.dart';

void main() {
  //// Test and see if we can create a Vulkan instance without validation.
  //test("Create a new Vulkan instance without validation.", () {
  //  final instance = Instance(false);
  //  instance.destroy();
  //});
  //
  //// Create a device without validation.
  //test("Create a Vulkan device without validation.", () {
  //  final instance = Instance(false);
  //  final device = instance.createDevice();
  //  device.destroy();
  //  instance.destroy();
  //});
  //
  //// Test and see if we can create a Vulkan instance with validation.
  //test("Create a new Vulkan instance with validation.", () {
  //  final instance = Instance(true);
  //  instance.destroy();
  //});
  //
  //// Create a device with validation.
  //test("Create a Vulkan device with validation.", () {
  //  final instance = Instance(true);
  //  final device = instance.createDevice();
  //  device.destroy();
  //  instance.destroy();
  //});

  test("All in one test", () {
    // Create the instance. For now, we turn off validation.
    final instance = Instance(false);

    // Create the device.
    final device = instance.createDevice();

    // Create the image.
    final image = device.createImage(
        Extent3D(1, 1, 1), VK_FORMAT_B8G8R8A8_SRGB, VK_IMAGE_TYPE_2D, 1, 1);

    // Create the shader.
    final shader = device.createShader(
        Directory.current.path + "/test/assets/Occlusion.vert.fsc",
        VK_SHADER_STAGE_VERTEX_BIT);

    // Add resource info and crete the descriptor set layout.
    shader.addResourceInfo(0, 1, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER);
    shader.createDescriptorSetLayout();

    // Create buffer.
    final buffer = device.createBuffer(1024, Buffer.BUFFER_TYPE_STAGING);

    // Map the buffer memory.
    final pointer = buffer.mapMemory();

    // Fill up the buffer with 0xff.
    for (int i = 0; i < 1024; i++) {
      pointer.elementAt(i).value = 0xff;
    }

    // Unmap the memory later.
    buffer.unmapMemory();

    // Destroy the allocated resources.
    buffer.destroy();
    shader.destroy();
    image.destroy();
    device.destroy();
    instance.destroy();
  });
}
