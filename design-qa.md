# Weatherhood urban main screen QA — 2026-10-30

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
