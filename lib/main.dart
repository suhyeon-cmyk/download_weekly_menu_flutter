import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 사용을 위해 추가
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'dart:convert'; // JSON 처리를 위해 추가
import 'package:shared_preferences/shared_preferences.dart'; // 추가
import 'package:fluttertoast/fluttertoast.dart'; // 토스트 패키지 임포트
import 'package:url_launcher/url_launcher.dart';
import 'models/saved_menu.dart';
import 'services/menu_storage_service.dart';
import 'widgets/saved_menu_bar.dart';

// 공식 출처 링크 연결을 위한 헬퍼 함수
Future<void> _launchURL(String urlString) async {
  final Uri url = Uri.parse(urlString);
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    Fluttertoast.showToast(
      msg: '링크를 열 수 없습니다: $urlString',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }
}

// 1. 부모 데이터 (청사)
final List<Map<String, String>> officeList = [
  {'id': 'CD002', 'name': '세종청사'},
  {'id': 'CD001', 'name': '서울청사'},
  {'id': 'CD004', 'name': '과천청사'},
  {'id': 'CD003', 'name': '대전청사'},
  {'id': 'CD007', 'name': '대구청사'},
  {'id': 'CD011', 'name': '인천청사'},
  {'id': 'CD005', 'name': '광주청사'},
  {'id': 'CD008', 'name': '경남청사'},
  {'id': 'CD006', 'name': '제주청사'},
  {'id': 'CD010', 'name': '고양청사'},
  {'id': 'CD009', 'name': '춘천청사'},
  {'id': 'CD012', 'name': '충남청사'},
  {'id': 'CD013', 'name': '경북청사'},
];

// 2. 전체 자식 데이터 (제공해주신 JSON 합본)
final List<Map<String, dynamic>> allRestaurants = [
  {
    "rstrntName": "1동 진주홀(1동-2, 136호)",
    "rstrntCode": "1030",
    "upperCode": "CD002",
  },
  {
    "rstrntName": "2동 루비홀(2동-1, 116호)",
    "rstrntCode": "1029",
    "upperCode": "CD002",
  },
  {
    "rstrntName": "5동 수정홀(5동-1, 639호)",
    "rstrntCode": "1032",
    "upperCode": "CD002",
  },
  {
    "rstrntName": "6동 비취홀(6동-2, 108호)",
    "rstrntCode": "1033",
    "upperCode": "CD002",
  },
  {
    "rstrntName": "7동 대한홀(7동-1, 104호)",
    "rstrntCode": "1034",
    "upperCode": "CD002",
  },
  {"rstrntName": "9동 경복홀(201호)", "rstrntCode": "1035", "upperCode": "CD002"},
  {
    "rstrntName": "11동 경희홀(11동-2, 205호)",
    "rstrntCode": "1036",
    "upperCode": "CD002",
  },
  {
    "rstrntName": "13동 행복홀(13동-1. 619호)",
    "rstrntCode": "1037",
    "upperCode": "CD002",
  },
  {
    "rstrntName": "14동 미래홀(14동-1, 308호)",
    "rstrntCode": "1038",
    "upperCode": "CD002",
  },
  {"rstrntName": "16동 소담홀(124호)", "rstrntCode": "1039", "upperCode": "CD002"},
  {"rstrntName": "17동 한빛홀(B120호)", "rstrntCode": "1040", "upperCode": "CD002"},
  {"rstrntName": "중앙동 구내식당(1508호)", "rstrntCode": "1084", "upperCode": "CD002"},
  {"rstrntName": "중앙동 예약식당(1517호)", "rstrntCode": "1085", "upperCode": "CD002"},
  {"rstrntName": "구내식당(조식)", "rstrntCode": "1041", "upperCode": "CD001"},
  {"rstrntName": "구내식당(중식)", "rstrntCode": "1078", "upperCode": "CD001"},
  {"rstrntName": "구내식당(예약식당)", "rstrntCode": "1092", "upperCode": "CD001"},
  {"rstrntName": "주간식단표(전체)", "rstrntCode": "1043", "upperCode": "CD004"},
  {"rstrntName": "안내동 국화홀(A,B)", "rstrntCode": "1093", "upperCode": "CD004"},
  {"rstrntName": "후생동 진달래홀(한식)", "rstrntCode": "1095", "upperCode": "CD004"},
  {"rstrntName": "후생동 진달래홀(양식)", "rstrntCode": "1096", "upperCode": "CD004"},
  {"rstrntName": "안내동 예약식당", "rstrntCode": "1097", "upperCode": "CD004"},
  {"rstrntName": "석식(안내동)", "rstrntCode": "1098", "upperCode": "CD004"},
  {"rstrntName": "1동, 2동", "rstrntCode": "1049", "upperCode": "CD003"},
  {"rstrntName": "3동, 4동", "rstrntCode": "1050", "upperCode": "CD003"},
  {"rstrntName": "양식당", "rstrntCode": "1051", "upperCode": "CD003"},
  {"rstrntName": "후생동 식당", "rstrntCode": "1052", "upperCode": "CD003"},
  {"rstrntName": "대구청사 구내식당", "rstrntCode": "1073", "upperCode": "CD007"},
  {"rstrntName": "구내식당(14층)", "rstrntCode": "1054", "upperCode": "CD011"},
  {"rstrntName": "광주구내식당(4층)", "rstrntCode": "1055", "upperCode": "CD005"},
  {"rstrntName": "구내식당(본관동 11층)", "rstrntCode": "1056", "upperCode": "CD008"},
  {"rstrntName": "구내식당(오름동 4층)", "rstrntCode": "1057", "upperCode": "CD006"},
  {"rstrntName": "구내식당(5층)", "rstrntCode": "1058", "upperCode": "CD010"},
  {"rstrntName": "구내식당(5층)", "rstrntCode": "1059", "upperCode": "CD009"},
  {"rstrntName": "구내식당", "rstrntCode": "1060", "upperCode": "CD012"},
  {"rstrntName": "구내식당(1층 105호)", "rstrntCode": "1061", "upperCode": "CD013"},
];

void main() async {
  // SharedPreferences 등 비동기 작업을 main에서 하려면 필수
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final String? savedOffice = prefs.getString('lastOffice');
  final String? savedRestaurant = prefs.getString('lastRestaurant');

  // 저장된 값이 셋 다 있는지 확인
  bool hasSavedData = savedOffice != null && savedRestaurant != null;

  runApp(
    MaterialApp(
      title: '정부청사 식단표',
      // 저장된 데이터가 있으면 바로 식단표(ImageDetailScreen), 없으면 설정(SettingsScreen)
      home: hasSavedData
          ? ImageDetailScreen(
              officeId: savedOffice,
              restaurantId: savedRestaurant,
              isFirstScreen: true,
            )
          : const SettingsScreen(),
    ),
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String selectedOffice = 'CD006';
  String selectedRestaurant = '1057';
  List<Map<String, dynamic>> filteredRestaurants = [];
  bool isLoading = true; // 로딩 상태 추가
  DateTime? _lastPressedAt; // 마지막으로 뒤로가기 버튼을 누른 시간

  @override
  void initState() {
    super.initState();
    _loadSavedSettings(); // 저장된 데이터 불러오기
  }

  // 1. 저장된 데이터 불러오기
  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedOffice = prefs.getString('lastOffice') ?? officeList[0]['id']!;

      // 먼저 해당 청사의 식당 리스트를 구성
      filteredRestaurants = allRestaurants
          .where((res) => res['upperCode'] == selectedOffice)
          .toList();

      // 저장된 식당 코드가 있고, 현재 청사의 식당 리스트에 포함되어 있는지 확인
      String? savedRest = prefs.getString('lastRestaurant');
      if (savedRest != null &&
          filteredRestaurants.any((r) => r['rstrntCode'] == savedRest)) {
        selectedRestaurant = savedRest;
      } else if (filteredRestaurants.isNotEmpty) {
        selectedRestaurant = filteredRestaurants[0]['rstrntCode'];
      }

      isLoading = false;
    });
  }

  // 2. 데이터 저장하기
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastOffice', selectedOffice);
    await prefs.setString('lastRestaurant', selectedRestaurant);
  }

  void _updateRestaurantList(String officeId) {
    setState(() {
      selectedOffice = officeId;
      filteredRestaurants = allRestaurants
          .where((res) => res['upperCode'] == officeId)
          .toList();

      if (filteredRestaurants.isNotEmpty) {
        selectedRestaurant = filteredRestaurants[0]['rstrntCode'];
      }
      _saveSettings(); // 청사 변경 시 저장
    });
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중일 때는 빈 화면이나 인디케이터 표시
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false, // 시스템 뒤로가기로 화면이 나가는 것을 기본적으로 막음
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final now = DateTime.now();
        // 2초 이내에 다시 눌렀는지 확인
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;

          // 토스트 메시지 출력
          Fluttertoast.showToast(
            msg: "'뒤로' 버튼을 한 번 더 누르면 종료됩니다.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black87,
            textColor: Colors.white,
          );
        } else {
          // 2초 이내에 다시 눌렀다면 앱 종료
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('식단표 설정'),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '청사 선택',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedOffice,
                  onChanged: (val) => _updateRestaurantList(val!),
                  items: officeList.map((office) {
                    return DropdownMenuItem(
                      value: office['id'],
                      child: Text(office['name']!),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  '식당 선택',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedRestaurant,
                  onChanged: (String? val) {
                    setState(() {
                      selectedRestaurant = val!;
                      _saveSettings();
                    });
                  },
                  items: filteredRestaurants.map<DropdownMenuItem<String>>((res) {
                    return DropdownMenuItem<String>(
                      value: res['rstrntCode'].toString(),
                      child: Text(res['rstrntName'].toString()),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _saveSettings(); // 이동 전 확실히 저장
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        // 메인으로 쓰기 위해 pushReplacement 권장
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageDetailScreen(
                            officeId: selectedOffice,
                            restaurantId: selectedRestaurant,
                            isFirstScreen: false, // 설정에서 넘어온 것임
                          ),
                        ),
                      );
                    },
                    child: const Text('식단표 확인'),
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  color: Colors.grey[100],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.info_outline, size: 18, color: Colors.blueGrey),
                            SizedBox(width: 6),
                            Text(
                              '정부 기관 비제휴 및 정보 출처 공지',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. 본 앱은 정부 기관을 대표하지 않으며, 정부와 어떠한 제휴나 협력 관계도 맺지 않은 민간 개발자의 개인 비공식 앱입니다.\n'
                          '2. 본 앱에서 제공하는 식단 정보는 정부청사관리본부 공식 웹사이트의 공개 자료를 활용하여 제작되었습니다.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _launchURL('https://gbmo.go.kr'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                '공식 출처: 행정안전부 정부청사관리본부',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.open_in_new, size: 12, color: Colors.blue),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: () => _launchURL('https://gbmo.go.kr'),
                          child: const Text(
                            'https://gbmo.go.kr',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ImageDetailScreen extends StatefulWidget {
  final String officeId; // gbd
  final String restaurantId; // rc
  final bool isFirstScreen; // 첫 화면인지 여부 추가

  const ImageDetailScreen({
    super.key,
    required this.officeId,
    required this.restaurantId,
    this.isFirstScreen = false,
  });

  @override
  State<ImageDetailScreen> createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  final TransformationController _transformationController =
      TransformationController();
  bool isLandscape = false;
  late Future<Uint8List> _imageFuture;
  DateTime? _lastPressedAt; // 마지막으로 뒤로가기 버튼을 누른 시간

  Uint8List? _currentLiveImageBytes; // 실시간 다운로드된 이미지 바이트
  List<SavedMenu> _savedMenus = []; // 저장된 식단표 목록
  SavedMenu? _selectedSavedMenu; // 현재 선택된 저장 식단표 (null이면 실시간)
  Uint8List? _selectedSavedImageBytes; // 현재 선택된 저장 식단표의 이미지 바이트
  bool _isSaving = false; // 저장 진행 중 상태

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 POST 요청 시작
    _imageFuture = fetchDietImage();
    _loadSavedMenus();
  }

  Future<void> _loadSavedMenus() async {
    final list = await MenuStorageService.instance.getSavedMenus();
    if (mounted) {
      setState(() {
        _savedMenus = list;
      });
    }
  }

  String getProxyUrl(String originalUrlPath) {
    if (kIsWeb) {
      if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
        return 'https://gbmo.go.kr$originalUrlPath';
      } else {
        final baseUri = Uri.base;
        return Uri(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.port == 80 || baseUri.port == 443 ? null : baseUri.port,
          path: '/api/proxy',
          queryParameters: {'path': originalUrlPath},
        ).toString();
      }
    }
    return 'https://gbmo.go.kr$originalUrlPath';
  }

  Future<Uint8List> fetchDietImage() async {
    final urlString = getProxyUrl('/chungsa/dv/dietView/selectDietView.do');
    final url = Uri.parse(urlString);

    try {
      // 1. POST 요청으로 JSON 데이터 가져오기 (Python 소스 참고)
      final response = await http.post(
        url,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Content-Type': 'application/json;charset=UTF-8',
          'Accept': 'application/json, text/javascript, */*; q=0.01',
        },
        body: jsonEncode({
          "gbd": widget.officeId,
          "rc": widget.restaurantId,
          "sysId": "chungsa",
        }),
      );

      if (response.statusCode == 200) {
        // 2. JSON 응답 파싱
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final item = data[0];
          final String fileStreCours = item["fileStreCours"];

          // 이미지 다운로드 URL도 프록시 처리
          final fullImageUrl = getProxyUrl(fileStreCours);

          developer.log('최종 이미지 URL: $fullImageUrl', name: 'MealApp');

          // 3. 찾은 이미지 주소로 다시 GET 요청하여 이미지 바이너리 획득
          final imgResponse = await http.get(Uri.parse(fullImageUrl));

          if (imgResponse.statusCode == 200) {
            final bytes = imgResponse.bodyBytes;
            _currentLiveImageBytes = bytes;
            return bytes;
          } else {
            throw Exception('이미지 다운로드 실패 (Status: ${imgResponse.statusCode})');
          }
        } else {
          throw Exception('응답 데이터가 비어 있습니다.');
        }
      } else {
        throw Exception('서버 응답 에러: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('이미지 로딩 에러 발생', error: e, name: 'MealApp');
      throw Exception('식단표 로딩 실패: $e');
    }
  }

  Future<void> _saveCurrentMenu(String officeName, String restaurantName) async {
    if (_currentLiveImageBytes == null) {
      Fluttertoast.showToast(
        msg: '식단표 이미지를 불러오는 중입니다. 잠시 후 다시 시도해주세요.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
      );
      return;
    }

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final saved = await MenuStorageService.instance.saveMenu(
        officeId: widget.officeId,
        officeName: officeName,
        restaurantId: widget.restaurantId,
        restaurantName: restaurantName,
        imageBytes: _currentLiveImageBytes!,
      );

      await _loadSavedMenus();

      Fluttertoast.showToast(
        msg: '${saved.title} 저장되었습니다.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: '식단표 저장 실패: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectSavedMenu(SavedMenu? menu) async {
    _transformationController.value = Matrix4.identity();
    if (menu == null) {
      setState(() {
        _selectedSavedMenu = null;
        _selectedSavedImageBytes = null;
      });
      return;
    }

    final bytes = await MenuStorageService.instance.getImageBytes(menu);
    if (mounted) {
      setState(() {
        _selectedSavedMenu = menu;
        _selectedSavedImageBytes = bytes;
      });
    }
  }

  Future<void> _deleteSingleMenu(SavedMenu menu) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          '식단표 삭제',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '\'${menu.title}\' 식단표를 삭제하시겠습니까?',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await MenuStorageService.instance.deleteMenu(menu.id);
      if (_selectedSavedMenu?.id == menu.id) {
        await _selectSavedMenu(null); // 실시간 뷰로 복귀
      }
      await _loadSavedMenus();
      Fluttertoast.showToast(
        msg: '${menu.title} 삭제되었습니다.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _handleDeleteMenus(List<String> ids) async {
    final count = await MenuStorageService.instance.deleteMenus(ids);
    if (_selectedSavedMenu != null && ids.contains(_selectedSavedMenu!.id)) {
      await _selectSavedMenu(null);
    }
    await _loadSavedMenus();
    Fluttertoast.showToast(
      msg: '$count개의 식단표가 삭제되었습니다.',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  void _toggleRotation() {
    setState(() {
      isLandscape = !isLandscape;
      _transformationController.value = Matrix4.identity(); // 회전 시 위치 초기화

      if (isLandscape) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        // 가로모드 시 상태바 숨김 (Full Screen)
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        // 세로모드 시 상태바 표시
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // 앱 종료나 화면 이탈 시 상태바 복구
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 청사 이름 찾기
    final officeName = officeList.firstWhere(
      (off) => off['id'] == widget.officeId,
      orElse: () => {'name': '알 수 없는 청사'},
    )['name']!;

    // 2. 식당 이름 찾기
    final restaurantName = allRestaurants.firstWhere(
      (res) =>
          (res['upperCode'] == widget.officeId &&
          res['rstrntCode'] == widget.restaurantId),
      orElse: () => {'rstrntName': '알 수 없는 식당'},
    )['rstrntName']!;

    // 3. 최종 타이틀 문자열 조합
    final isViewingSaved = _selectedSavedMenu != null;
    final displayTitle = isViewingSaved
        ? '[저장됨] ${_selectedSavedMenu!.title}'
        : "$officeName : $restaurantName";

    // 모바일 여부 확인 (Android, iOS)
    final bool isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    return PopScope(
      canPop: false, // 시스템 뒤로가기로 화면이 나가는 것을 기본적으로 막음
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        final now = DateTime.now();
        // 2초 이내에 다시 눌렀는지 확인
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;

          // 토스트 메시지 출력
          Fluttertoast.showToast(
            msg: "'뒤로' 버튼을 한 번 더 누르면 종료됩니다.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.black87,
            textColor: Colors.white,
          );
        } else {
          // 2초 이내에 다시 눌렀다면 앱 종료
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: isLandscape
            ? null // 가로모드일 때 AppBar 숨김
            : AppBar(
                title: Text(
                  displayTitle,
                  style: const TextStyle(fontSize: 15),
                ),
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  if (isViewingSaved) ...[
                    // 저장된 식단표 개별 삭제 버튼
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      tooltip: '현재 식단표 삭제',
                      onPressed: () =>
                          _deleteSingleMenu(_selectedSavedMenu!),
                    ),
                  ] else ...[
                    // 실시간 식단표 저장 버튼
                    IconButton(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.bookmark_add_outlined),
                      tooltip: '식단표 저장',
                      onPressed: _isSaving
                          ? null
                          : () => _saveCurrentMenu(officeName, restaurantName),
                    ),
                  ],
                  // 실시간 식단표 새로고침 (저장된 식단표 열람 중에는 실시간 화면으로 복귀)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: isViewingSaved ? '실시간 식단표로 돌아가기' : '새로고침',
                    onPressed: () {
                      if (isViewingSaved) {
                        _selectSavedMenu(null);
                      }
                      setState(() {
                        _imageFuture = fetchDietImage();
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    tooltip: '정보 출처 및 면책조항',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('💡 정보 출처 및 면책 고지'),
                          content: SingleChildScrollView(
                            child: ListBody(
                              children: [
                                const Text(
                                  '본 앱은 정부 기관을 대표하지 않는 민간 개발자의 개인 비공식 앱입니다.',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  '제공되는 모든 청사 식단 정보는 행정안전부 정부청사관리본부 공식 웹사이트의 공개 자료를 실시간으로 조회하여 표시합니다.',
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '공식 출처 사이트:',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _launchURL('https://gbmo.go.kr');
                                  },
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 4.0),
                                    child: Text(
                                      '정부청사관리본부 (https://gbmo.go.kr)',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('닫기'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // 모바일 화면 회전 버튼 (세로 모드에서는 상단 AppBar에 배치하여 하단 UI 가림 방지)
                  if (isMobile)
                    IconButton(
                      icon: const Icon(Icons.screen_rotation),
                      tooltip: '가로 화면으로 회전',
                      onPressed: _toggleRotation,
                    ),
                  // 식단표 화면에서 설정을 다시 바꾸고 싶을 수 있으므로 설정 버튼 추가
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: '청사/식당 변경',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
        backgroundColor: Colors.black,
        body: Column(
          children: [
            Expanded(
              child: isViewingSaved
                  ? (_selectedSavedImageBytes != null
                      ? InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 1.0,
                          maxScale: 5.0,
                          child: Center(
                            child: Image.memory(
                              _selectedSavedImageBytes!,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ))
                  : FutureBuilder<Uint8List>(
                      future: _imageFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${snapshot.error}',
                                    style: const TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _imageFuture = fetchDietImage();
                                      });
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('다시 시도'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (snapshot.hasData) {
                          return InteractiveViewer(
                            transformationController:
                                _transformationController,
                            minScale: 1.0,
                            maxScale: 5.0,
                            child: Center(
                              child: Image.memory(
                                snapshot.data!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          );
                        } else {
                          return const Center(
                            child: Text(
                              '데이터가 없습니다.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }
                      },
                    ),
            ),
            // 하단 저장된 식단표 가로 스크롤 바 (가로모드 시 전체화면을 위해 숨김)
            if (!isLandscape)
              SavedMenuBar(
                savedMenus: _savedMenus,
                selectedMenuId: _selectedSavedMenu?.id,
                onSelectMenu: _selectSavedMenu,
                onDeleteMenus: _handleDeleteMenus,
              ),
          ],
        ),
        floatingActionButton: (isMobile && isLandscape)
            ? FloatingActionButton.small(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                tooltip: '세로 화면으로 복귀',
                onPressed: _toggleRotation,
                child: const Icon(Icons.screen_rotation),
              )
            : null,
      ),
    );
  }
}
