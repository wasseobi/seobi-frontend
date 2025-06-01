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

## 개발 환경 설정

1. 시크릿 파일 설정
   - `.env` → 프로젝트 루트 디렉토리에 복사
   - `seobi.keystore` → `keys/` 디렉토리에 복사
   - `debug.keystore` → `~/.android/` 디렉토리에 복사

   > 이 파일들은 보안을 위해 Git에서 추적되지 않으며, 팀 내부에서 안전한 방법으로 공유됩니다.
   > 새로 합류하는 개발자는 팀 리더에게 요청하여 필요한 파일들을 받을 수 있습니다.

2. 앱 서명 보고서 확인 및 구글 클라우드 설정
   - 이 단계는 이미 완료된 상태이며 추가적인 작업이 필요하지 않습니다. 문제가 생길 경우에 참고하세요.
   1. 터미널에서 앱 서명 보고서 확인:
      ```bash
      cd android && ./gradlew signingReport
      ```
   2. [Google Cloud Console](https://console.cloud.google.com/) 설정:
      - 새 프로젝트를 생성하거나 기존 프로젝트 선택
      - OAuth 동의 화면 설정
      - 사용자 인증 정보 > OAuth 2.0 클라이언트 ID 생성:
        * 유형: Android 앱
        * 패키지 이름: 
          - 릴리스용: `com.wasseobi.app`, 
          - 디버그용: `com.wasseobi.app.debug`
        * SHA-1 인증서 지문: 
          - 릴리스용: `keys/seobi.keystore`
          - 디버그용: `~/.android/debug.keystore`
      - 웹 애플리케이션용 클라이언트 ID도 추가로 생성
      - 생성된 클라이언트 ID들을 `.env` 파일에 설정

   > 디버그 빌드와 릴리스 빌드의 패키지 이름이 다르므로, 구글 클라우드 콘솔에 두 개의 안드로이드 앱 ID를 등록해야 합니다.


## 키스토어 관리

### 키스토어 직접 생성하기

1. **Java JDK 설치**
   - [Oracle Java Downloads](https://www.oracle.com/java/technologies/downloads/)에서 다운로드
   - JDK의 `bin/` 디렉토리 경로를 환경 변수에 추가 권장
   - 설치 확인: `keytool -version`

2. **새 키스토어 생성**
   ```bash
   keytool -genkey -v -keystore keys/seobi.keystore -alias seobi_key -keyalg RSA -keysize 2048 -validity 10000
   ```

### 보안 주의사항

1. 키스토어 파일과 비밀번호는 절대로 GitHub에 커밋하지 마세요.
2. `keys/` 디렉토리와 `*.keystore` 파일은 .gitignore에 포함되어 있습니다.
3. 키스토어 파일과 비밀번호는 안전한 곳에 백업해두세요.

## 빌드

### 디버그 빌드
```pwsh
flutter clean && flutter pub get && flutter build apk
```

### 릴리스 빌드
```pwsh
flutter clean && flutter pub get && flutter build apk --release
```
