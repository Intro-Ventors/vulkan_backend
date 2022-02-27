import 'package:vulkan/vulkan.dart';

class Extent2D {
  int mWidth = 0;
  int mHeight = 0;

  /// Default constructor.
  constructor() {}

  /// Set the width as [width] and return `this`.
  Extent2D setWidth(int width) {
    mWidth = width;
    return this;
  }

  /// Set the height as [height] and return `this`.
  Extent2D setHeight(int height) {
    mHeight = height;
    return this;
  }
}

class Extent3D {
  int mWidth = 0;
  int mHeight = 0;
  int mDepth = 0;

  /// Construct the extent structure using its [width], [height] and optional
  /// [depth].
  Extent3D(int width, int height, [int depth = 1])
      : mWidth = width,
        mHeight = height,
        mDepth = depth;

  /// Set the width as [width] and return `this`.
  Extent3D setWidth(int width) {
    mWidth = width;
    return this;
  }

  /// Set the height as [height] and return `this`.
  Extent3D setHeight(int height) {
    mHeight = height;
    return this;
  }

  /// Set the height as [depth] and return `this`.
  Extent3D setDepth(int depth) {
    mDepth = depth;
    return this;
  }
}

class BackendError implements Exception {
  final String mErrorMessage;

  /// Create the backend error using an error [message]. This is optional.
  BackendError([String message = ""]) : mErrorMessage = message;

  // Get the error message.
  String getMessage() => mErrorMessage;
}

/// Make a version integer out of the [major], [minor] and [patch] versions.
int makeVersion(int major, int minor, int patch) =>
    ((major) << 22) | ((minor) << 12) | (patch);

/// Validate a Vulkan [result]. This will print out a [message] if the result is not equal to `VK_SUCCESS`.
void validateResult(final int result, String message) {
  if (result != VK_SUCCESS) {
    throw BackendError(message);
  }
}
