// Copyright 2022-present 650 Industries. All rights reserved.

import ExpoModulesCore
import MobileCoreServices
import PhotosUI

internal let MAXIMUM_QUALITY = 1.0

internal let UNLIMITED_SELECTION = 0
internal let SINGLE_SELECTION = 1

internal struct ImagePickerOptions: Record {
  @Field
  var allowsEditing: Bool = false

  @Field
  var aspect: [Double]

  @Field
  var quality: Double = 1.0

  @Field
  var mediaTypes: MediaType = .images

  @Field
  var exif: Bool

  @Field
  var base64: Bool = false

  @Field
  var videoExportPreset: VideoExportPreset = .passthrough

  @Field
  var videoQuality: VideoQuality = .typeHigh

  @Field
  var videoMaxDuration: Double = 0

  @Field
  var presentationStyle: PresentationStyle = .automatic

  @Field
  var preferredAssetRepresentationMode: PreferredAssetRepresentationMode = .automatic

  @Field
  var cameraType: CameraType = .back

  @Field
  var allowsMultipleSelection: Bool = false

  @Field
  var selectionLimit: Int = UNLIMITED_SELECTION

  @Field
  var orderedSelection: Bool = false
}

internal enum PresentationStyle: String, Enumerable {
  case fullScreen
  case pageSheet
  case formSheet
  case currentContext
  case overFullScreen
  case overCurrentContext
  case popover
  case none
  case automatic

  func toPresentationStyle() -> UIModalPresentationStyle {
    switch self {
    case .fullScreen:
      return .fullScreen
    case .pageSheet:
      return .pageSheet
    case .formSheet:
      return .formSheet
    case .currentContext:
      return .currentContext
    case .overFullScreen:
      return .overFullScreen
    case .overCurrentContext:
      return .overCurrentContext
    case .popover:
      return .popover
    case .none:
      return .none
    case .automatic:
      if #available(iOS 13.0, *) {
        return .automatic
      }
      // default prior iOS 13
      return .fullScreen
    }
  }
}

internal enum PreferredAssetRepresentationMode: String, Enumerable {
  case automatic
  case compatible
  case current

  func toAssetRepresentationMode() -> PHPickerConfiguration.AssetRepresentationMode {
    switch self {
    case .automatic:
      return .automatic
    case .compatible:
      return .compatible
    case .current:
      return .current
    }
  }
}

internal enum VideoQuality: Int, Enumerable {
  case typeHigh = 0
  case typeMedium = 1
  case typeLow = 2
  case type640x480 = 3
  case typeIFrame1280x720 = 4
  case typeIFrame960x540 = 5

  func toQualityType() -> UIImagePickerController.QualityType {
    switch self {
    case .typeHigh:
      return .typeHigh
    case .typeMedium:
      return .typeMedium
    case .typeLow:
      return .typeLow
    case .type640x480:
      return .type640x480
    case .typeIFrame1280x720:
      return .typeIFrame1280x720
    case .typeIFrame960x540:
      return .typeIFrame960x540
    }
  }
}

internal enum MediaType: String, Enumerable {
  case all = "All"
  case videos = "Videos"
  case images = "Images"

  func toArray() -> [String] {
    switch self {
    case .images:
      return [kUTTypeImage as String]
    case .videos:
      return [kUTTypeMovie as String]
    case .all:
      return [kUTTypeImage as String, kUTTypeMovie as String]
    }
  }

  func requiresMicrophonePermission() -> Bool {
    switch self {
    case .images:
      return false
    case .videos:
      return true
    case .all:
      return true
    }
  }

  func toPickerFilter() -> PHPickerFilter {
    // TODO: (barthap) Maybe add support for live photos
    switch self {
    case .images:
      return .images
    case .videos:
      return .videos
    case .all:
      return .any(of: [.images, .videos])
    }
  }
}

internal enum VideoExportPreset: Int, Enumerable {
  case passthrough = 0
  case lowQuality = 1
  case mediumQuality = 2
  case highestQuality = 3
  case h264_640x480 = 4
  case h264_960x540 = 5
  case h264_1280x720 = 6
  case h264_1920x1080 = 7
  case h264_3840x2160 = 8
  case hevc_1920x1080 = 9
  case hevc_3840_2160 = 10

  func toAVAssetExportPreset() -> String {
    switch self {
    case .passthrough:
      return AVAssetExportPresetPassthrough
    case .lowQuality:
      return AVAssetExportPresetLowQuality
    case .mediumQuality:
      return AVAssetExportPresetMediumQuality
    case .highestQuality:
      return AVAssetExportPresetHighestQuality
    case .h264_640x480:
      return AVAssetExportPreset640x480
    case .h264_960x540:
      return AVAssetExportPreset960x540
    case .h264_1280x720:
      return AVAssetExportPreset1280x720
    case .h264_1920x1080:
      return AVAssetExportPreset1920x1080
    case .h264_3840x2160:
      return AVAssetExportPreset3840x2160
    case .hevc_1920x1080:
      return AVAssetExportPresetHEVC1920x1080
    case .hevc_3840_2160:
      return AVAssetExportPresetHEVC3840x2160
    }
  }
}

internal enum CameraType: String, Enumerable {
  case back
  case front
}
