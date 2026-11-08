# Weatherhood iOS

Swift 6 + SwiftUI 기반 iOS 전용 앱. 외부 패키지 의존성은 없습니다.

## 구현 범위

- Figma [날씨별 시안 v0.9](https://www.figma.com/design/zKUdPzZ43A0fXpTxpsUiIL?node-id=4-2)의 사용자 제공 스크린샷 기반 메인 날씨 탭
- LINE Seed KR로 앱 작성 텍스트 통일: 제목·버튼 Bold, 본문 Regular. 공통 기준은 인접 specs 레포의 `docs/typography.md`
- 승인한 부드러운 도시 스타일의 날씨·시간대 12종을 `Urban*.imageset`으로 저장. 캐릭터와 배경·접지 그림자는 한 장의 일러스트이며 UI는 네이티브 컨트롤
- 위치·날짜 캡슐 버튼 / 왼쪽 기온 / 중앙 캐릭터 / 하단 시간 눈금과 꾸미기 버튼
- 날짜 메뉴 선택, 시간 눈금 드래그·이전/다음 시간, 재생·정지, 샘플 현재 시각으로 초기화
- 날씨 버튼에서 맑음·흐림·비·눈·더위·추위·바람·천둥번개·일출·노을·맑은 밤·비 오는 밤 미리보기 선택
- 하루 끝(23:59), 탭 전환, 백그라운드 진입 시 재생 정지
- 하단 탭 제거. 시간 눈금과 재생/꾸미기/초기화는 하단에 정렬. 오른쪽 위 프로필 버튼은 NavigationStack으로 마이페이지를 표시
- 마이페이지: 메인과 연결된 날씨 헤더·가로형 프로필·28pt 이름·연보라 꾸미기 배너, 아이콘 메뉴와 섹션 구분선. 메뉴 오른쪽 화살표 표시(앱 버전·로그아웃 제외), 계정 관리 바로 아래 로그아웃 배치. 회원 탈퇴는 계정 관리 내부에 유지
- 마이페이지는 스와이프 뒤로가기를 막고 상단 뒤로가기 버튼 및 세로 스크롤을 유지. 다른 화면으로 이동하면 기존 제스처 상태를 복원
- 알림 설정 아래 위치 권한 설정은 iOS 앱 설정으로 이동. 위치 권한 요청은 아직 구현하지 않아 위치 항목이 없을 수 있음. 오픈소스 라이선스는 코드 아이콘과 준비 중 안내를 표시
- 닉네임은 기기에 저장. 캐릭터 움직임 줄이기 메뉴와 앱 자체 선호 저장은 제거. 현재 캐릭터는 정지 이미지이며 계정·알림·지역·꾸미기는 서버 미연결 안내를 표시. 로그아웃/탈퇴는 실제 계정이나 데이터를 변경하지 않음
- 지역 선택·아바타 꾸미기는 안내만 표시. 새로운 정보 화면은 추가하지 않음

## 샘플 데이터와 제한

실제 날씨/API/위치 권한/계정은 연결하지 않았습니다.
피그마와 비교하기 위해 샘플 현재 시각을 **2026-10-10 15:00, Asia/Seoul**로 고정했습니다.
'오늘'과 초기화 버튼도 이 샘플 시계를 기준으로 작동합니다. 실제 오늘의 예보가 아닙니다.
서울 중구 버튼을 누르면 이 안내를 확인할 수 있습니다.

7일과 시간별 수치는 가상 데이터이며, 공급처의 지원 기간이나 시간 해상도를 확정하지 않습니다.
재생 속도는 UI 검증용으로 **1초당 1시간**입니다. 중간 시각에는 직전 샘플의 예보를 표시합니다.
다른 날짜 선택 시 오늘은 샘플 현재 시각, 이후 날짜는 00:00으로 이동하고 정지합니다.
캐릭터는 지정된 오리너구리로 고정되며 의상/포즈/날씨 애니메이션은 아직 없습니다.
배경은 원본 레이어 추출본이 아니라 첨부 스크린샷을 참조해 생성한 대체 배경입니다.
기온의 입체 재질 대신 LINE Seed KR Bold와 색/그림자를 사용합니다. 위치/날짜는 기존 샘플 데이터에 맞춰 유지합니다.
미세먼지는 이번 승인 보드에 없어 제외했습니다. 천둥번개는 디자인 미리보기만 지원합니다.
12가지 미리보기는 예보 상태와 분리됩니다. 시간/날짜 변경·재생·초기화를 하면 샘플 예보로 돌아옵니다.
일출 미리보기는 06:00, 노을 17:30, 맑은 밤 21:00, 비 오는 밤 22:00으로 눈금도 이동합니다.
더위·추위·폭풍의 실제 임계값은 정하지 않았습니다. 맑은 샘플 예보의 06~07시는 일출, 17~18시는 노을, 06시 이전·18시 이후는 밤이며 UI 데모용 고정 구간입니다. 비도 같은 밤 구간에는 비 오는 밤으로 표시합니다. 흐림은 시간과 무관하게 기존 흐림 장면을 유지합니다. 실제 위치별 일출/일몰 계산이나 모든 날씨×시간대 조합을 구현한 것은 아닙니다.

피그마의 고정 크기는 화면 높이에 맞춰 조정했습니다. 작은 화면·큰 글자는 세로/가로 스크롤로 탐색합니다.
비·밤 장면은 어두운 테마, 나머지는 밝은 테마를 적용해 시스템 상태 표시줄도 읽을 수 있게 했습니다.
접근성 큰 글자 설정에서는 헤더/기온, 전체 일러스트, 하단 컨트롤 순으로 스크롤합니다. 시스템 상태 표시줄과 홈 인디케이터는 iOS가 표시합니다.

## 구조

- `WeatherhoodApp.swift`: 앱 진입점
- `WeatherhoodTypography.swift`: 공식 LINE Seed KR 등록, 공통 Regular/Bold 및 Dynamic Type 크기
- `Fonts/`: 공식 TTF 두 종과 SIL OFL 1.1 고지. 실행 시 CoreText로 프로세스에 등록하며 네트워크·사용자 설치가 필요하지 않음
- `ContentView.swift`: 스택 탐색과 공유 상태, 마이페이지 및 계정 관리 미리보기
- `MainWeatherView.swift`: 전체 배경, 헤더/날짜 메뉴, 기온/캐릭터, 시간 눈금, 재생 조작
- `MainWeatherState.swift`: 샘플 데이터와 선택/재생 상태 로직
- `WeatherTheme.swift`: 기존 디자인 토큰 및 이전 버전의 SVG 컴포넌트 (보존)
- `Assets.xcassets`: 현재 도시 장면 12개, 보존한 이전 배경/캐릭터/SVG 및 색상
- `DesignReference/urban-approved-board.png`: 최종 승인 보드
- `DesignReference/urban-scenes-v2.json`: 내장 이미지 생성 도구로 만든 각 이미지의 원본 경로와 정확한 프롬프트, 수정 기록
- `DesignReference/weather-scenes-v1.json`: 원본·생성 에셋·프롬프트 대응. `main-v3.json`은 이전 버전 기록
- `Tests/MainWeatherStateChecks.swift`: 의존성 없는 상태 로직 검증 프로그램

## 실행

앱에서 작성한 텍스트는 공통 서체를 사용합니다. iOS 상태 표시줄·시스템 경고창·메뉴 등 OS 소유 UI와 SF Symbols는 시스템 기본 표시를 유지합니다. Figma의 이미지로 합쳐진 글자는 변경 대상이 아닙니다. Figma는 로컬 플러그인 실행 후 결과 보고를 확인해야 하며 코드 변경만으로 자동 반영되지 않습니다.

1. `Weatherhood.xcodeproj`를 Xcode에서 엽니다.
2. `Weatherhood` Scheme과 설치된 iPhone 시뮬레이터를 선택합니다.
3. Run(⌘R)을 실행합니다.

초기 개발 설정: iOS 17.0 이상, iPhone, Bundle ID `com.example.weatherhood`.
지원 OS 정책과 Bundle ID는 임시값이며, 실기기·배포 전 고유 Bundle ID와 Signing Team을 설정해야 합니다.
앱 아이콘, 배포 서명, XCTest/UI 테스트 타깃은 아직 미설정입니다.

## 검증

```sh
xcodebuild -project Weatherhood.xcodeproj \
  -scheme Weatherhood -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/weatherhood-derived-data \
  CODE_SIGNING_ALLOWED=NO build

xcrun swiftc Weatherhood/MainWeatherState.swift Tests/MainWeatherStateChecks.swift \
  -o /tmp/weatherhood-state-checks
/tmp/weatherhood-state-checks
```

상태 검증은 초기값, 날짜·시간 선택, 재생 진행, 드래그 정지, 범위 제한,
하루 끝 정지, 초기화, 탭/백그라운드 정지용 동작, 샘플 데이터 범위를 확인합니다.
별도 XCTest 또는 실제 터치 자동화 검증과는 구분합니다.

공통 기능 요구사항은 인접한 `weatherhood-specs` 레포가 원본입니다.
