import 'package:flutter_test/flutter_test.dart';

import 'package:vulkan_backend/vulkan_backend.dart';

void main() {
  // Test and see if we can create a Vulkan instance without validation.
  test("Create a new Vulkan instance without validation.", () {
    final instance = Instance(false);
    instance.destroy();
  });

  // Test and see if we can create a Vulkan instance with validation.
  test("Create a new Vulkan instance with validation.", () {
    final instance = Instance(true);
    instance.destroy();
  });
}
