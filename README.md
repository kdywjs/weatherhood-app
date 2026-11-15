# Weatherhood iOS

Swift 6·SwiftUI·SpriteKit 기반 iOS 앱이다. 외부 패키지 의존성은 없으며 Xcode에서 실행한다. 기능 요구사항의 원본은 [날씨 표현](https://github.com/kdywjs/weatherhood-specs/blob/main/specs/weather-presentation/requirements.md), [주간 날씨](https://github.com/kdywjs/weatherhood-specs/blob/main/specs/weather-information/requirements.md), [캐릭터 선택](https://github.com/kdywjs/weatherhood-specs/blob/main/specs/character-selection/requirements.md)이다.

## 현재 실행 범위

- 고정 도시 배경의 메인, 시간 탐색·재생, 주간 목록과 하단 텍스트 슬라이더, 마이페이지 스택 탐색.
- SpriteKit 구름·빛·비·눈·혼합·풍속 효과와 Debug 개발자 설정. 셰이더·습도 안개·대기질 연무·기온 색감·고정 시각 낮밤은 사용하지 않는다.
- LINE Seed KR Regular/Bold를 번들에서 등록하고 WeatherhoodTypography로 사용한다. 시스템 UI와 SF Symbols는 OS 서체다. [공통 서체](https://github.com/kdywjs/weatherhood-specs/blob/main/docs/typography.md)를 따른다.
- 기존 마이페이지의 로컬 닉네임, 메뉴·계정 미리보기와 iOS 설정 이동을 유지한다. 실제 로그인·지역·계정·알림·캐릭터 저장은 미연동이다.

## 샘플과 미연동

실제 날씨 API는 연결하지 않았다. 기본 시계는 2026-10-10 15:00, Asia/Seoul이며 7일·시간별 값은 샘플이다. 재생은 검토용 1초당 1시간이며 직전 샘플 값을 사용한다. 운영 데이터 보간이나 서버 제공 범위를 뜻하지 않는다.

캐릭터와 도시 배경은 한 장의 정지 이미지다. 자동 의상·우산·마스크·옷자락 애니메이션은 자산·기준 확정 후 연결해야 한다. 날짜 행의 상세 이동은 없다. 현재 날짜 선택 메뉴도 제거되어 있다.

일출·일몰은 최신 서버 계약에 추가됐지만 앱에는 아직 연결하지 않았다. 박명 필드도 현재 계약에 없으므로 새벽·해질녘 연동은 후속 작업이다. 12개 Urban 원화와 과거 디자인 자료는 보존하지만 시계로 밤·노을·일출을 임의 선택하지 않는다.

Debug 개발자 모드의 ‘스펙 전체 설정’에서 테스트값을 바꾼다. 미리보기를 켜면 하늘·강수·풍속을 적용하며 수동 비교를 켜면 강도 프리셋을 사용한다. 수치 정보와 효과를 분리한다. 최근·시간별 대기질 선택은 정보 표시용이다. 미리보기 종료 시 기본 샘플로 돌아간다.

## 코드 위치

- `ContentView.swift`: 공유 상태, 스택 탐색, 마이페이지.
- `MainWeatherState.swift`: 샘플과 재생·시간 탐색.
- `MainWeatherView.swift`: 고정 배경, 주간 전환, 메인 UI.
- `WeatherInfoView.swift`: 주간 목록과 기온 범위 막대. 이전 전체 화면 시안 코드가 일부 남아 있으며 현재 진입은 componentOnly이다.
- `WeatherEffectConfiguration.swift`: 원본 분류·범위·누락과 배경 입력 매핑.
- `RainBackground.swift`: SpriteKit 입자와 하늘 효과. 초기화 가드·입자 수 제한·비활성화 정지.
- `WeatherDeveloperSettings.swift`: 테스트값·설정. 설정 화면은 Debug 빌드만 포함한다.
- `Fonts/`: 공식 LINE Seed KR TTF와 SIL OFL 1.1.
- `Assets.xcassets`, `DesignReference/`: 현재 이미지 및 과거 시안·검증 자료. 과거 캡처를 현재 동작 검증으로 간주하지 않는다.

## 실행

`Weatherhood.xcodeproj` → Weatherhood scheme → iPhone Simulator → Run.

iOS 17 이상, 임시 bundle ID `com.example.weatherhood`. 앱 아이콘·배포 서명·실기기 성능 검증은 후속 작업이다. Debug 환경변수 `WEATHERHOOD_DEVELOPER_SETTINGS=1`은 설정 화면을 열고, `WEATHERHOOD_PREVIEW_SCENE`은 보존된 디자인 장면을 명시적으로 확인할 때만 사용한다.

## 검증 명령

```sh
xcodebuild -quiet -project Weatherhood.xcodeproj -scheme Weatherhood \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/weatherhood-derived-data CODE_SIGNING_ALLOWED=NO build

xcrun swiftc Weatherhood/MainWeatherState.swift Tests/MainWeatherStateChecks.swift \
  -o /tmp/weatherhood-state-checks
/tmp/weatherhood-state-checks

xcrun swiftc Weatherhood/MainWeatherState.swift Weatherhood/WeatherDeveloperSettings.swift \
  Weatherhood/WeatherEffectConfiguration.swift Tests/WeatherEffectMappingChecks.swift \
  -o /tmp/weatherhood-effect-checks
/tmp/weatherhood-effect-checks
```

## 참고 및 검증

2026-11-15 작업 범위는 주간 전환·날씨 효과·개발자 도구와 추정 효과 제거다. 상태 검사와 효과 매핑 검사에서 강수 분류·범위·집계 기간·경계값·누락·수동 비교·제외 효과를 다룬다. 빌드와 제한된 시뮬레이터 실행 확인은 전체 제스처·시각 조합·실기기 성능·실제 API 연동의 검증을 대신하지 않는다. 시각적인 최종 확인은 사용자에게 남겨둔다.

검증 결과: Debug·Release 시뮬레이터 빌드 및 위 두 Swift 검사 통과. Debug 앱을 부팅된 시뮬레이터에 설치하고 실행 성공을 확인했다. 전체 제스처·날씨 조합의 시각 검증은 미실시다.
