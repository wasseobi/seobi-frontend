# seobi_app

A new Flutter project.

## 초기 설정

1. **Android Studio** 설치
   1. Android Studio 실행 > [More Actions] > [SDK Manager] > [SDK Tools] 탭 > 하단 [Hide Obsolete Packages] 체크 해제
   2. 목록에서 `Android SDK Command-line Tools (latest)`, `Android SDK Tools (Obsolete)` 체크 후 [OK] 클릭
2. **Visual Studio Code** 실행
3. Visual Studio Code **Flutter 확장** 설치
4. Flutter 확장의 제안에 따라 **Flutter SDK** 설치
5. 터미널에서 `flutter pub get` 실행 (보통 직접 호출하지 않아도 자동으로 호출됨)

## 키스토어 설정

### 1. 키스토어 생성
**keytool**은 Java JDK에 포함되어 있는 보안 유틸리티입니다. JDK가 설치되어 있지 않다면 [Oracle Java Downloads](https://www.oracle.com/java/technologies/downloads/)에서 다운로드하여 설치하세요. 편의를 위해 설치된 JDK 내부의 `bin/` 디렉토리 경로를 환경 변수에 추가할 것을 권장합니다.

터미널에서 `keytool -version` 명령어를 실행하여 **keytool**이 잘 설치되었는지 확인할 수 있습니다.

새 키 스토어를 생성하려면 다음 명령어를 실행하세요:

```bash
keytool -genkey -v -keystore keys/seobi.keystore -alias seobi_key -keyalg RSA -keysize 2048 -validity 10000
```

### 2. 개발 환경 설정

1. `keys/` 디렉토리에 있는 `seobi.keystore` 파일을 프로젝트의 키스토어로 사용합니다.

### 3. SHA-1 인증서 지문 확인 및 Google Cloud Console 설정

1. 키스토어의 SHA-1 인증서 지문을 확인합니다:
   ```bash
   keytool -list -v -keystore keys/seobi.keystore -alias seobi_key
   ```
   이 명령어를 실행하면 SHA-1, SHA-256 등의 인증서 지문이 표시됩니다.

2. [Google Cloud Console](https://console.cloud.google.com/) 설정:
   - 새 프로젝트를 생성하거나 기존 프로젝트 선택
   - OAuth 동의 화면 설정
   - 사용자 인증 정보 > OAuth 2.0 클라이언트 ID 생성:
     * 유형: Android 앱
     * 패키지 이름: `com.wasseobi.app`
     * SHA-1 인증서 지문: 위에서 확인한 SHA-1 값 입력
   - 웹 애플리케이션용 클라이언트 ID도 추가로 생성
   - 생성된 클라이언트 ID들을 `.env` 파일에 설정

3. 앱 서명 보고서 확인:
   - 터미널에서 다음 명령어를 실행하여 앱 서명 보고서를 확인합니다:
   ```bash
   cd android && ./gradlew signingReport
   ```

### 4. 보안 주의사항

1. 키스토어 파일과 비밀번호는 절대로 GitHub에 커밋하지 마세요.
2. `keys/` 디렉토리와 `*.keystore` 파일은 .gitignore에 포함되어 있습니다.
3. 키스토어 파일과 비밀번호는 안전한 곳에 백업해두세요.

## 환경 변수와 키스토어 설정

1. 팀에서 안전하게 공유받은 파일들을 다음과 같이 배치합니다:
   - `.env` 파일 → 프로젝트 루트 디렉토리에 복사
   - `seobi.keystore` 파일 → `keys/` 디렉토리에 복사

환경 변수 파일 구조 참고:
```properties
# Google OAuth
GOOGLE_ANDROID_CLIENT_ID=<팀 내부에서 공유된 Android 클라이언트 ID>
GOOGLE_WEB_CLIENT_ID=<팀 내부에서 공유된 웹 클라이언트 ID>

# Keystore Configuration
KEYSTORE_PATH=keys/seobi.keystore
KEYSTORE_PASSWORD=<팀 내부에서 공유된 키스토어 비밀번호>
KEYSTORE_KEY_PASSWORD=<팀 내부에서 공유된 키 비밀번호>
KEYSTORE_ALIAS=seobi_key
```

이 파일들은 보안을 위해 Git에서 추적되지 않으며, 팀 내부에서 안전한 방법으로 공유됩니다. 새로 합류하는 개발자는 팀 리더에게 요청하여 필요한 파일들을 받을 수 있습니다.