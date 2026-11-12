import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menu/models/saved_menu.dart';
import 'package:menu/services/menu_storage_service.dart';
import 'package:menu/widgets/saved_menu_bar.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('menu_test_');
    MenuStorageService.instance.customDirectoryProvider = () async => tempDir;
  });

  tearDown(() async {
    MenuStorageService.instance.customDirectoryProvider = null;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SavedMenu Model Tests', () {
    test('extractBuildingName correctly parses various restaurant names', () {
      // Rule 1: 구내식당(오름동 4층) -> 오름동4층
      expect(
        SavedMenu.extractBuildingName('구내식당(오름동 4층)'),
        equals('오름동4층'),
      );
      // Rule 2: 구내식당(본관동 11층) -> 본관동11층
      expect(
        SavedMenu.extractBuildingName('구내식당(본관동 11층)'),
        equals('본관동11층'),
      );
      // Rule 3: 1동 진주홀(1동-2, 136호) -> 1동진주홀
      expect(
        SavedMenu.extractBuildingName('1동 진주홀(1동-2, 136호)'),
        equals('1동진주홀'),
      );
      // Rule 4: 대구청사 구내식당 -> 대구청사구내식당
      expect(
        SavedMenu.extractBuildingName('대구청사 구내식당'),
        equals('대구청사구내식당'),
      );
      // Rule 5: 구내식당(조식) -> 조식
      expect(
        SavedMenu.extractBuildingName('구내식당(조식)'),
        equals('조식'),
      );
    });

    test('formatDate outputs YYYY-MM-DD correctly', () {
      final date = DateTime(2026, 9, 12, 10, 30);
      expect(SavedMenu.formatDate(date), equals('2026-09-12'));
    });

    test('SavedMenu serialization and deserialization', () {
      final now = DateTime.now();
      final menu = SavedMenu(
        id: '12345',
        officeId: 'CD006',
        officeName: '제주청사',
        restaurantId: '1057',
        restaurantName: '구내식당(오름동 4층)',
        buildingName: '오름동4층',
        seq: 1,
        title: '제주청사_오름동4층_1',
        savedDate: '2026-09-12',
        savedAt: now,
        filePath: '/mock/path/file.png',
        base64Data: 'mockBase64',
      );

      final jsonString = menu.toJson();
      final parsed = SavedMenu.fromJson(jsonString);

      expect(parsed.id, equals('12345'));
      expect(parsed.officeName, equals('제주청사'));
      expect(parsed.buildingName, equals('오름동4층'));
      expect(parsed.seq, equals(1));
      expect(parsed.title, equals('제주청사_오름동4층_1'));
      expect(parsed.savedDate, equals('2026-09-12'));
      expect(parsed.filePath, equals('/mock/path/file.png'));
      expect(parsed.base64Data, equals('mockBase64'));
    });
  });

  group('MenuStorageService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saveMenu generates sequential titles and persists items', () async {
      final service = MenuStorageService.instance;
      final dummyBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      // First save: seq 1
      final menu1 = await service.saveMenu(
        officeId: 'CD006',
        officeName: '제주청사',
        restaurantId: '1057',
        restaurantName: '구내식당(오름동 4층)',
        imageBytes: dummyBytes,
      );

      expect(menu1.title, equals('제주청사_오름동4층_1'));
      expect(menu1.seq, equals(1));

      // Second save on same office & building: seq 2
      final menu2 = await service.saveMenu(
        officeId: 'CD006',
        officeName: '제주청사',
        restaurantId: '1057',
        restaurantName: '구내식당(오름동 4층)',
        imageBytes: dummyBytes,
      );

      expect(menu2.title, equals('제주청사_오름동4층_2'));
      expect(menu2.seq, equals(2));

      // Different office: seq 1
      final menu3 = await service.saveMenu(
        officeId: 'CD001',
        officeName: '서울청사',
        restaurantId: '1041',
        restaurantName: '구내식당(조식)',
        imageBytes: dummyBytes,
      );

      expect(menu3.title, equals('서울청사_조식_1'));
      expect(menu3.seq, equals(1));

      // Check all retrieved
      final list = await service.getSavedMenus();
      expect(list.length, equals(3));

      // Delete menu 1
      final deleted = await service.deleteMenu(menu1.id);
      expect(deleted, isTrue);

      final listAfterDelete = await service.getSavedMenus();
      expect(listAfterDelete.length, equals(2));
      expect(listAfterDelete.any((m) => m.id == menu1.id), isFalse);

      // Delete remaining with bulk delete
      final bulkDeleted = await service.deleteMenus([menu2.id, menu3.id]);
      expect(bulkDeleted, equals(2));

      final emptyList = await service.getSavedMenus();
      expect(emptyList.isEmpty, isTrue);
    });
  });

  group('SavedMenuBar Widget Tests', () {
    testWidgets('Renders empty state when no saved menus exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavedMenuBar(
              savedMenus: const [],
              selectedMenuId: null,
              onSelectMenu: (_) {},
              onDeleteMenus: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('저장된 식단표 (0)'), findsOneWidget);
      expect(find.textContaining('저장된 식단표가 없습니다'), findsOneWidget);
    });

    testWidgets('Renders saved menus and supports Select All and selection mode',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final dummyMenus = [
        SavedMenu(
          id: 'menu_1',
          officeId: 'CD006',
          officeName: '제주청사',
          restaurantId: '1057',
          restaurantName: '구내식당(오름동 4층)',
          buildingName: '오름동4층',
          seq: 1,
          title: '제주청사_오름동4층_1',
          savedDate: '2026-09-12',
          savedAt: now.subtract(const Duration(minutes: 5)),
          filePath: '',
          base64Data: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        ),
        SavedMenu(
          id: 'menu_2',
          officeId: 'CD006',
          officeName: '제주청사',
          restaurantId: '1057',
          restaurantName: '구내식당(오름동 4층)',
          buildingName: '오름동4층',
          seq: 2,
          title: '제주청사_오름동4층_2',
          savedDate: '2026-09-12',
          savedAt: now,
          filePath: '',
          base64Data: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        ),
      ];

      SavedMenu? selectedMenu;
      List<String>? deletedIds;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavedMenuBar(
              savedMenus: dummyMenus,
              selectedMenuId: null,
              onSelectMenu: (menu) => selectedMenu = menu,
              onDeleteMenus: (ids) => deletedIds = ids,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check title with count
      expect(find.text('저장된 식단표 (2)'), findsOneWidget);
      expect(find.text('실시간 식단표'), findsNothing);
      expect(find.text('제주청사_오름동4층_1'), findsOneWidget);
      expect(find.text('제주청사_오름동4층_2'), findsOneWidget);

      // Tap on first saved menu
      await tester.tap(find.text('제주청사_오름동4층_1'));
      expect(selectedMenu?.id, equals('menu_1'));

      // Rebuild with selectedMenuId set to menu_1 and tap again to verify toggle back to null (live)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SavedMenuBar(
              savedMenus: dummyMenus,
              selectedMenuId: 'menu_1',
              onSelectMenu: (menu) => selectedMenu = menu,
              onDeleteMenus: (ids) => deletedIds = ids,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('제주청사_오름동4층_1'));
      expect(selectedMenu, isNull);

      // Tap "관리" (Manage) button
      await tester.tap(find.text('관리'));
      await tester.pumpAndSettle();

      // In selection mode, '전체선택' should appear
      expect(find.text('전체선택'), findsOneWidget);
      expect(find.text('(0/2)'), findsOneWidget);

      // Tap '전체선택' to select all
      await tester.tap(find.text('전체선택'));
      await tester.pumpAndSettle();
      expect(find.text('(2/2)'), findsOneWidget);
      expect(find.text('삭제 (2)'), findsOneWidget);

      // Tap delete button -> triggers confirmation dialog
      await tester.tap(find.text('삭제 (2)'));
      await tester.pumpAndSettle();

      expect(find.text('식단표 삭제'), findsOneWidget);
      expect(find.textContaining('2개의 저장된 식단표를 삭제하시겠습니까?'), findsOneWidget);

      // Confirm dialog deletion
      await tester.tap(find.widgetWithText(ElevatedButton, '삭제'));
      await tester.pumpAndSettle();

      expect(deletedIds, isNotNull);
      expect(deletedIds!.length, equals(2));
      expect(deletedIds, containsAll(['menu_1', 'menu_2']));
    });
  });
}
