# Weekly Menu Flutter (menu)

주간 식단 다운로드 및 뷰어 플러터(Flutter) 프로젝트입니다.

---

## 🚀 시작하기 (Getting Started)

프로젝트를 로컬 환경에서 구동하기 위한 가이드입니다. 먼저 Flutter SDK가 설치되어 있어야 합니다.

### 1. 의존성 패키지 설치 (Install Dependencies)

프로젝트에 필요한 외부 라이브러리 및 패키지를 다운로드하고 설치합니다.
```bash
flutter pub get
```

### 2. 크롬(Web)으로 실행 (Run on Chrome)

웹 브라우저(크롬)에서 프로젝트를 실행합니다. API 호출 시 발생할 수 있는 CORS 제약을 우회하기 위해 웹 보안을 비활성화하는 플래그가 포함되어 있습니다.
```bash
flutter run -d chrome --web-browser-flag="--disable-web-security"
```

### 3. 안드로이드(Android)로 실행 (Run on Android)

연결된 안드로이드 실기기 또는 에뮬레이터에서 실행합니다.

* **연결된 디바이스 목록 및 ID 확인**:
  ```bash
  flutter devices
  ```
* **안드로이드 기기로 실행**:
  ```bash
  # 특정 디바이스 ID를 지정하여 실행하는 경우
  flutter run -d <device_id>

  # 또는 사용 가능한 안드로이드 기기로 바로 실행하는 경우
  flutter run -d android
  ```

#### 📶 Wi-Fi 무선 디버깅 연결 방법 (Android 11 이상)

USB 케이블 연결 없이 동일한 Wi-Fi 네트워크 상에서 앱을 무선으로 빌드하고 설치할 수 있습니다.

1. **사전 준비**: 
   * 개발 PC와 안드로이드 기기가 **동일한 Wi-Fi 네트워크**에 연결되어 있어야 합니다.
   * PC에 Android SDK 플랫폼 도구(`adb`)가 설치되어 있어야 합니다.

2. **기기 설정**:
   * 안드로이드 **설정 > 휴대전화 정보 > 소프트웨어 정보**에서 **빌드 번호**를 7번 연타하여 '개발자 옵션'을 활성화합니다.
   * **설정 > 개발자 옵션**으로 이동하여 **무선 디버깅(Wireless Debugging)**을 활성화합니다.

3. **기기 페어링 (최초 1회)**:
   * 무선 디버깅 옵션을 터치하여 상세 메뉴로 진입한 후 **'페어링 코드로 기기 페어링'**을 선택합니다.
   * 화면에 나오는 **IP 주소 및 포트**와 **6자리 페어링 코드**를 확인합니다.
   * PC 터미널에서 다음 명령어를 실행하여 페어링합니다.
     ```bash
     adb pair <IP_주소>:<포트>
     # 예: adb pair 192.168.0.10:37281
     ```
   * 프롬프트에 확인한 6자리 페어링 코드를 입력합니다.

4. **디버거 연결**:
   * 페어링 완료 후, 무선 디버깅 메인 화면의 **'IP 주소 및 포트'**를 확인합니다 (페어링 시 포트와 다를 수 있습니다).
   * PC 터미널에서 다음 명령어로 기기에 연결합니다.
     ```bash
     adb connect <IP_주소>:<포트>
     # 예: adb connect 192.168.0.10:41235
     ```
   * `adb devices` 명령어로 `connected` 상태를 확인합니다.

5. **앱 빌드 및 실행**:
   * 연결된 기기 정보를 확인한 후, 프로젝트 폴더에서 앱을 구동합니다.
     ```bash
     flutter run -d adb-R3CY20MZ6GH-EbZdH2._adb-tls-connect._tcp
     ```

#### 🤖 구글 플레이스토어 배포 가이드 (Google Play Store Release)

구글 플레이스토어에 앱을 출시하기 위한 핵심 절차 정리입니다.

##### 1. 패키지명(Application ID) 변경 (필수)
`com.example`이 포함된 기본 패키지명은 스토어 등록이 불가능합니다. 본인만의 고유한 패키지명으로 변경해 줍니다.
* **패키지 변경 도구 설치 및 실행**:
  ```bash
  flutter pub add dev:change_app_package_name
  flutter pub run change_app_package_name:main com.cmyk.gov_cafeteria_helper
  ```

##### 2. 디지털 서명 키(Keystore) 생성 및 설정
1. **Keystore 키 파일 생성**:
   ```bash
   keytool -genkey -v -keystore C:\Users\jini2\Downloads\a\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias key
   

    Re-enter new password : Kosaf@66842

    What is your first and last name?
    [Unknown]:  suhyeon_ji
    What is the name of your organizational unit?
    [Unknown]:  cmyk
    What is the name of your organization?
    [Unknown]:  cmyk
    What is the name of your City or Locality?
    [Unknown]:  seoul
    What is the name of your State or Province?
    [Unknown]:  seoul
    What is the two-letter country code for this unit?
    [Unknown]:  KR
    Is CN=suhyeon_ji, OU=cmyk, O=cmyk, L=seoul, ST=seoul, C=KR correct?
    [no]:  yes

    Generating 2,048 bit RSA key pair and self-signed certificate (SHA256withRSA) with a validity of 10,000 days
            for: CN=suhyeon_ji, OU=cmyk, O=cmyk, L=seoul, ST=seoul, C=KR
    Enter key password for <key>
            (RETURN if same as keystore password):Kosaf@66842

    Re-enter new password: 

    [Storing C:\Users\jini2\Downloads\a\upload-keystore.jks]

    Warning:
    The JKS keystore uses a proprietary format. It is recommended to migrate to PKCS12 which is an industry standard format using "keytool -importkeystore -srckeystore C:\Users\jini2\Downloads\a\upload-keystore.jks -destkeystore C:\Users\jini2\Downloads\a\upload-keystore.jks -deststoretype pkcs12". 
    PS D:\dev\workspace\flutter\menu> 

   ```
2. **`key.properties` 파일 생성** (`android/key.properties`):
   ```properties
   storePassword=<설정한_비밀번호>
   keyPassword=<설정한_비밀번호>
   keyAlias=key
   storeFile=<upload-keystore.jks_파일_경로>
   ```
3. **`android/app/build.gradle` 서명 설정 적용**:
   ```groovy
   def keystoreProperties = new Properties()
   def keystorePropertiesFile = rootProject.file('key.properties')
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(new java.io.FileInputStream(keystorePropertiesFile))
   }

   android {
       ...
       signingConfigs {
           release {
               keyAlias keystoreProperties['keyAlias']
               keyPassword keystoreProperties['keyPassword']
               storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
               storePassword keystoreProperties['storePassword']
           }
       }
       buildTypes {
           release {
               signingConfig signingConfigs.release
           }
       }
   }
   ```

##### 3. 앱 번들(AAB) 빌드
구글 플레이스토어 업로드 규격인 AAB 파일로 빌드합니다.
```bash
flutter build appbundle
```
* 빌드 완료 후 파일 위치: `build/app/outputs/bundle/release/app-release.aab`

##### 4. 구글 플레이 콘솔 업로드
1. [Google Play Console](https://play.google.com/console) 가입 (등록비 $25).
2. 새 앱 생성 및 필수 설정 사항(개인정보처리방침, 콘텐츠 등급 등) 설문 작성.
3. 스토어 정보(앱 이름, 설명, 앱 아이콘, 크기별 스크린샷 이미지) 등록.
4. 빌드된 `.aab` 파일을 프로덕션/테스트 트랙에 업로드한 후 검토 및 출시 제출.

---

## 📦 Git 워크플로우 (Git Workflow)

### 첫 커밋 및 Push
```bash
git init
git add .
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/suhyeon-cmyk/download_weekly_menu_flutter.git
git push -u origin main
```

### 변경 사항 Commit 및 Push
```bash
git add .
git commit -m "커밋 메시지 작성"
git branch -M main
git push -u origin main
```

### 원격 저장소 관리 (git remote)

로컬 폴더와 연결된 원격 저장소를 확인하거나 주소를 관리합니다.

* **연결된 원격 저장소 목록 및 주소 확인 (-v)**:
  ```bash
  git remote -v
  ```
* **새로운 원격 저장소 연결 추가 (add)**:
  ```bash
  git remote add origin <원격저장소_주소>
  ```
* **기존 원격 저장소 연결 주소 변경 (set-url)**:
  ```bash
  git remote set-url origin <새로운_원격저장소_주소>
  ```
* **원격 저장소 연결 삭제 (remove)**:
  ```bash
  git remote remove origin
  ```