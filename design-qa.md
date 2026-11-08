# Weatherhood profile screen QA — 2026-11-08

final result: passed

## Scope and evidence

- Visual-only local profile implementation; no production account, alerts, location or wardrobe services.
- Source: `DesignReference/profile-approved.png` (1263 × 1246 two-panel concept).
- Implementation: `DesignReference/QA/profile/top.png`, `bottom.png` (1206 × 2622 each; iPhone 17 Pro, 402 × 874 points at 3x, iOS 26.5).
- Opened the source and both final rendered captures together in one comparison input. Compared app-owned regions relative to each portrait viewport; excluded reference outer margins/captions and native device chrome. This is not pixel-exact matching: reference is a generated concept, system fonts and original approved app mascot take precedence.
- States: top of profile and scroll end. Bottom screenshot is further down than the reference's right panel because real menu rows are 60pt and use safe-area insets; settings remain above in the same scroll view. All account actions are visible at scroll end.
- Focused text, profile image and logout review used the full-resolution captures; those regions are legible without separate crops.

## Findings and iteration

- [P2, resolved] First avatar showed the whole body rather than the reference portrait. Increased crop scale to 1.45, top-anchored, retaining original Violet-Light-02 asset. Final top capture confirms head and upper body inside the white-bordered circle.
- [P3] Native iOS 26 back chevron includes the system glass backing. Retained native back behavior rather than drawing a replacement. No back label or page title remains.
- [P3] Native off-switch is subtler than the generated reference. Setting is local-only; current character is static.
- No remaining P0/P1/P2 visual findings in the inspected states.

## Fidelity surfaces

- Typography: iOS system Korean text, bold name and headings; no missing font or zero-width text. All source menu labels preserved.
- Layout: overlapping circular portrait, 24pt horizontal margins, 32pt section gaps, 60pt rows, 20pt card corners, scrollable content. No bottom tabs. Main screen remains independent of profile scrolling.
- Colors: brand #9587EF, pale lavender background, white cards, dark violet ink and muted logout. Deliberately flat brand fill rather than reproducing generated image lighting.
- Imagery: existing approved app mascot reused, not generated mockup's altered face. No full-screen image masquerades as controls.
- Content: membership deletion inside account management, quiet logout at bottom; no large destructive button on profile. Unimplemented actions explicitly disclose their status rather than claiming service success.

## Verification / remaining limits

- Debug simulator build passed; installed and launched. Top and end-of-scroll captures inspected after correction.
- Existing Foundation weather-state checks passed (selection/playback/scrub/reset/12 scenes/ruler).
- Native NavigationStack push is wired to the existing profile callback; native back button preserved through minimal back-title configuration.
- Actual tap/swipe, nickname entry and VoiceOver were NOT automated: computer-use runtime failed to start (missing Node runtime). Rendering used DEBUG-only launch arguments `--profile-preview` and `--profile-bottom`. These do not alter normal launches.
- Nickname and motion preference persist locally. Logout/deletion show honest prototype notices and never alter accounts or data. Server integration remains out of scope.
- Additional devices, landscape and largest Dynamic Type sizes require manual follow-up.

---

# Historical weather-main QA — 2026-10-30

final result: passed

## Current scope and evidence

- Source visual truth: `DesignReference/urban-approved-board.png` (1024 × 1536), approved soft urban 12-screen board with no bottom tabs and lowered controls.
- Native SwiftUI implementation: `DesignReference/QA/urban-v2/` contains all twelve scene screenshots; `dawn-final.png`, `sunset-final.png`, `night-final.png`, `rainNight-final.png` supersede their earlier captures.
- Device: iPhone 17 Pro / iOS 26.5, 402 × 874 logical points, 1206 × 2622 pixels (3x). Generated art plates are 852 × 1846. Compared relative app-owned regions; board panels are smaller and omit OS chrome. This is not a pixel-exact recreation claim. No web viewport/CSS applies to this native project.
- Full-view comparison: source board and simulator captures opened together in the same comparison input before and after revisions. All twelve rendered scenes inspected individually. Focused review of temperature, footer text, feet/contact shadows and time labels used the legible full-resolution portrait captures; separate crops were unnecessary. The source board's tiny generated text is not treated as authoritative copy.

## Findings and corrections

1. [P2, resolved] A narrow uncovered strip appeared above the status area in `sunny-v1.png`. Extended background overscan by 40 points; `sunny.png` confirms full coverage and retained foot contact.
2. [P2, resolved] Initial rainy-night art included lightning, confusing it with the dedicated storm scene. Removed the lightning with a narrow image edit. `rainNight-final.png` shows ordinary rain, while `storm.png` retains lightning.
3. [P2, resolved] Time-of-day previews initially retained 15:00. Added per-scene preview times (06:00 / 17:30 / 21:00 / 22:00); final dawn/sunset/night screenshots confirm corresponding ruler positions. These are demo times, not astronomical calculations.
4. [P3] Independently generated plates have small differences in mascot scale, building detail and highlights between scenes. They retain the approved character, urban layout, soft animation direction and grounding, but are not pixel-identical extractions from the board.
5. [P3] The moon partly sits behind the date capsule in the night plate. UI text remains readable; optional artwork-position polish remains.

## Fidelity surfaces

- Typography: user-selected iOS system fonts, rounded bold temperature and tracked wordmark retained. Native legible labels replace distorted generated reference text. Native 44-point control heights take precedence over small mockup labels.
- Layout: no TabView or bottom tab capsule. Time ruler and play/customize/reset group align near the bottom with safe-area spacing. Profile remains accessible through top-right button and a dismissible sheet. Character is not rendered twice. Accessibility-medium stacks selectors and shows an uncropped illustration in scroll content (`accessibility.png`, rainy sample state); lower controls are below the fold by design.
- Colors: warm daytime, blue winter, muted cloudy/rain, orange dawn/sunset, dark blue night; dark/rain controls use light text with a subdued backing for contrast. Header/status appearance follows scene brightness. Small contrast backing on ruler is an intentional readability adaptation.
- Imagery: local clean 12-scene plates preserve purple platypus + contact shadow together. UI is real SwiftUI, not a full-screen screenshot. New plate generation uses the approved image as reference; prompts and original/corrected paths are in `urban-scenes-v2.json`. Previous assets are retained.
- Copy: Seoul Jung-gu / fixed 2026-10-10 sample date retained, preview/sample labeling visible. No real-weather claim; customization/location/profile remain honest placeholders. Weather and time-of-day labels cover the twelve approved scenes.

## Verification and limitations

- Debug simulator build passed, no new dependencies.
- Foundation state checks passed: selection/playback/scrub/clamps/reset, twelve unique assets, dawn/sunset/night boundaries, rainy-night mapping and preview times, exhaustive ruler-window bounds and drag conversion.
- All 12 scenes rendered in the simulator using DEBUG environment overrides; default and accessibility-medium text captured, then text size restored to large.
- Computer-control runtime failed to start (Node runtime unavailable). Actual tap/drag, menu selection and sheet dismissal were not automated; rendered evidence and state checks do not claim end-to-end UI coverage. Manual interaction and VoiceOver testing remain recommended.
- No live API, location permission, production sunrise/sunset calculations, weather animation, all weather×time combinations or customization implemented. Cloudy keeps its existing single plate. Landscape/smaller devices not visually certified in this pass.
- All work local only: no Git add/commit/push, GitHub writes, Figma writes, server edits or deployment.

## Implementation checklist

- [x] Approved urban illustration direction and twelve preview scenes
- [x] Bottom tabs removed; footer alignment and native controls preserved
- [x] Source/prompt provenance and simulator screenshots retained
- [x] Build and state checks pass; visual corrections rechecked
- [ ] Manual touch/VoiceOver and additional-device QA

---

# Historical QA — preceding weather-scene iteration (superseded)

final result: passed

## Scope and evidence

- Source visual truth: `DesignReference/weather-board-source.png` and `DesignReference/character-source.png` (user attachments; Figma weather v0.9 board and Violet-Light-02 selection).
- Implementation: `DesignReference/QA/sunny-final.png`, `rain-v2.png`, `night-v2.png`, and the other five scene captures. All are simulator-rendered SwiftUI, not generated screen mockups.
- iPhone 17 Pro, iOS 26.5, 402 × 874 logical points, screenshot 1206 × 2622 at 3x. Reference desktop screenshot 3420 × 2224, with weather frames embedded at different scales. Compared app-owned regions relative to viewport, excluding Figma/OS chrome; not a pixel-exact comparison claim.
- Full-view comparison: supplied board and sunny simulator screenshot were opened together; rainy/night revisions and the board were also opened in one comparison input. Eight individual rendered scene images were inspected.
- Focused inspection: header/selector labels, mascot outline/feet, ruler and footer were legible in the 942 × 2048 displayed captures. No extra crop was needed. Alpha metadata confirms character transparency (1254 × 1254).

## Findings and iteration history

1. [P2, resolved] Initial background ended above the device bottom, leaving a white strip (`sunny-v1.png`). Extended decorative background coverage. `sunny-final.png` confirms continuous backdrop to the home indicator.
2. [P2, resolved] Rain ruler was dark against wet pavement (`rain-final.png`). Switched rain foreground to light and added a subdued backing to its ruler. `rain-v2.png` confirms readable labels and controls.
3. [P2, resolved] Night system status bar stayed black (`night-final.png`). Removed fixed root light appearance and selected the preferred scheme by scene. `night-v2.png` confirms white system status information.

## Required fidelity surfaces

- Typography: user-approved iOS system font throughout. Large rounded temperature, tracked compact wordmark, caption controls. 3D number textures are intentionally simplified to live text with color/shadow; no exact texture match is claimed.
- Layout: source order retained: wordmark/profile, location/date capsules, left temperature and weather capsule, mascot, ruler, avatar action. Native tabs and playback/reset controls retained from agreed implementation. Smaller heights remain vertically scrollable.
- Colors: warm orange sunny/hot, cool blue cold/snow, slate cloudy/wind, light rain/night values. Generated scenery follows each source weather palette. Header and native controls adapt for night/rain.
- Imagery: designated purple platypus retained, transparent background derivative; eight independent generated backdrop plates. No full-screen screenshot is used as UI. Backdrops are approximate recreations, not original Figma layers. Same mascot pose/clothing across states is intentional; no motion is claimed.
- Content: existing mock Seoul Jung-gu/date/time retained rather than fabricated live weather. Explicit preview/sample label, honest unimplemented location/customization notices. Weather menu lists eight visible reference scenes; dust and thunder are excluded because the source attachment hides them.
- Accessibility: default and accessibility-medium text sizes captured. Larger selectors stack vertically, content scrolls below the fold; simulator text size restored to large. Core controls have labels, the ruler has adjustable actions, and native menus/tab navigation supply semantics. Formal VoiceOver audit not performed.

## Verification

- Debug simulator build passed.
- Foundation-only checks passed: prior date/time selection, play/pause, end-of-day stop, clamp/reset checks, eight unique scene assets, clear-night mapping, every minute's ruler window, drag conversion and invalid fractions.
- Rendered all eight preview scenes through a DEBUG-only environment override.
- UI automation could not start because the computer-control Node runtime was unavailable. Physical tap/drag and menu-interaction testing was not performed; state tests and render verification are not represented as end-to-end UI automation.

## Follow-up polish

- P3: refine mascot-to-ground contact and scene-specific lighting once final art is available.
- P3: optional true 3D temperature material and weather-specific poses are outside this iteration.
- Real forecast API, location selection, customization, dust/thunder and other tabs remain out of scope.

## Implementation checklist

- [x] Screenshot-based SwiftUI main tab and designated character
- [x] Eight local background assets and provenance
- [x] Main state checks and visual corrections
- [x] No Figma edits, server edits, dependency installs or Git commits
# LINE Seed KR 통일 검증 — 2026-11-08

## 마이페이지 3안 적용 — 후속 검증

- 기준: `DesignReference/profile-three-approved.png`. 사용자 요청으로 캐릭터 움직임 줄이기 메뉴와 해당 앱 설정을 제거했습니다.
- 흰 바탕, 가로 프로필, 연보라 꾸미기 배너, 아이콘 메뉴와 섹션 구분선 적용. LINE Seed KR 유지. 기존 계정 관리 및 로그아웃 안내 동작 유지.
- 결과: Debug 시뮬레이터 빌드 PASS, MainWeatherStateChecks PASS, diff 공백 검사 PASS. `DesignReference/QA/profile-three/top.png`, `bottom.png`에서 배너·본문·계정 관리·로그아웃 시각 확인.
- 원본 시안과 화면 비율이 달라 메뉴는 스크롤로 이어집니다. iOS 기본 뒤로가기 및 기존 원본 캐릭터를 사용하므로 생성 이미지와 완전한 픽셀 일치는 아닙니다.
- 제한: 전체 탭 상호작용, 실기기 및 모든 접근성 크기는 이번 변경 후 검증하지 않았습니다. 서버 연결 기능은 기존 준비 중 안내 상태입니다.
- Figma: 기존 로컬 플러그인에 ‘마이페이지 3안 반영’ 추가. 편집 가능한 텍스트/아이콘/배너를 별도 마이페이지 프레임으로 생성하며 기존 프레임은 보존합니다. 직접 연결 호출 한도 때문에 실제 Figma 실행과 렌더 검증은 미완료입니다. JS 문법 및 기존 폰트 전환 모의 테스트 통과는 실제 Figma 렌더 검증을 대체하지 않습니다.

이 문서의 과거 검증에 기록된 시스템 서체 기준은 현재 적용 기준이 아닙니다. 현재 기준은 인접 `weatherhood-specs/docs/typography.md`입니다.

- 공식 Regular/Bold TTF 번들 포함, 프로세스 등록 및 PostScript 이름 확인. 앱 실행 시 누락/등록 실패를 검출합니다.
- Debug 시뮬레이터 빌드 통과. 기존 MainWeatherStateChecks 통과. 프로젝트 plist 및 diff 공백 검사 통과.
- 메인 기본 크기와 마이페이지 상단/설정 항목의 LINE Seed KR 표시를 시각 확인했습니다. 증적: `DesignReference/QA/typography/main.png`, `profile.png`.
- 접근성 medium의 메인 하단 글자 확대와 버튼 표시를 확인했습니다 (`main-accessibility-footer.png`). 전체 화면·모든 크기 및 실제 기기 검증은 수행하지 않았습니다. 시뮬레이터 크기는 원래 large로 복원했습니다.
- SF Symbols와 OS 소유 경고창·메뉴·상태 표시줄은 시스템 표시를 유지합니다.
- Figma 직접 연결은 호출 한도로 미실행. 로컬 플러그인의 폰트 전환 함수 모의 테스트에서 Regular/Bold 매핑, 기존 스타일 갱신, 아이콘 제외, 대상 폰트 누락 시 중단 및 JS 문법 검증을 통과했습니다. 실제 Figma 파일 반영·레이아웃 검증은 사용자 플러그인 실행 후 확인해야 합니다.
