import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';

class StorageMethods {
  // ඔබගේ Cloud Name: du3xszpzr
  // ඔබගේ Preset Name: Social_media
  // මේවායේ අකුරක් හෝ වැරදී ඇත්දැයි නැවත පරීක්ෂා කරන්න.
  final cloudinary = CloudinaryPublic(
    'du3xszpzr',
    'Social_media',
    cache: false,
  );

  Future<String> uploadImageToStorage(
    String childName,
    Uint8List file,
    bool isPost, {
    CloudinaryResourceType? resourceType,
    String? extension,
  }) async {
    try {
      CloudinaryResourceType resType =
          resourceType ??
          (childName == 'reels'
              ? CloudinaryResourceType.Video
              : CloudinaryResourceType.Image);

      String extensionToUse = extension ?? _getFileExtension(file, resType);
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          file,
          // Identifier එකක් ලබා දීම අනිවාර්ය නිසා අද්විතීය අගයක් ලබා දෙමු
          identifier:
              'file_${DateTime.now().millisecondsSinceEpoch}.$extensionToUse',
          resourceType: resType,
          folder: childName,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      debugPrint("--- Cloudinary Full Debug ---");
      debugPrint(e.toString());

      String errorMsg = "Upload failed";

      if (e is CloudinaryException) {
        // සර්වර් එකෙන් එවන සැබෑ පණිවිඩය ලබා ගැනීම
        errorMsg = e.message ?? "Unknown Cloudinary Error";
      } else {
        errorMsg = e.toString();
      }

      // වඩාත් පැහැදිලි උපදෙස් ලබා දීම
      throw "Cloudinary Error: $errorMsg \n\nවිසඳුම: \n1. Cloudinary Dashboard එකේ 'Social_media' Preset එක Edit කර 'General' ටැබ් එකේ 'Asset folder' කොටස හිස් කරන්න. \n2. 'Unsigned' mode එකේ ඇති බව තහවුරු කරන්න.";
    }
  }

  String _getFileExtension(Uint8List bytes, CloudinaryResourceType resType) {
    if (resType == CloudinaryResourceType.Video) {
      return 'mp4';
    }

    if (bytes.length >= 4) {
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
        return 'jpg';
      }
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'png';
      }
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return 'gif';
      }
      if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46) {
        return 'png';
      }
    }
    return 'jpg';
  }
}
