import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_menu.dart';

class MenuStorageService {
  static const String _prefsKey = 'saved_menus_list';
  static MenuStorageService? _instance;

  /// Optional custom directory provider for testing or custom environments
  Future<Directory?> Function()? customDirectoryProvider;

  MenuStorageService._();

  static MenuStorageService get instance => _instance ??= MenuStorageService._();

  /// Gets the dedicated private directory for saved menus.
  /// Also ensures a .nomedia file exists so Android gallery/media scanners ignore it.
  Future<Directory?> _getPrivateMenuDirectory() async {
    if (kIsWeb && customDirectoryProvider == null) return null;

    final Directory baseDir;
    if (customDirectoryProvider != null) {
      final custom = await customDirectoryProvider!();
      if (custom == null) return null;
      baseDir = custom;
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }
    final menuDir = Directory('${baseDir.path}/saved_menus');
    if (!await menuDir.exists()) {
      await menuDir.create(recursive: true);
    }

    // Android/Linux: Create .nomedia file to prevent media scanning
    final nomediaFile = File('${menuDir.path}/.nomedia');
    if (!await nomediaFile.exists()) {
      try {
        await nomediaFile.create();
      } catch (e) {
        debugPrint('.nomedia creation failed: $e');
      }
    }

    return menuDir;
  }

  /// Load all saved menus, sorted by newest first
  Future<List<SavedMenu>> getSavedMenus() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> rawList = prefs.getStringList(_prefsKey) ?? [];

    final list = rawList.map((str) {
      try {
        return SavedMenu.fromJson(str);
      } catch (e) {
        debugPrint('Error parsing SavedMenu: $e');
        return null;
      }
    }).whereType<SavedMenu>().toList();

    // Sort newest first
    list.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return list;
  }

  /// Calculates next sequence number for a given office and building on a specific date
  Future<int> _getNextSeq(String officeId, String buildingName, String savedDate) async {
    final menus = await getSavedMenus();
    final matches = menus.where((m) =>
        m.officeId == officeId &&
        m.buildingName == buildingName &&
        m.savedDate == savedDate);

    if (matches.isEmpty) return 1;

    int maxSeq = 0;
    for (final m in matches) {
      if (m.seq > maxSeq) {
        maxSeq = m.seq;
      }
    }
    return maxSeq + 1;
  }

  /// Save a menu image into app-internal storage
  Future<SavedMenu> saveMenu({
    required String officeId,
    required String officeName,
    required String restaurantId,
    required String restaurantName,
    required Uint8List imageBytes,
  }) async {
    final now = DateTime.now();
    final savedDate = SavedMenu.formatDate(now);
    final buildingName = SavedMenu.extractBuildingName(restaurantName);
    final seq = await _getNextSeq(officeId, buildingName, savedDate);
    final id = now.millisecondsSinceEpoch.toString();

    // Rule: [청사명]_[건물명]_[일련번호] (e.g. 제주청사_오름동4층_1)
    final title = '${officeName}_${buildingName}_$seq';

    String filePath = '';
    String? base64Data;

    if (kIsWeb) {
      // In web, fallback to base64 encoding inside metadata
      base64Data = base64Encode(imageBytes);
      filePath = 'web_memory_$id';
    } else {
      final dir = await _getPrivateMenuDirectory();
      if (dir != null) {
        // Sanitize file name for filesystem safety
        final sanitizedTitle = title.replaceAll(RegExp(r'[\/\\:\*\?"<>\|]'), '_');
        final fileName = '${id}_$sanitizedTitle.png';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(imageBytes, flush: true);
        filePath = file.path;
      }
    }

    final savedMenu = SavedMenu(
      id: id,
      officeId: officeId,
      officeName: officeName,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      buildingName: buildingName,
      seq: seq,
      title: title,
      savedDate: savedDate,
      savedAt: now,
      filePath: filePath,
      base64Data: base64Data,
    );

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentList = prefs.getStringList(_prefsKey) ?? [];
    currentList.add(savedMenu.toJson());
    await prefs.setStringList(_prefsKey, currentList);

    return savedMenu;
  }

  /// Read the image bytes of a saved menu
  Future<Uint8List?> getImageBytes(SavedMenu menu) async {
    if (kIsWeb || menu.base64Data != null) {
      if (menu.base64Data != null) {
        return base64Decode(menu.base64Data!);
      }
      return null;
    }

    try {
      final file = File(menu.filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('Error reading menu image file: $e');
    }
    return null;
  }

  /// Delete a single saved menu by ID
  Future<bool> deleteMenu(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentList = prefs.getStringList(_prefsKey) ?? [];

    SavedMenu? targetMenu;
    final updatedList = <String>[];

    for (final itemStr in currentList) {
      try {
        final menu = SavedMenu.fromJson(itemStr);
        if (menu.id == id) {
          targetMenu = menu;
        } else {
          updatedList.add(itemStr);
        }
      } catch (_) {}
    }

    // Delete physical file if exists
    if (targetMenu != null && !kIsWeb && targetMenu.filePath.isNotEmpty) {
      try {
        final file = File(targetMenu.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }
    }

    await prefs.setStringList(_prefsKey, updatedList);
    return targetMenu != null;
  }

  /// Delete multiple saved menus by IDs
  Future<int> deleteMenus(List<String> ids) async {
    if (ids.isEmpty) return 0;
    final idSet = ids.toSet();

    final prefs = await SharedPreferences.getInstance();
    final List<String> currentList = prefs.getStringList(_prefsKey) ?? [];

    final updatedList = <String>[];
    int deletedCount = 0;

    for (final itemStr in currentList) {
      try {
        final menu = SavedMenu.fromJson(itemStr);
        if (idSet.contains(menu.id)) {
          deletedCount++;
          if (!kIsWeb && menu.filePath.isNotEmpty) {
            try {
              final file = File(menu.filePath);
              if (await file.exists()) {
                await file.delete();
              }
            } catch (e) {
              debugPrint('Error deleting file: $e');
            }
          }
        } else {
          updatedList.add(itemStr);
        }
      } catch (_) {}
    }

    await prefs.setStringList(_prefsKey, updatedList);
    return deletedCount;
  }
}
