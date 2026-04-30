# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

"穿什么" — a Flutter app that pairs an Open-Meteo weather forecast with daily outfit recommendations. Single-screen primary use case; secondary tabs for 7-day forecast, wardrobe reference, and settings.

## Commands

- `flutter pub get` — install deps
- `flutter run` — run on attached device/emulator (hot reload). Native (Android manifest, res/, Kotlin) changes require a full reinstall, not hot reload.
- `flutter analyze` — must stay at "No issues found" before merging
- `flutter test` — full suite
- `flutter test test/features/weather/forecast_cache_test.dart` — single file
- `flutter test --plain-name "yields cache"` — single test by name substring
- `flutter build apk --debug` — verify Android side compiles (needed when changing manifest, layouts, or `WeatherWidgetProvider.kt`)

## Architecture

### Layering
`lib/core/` is platform/utility (router, theme, units, storage, error mapping, widgets, home-screen widget sync). `lib/features/<area>/` follows a fixed three-folder split: `model/`, `repository/` or `controller/`, `view/`. Outfit also has `data/` (the static catalog).

### State management
Riverpod 2.x. `SharedPreferences` is pre-warmed in `main.dart` and injected via `sharedPreferencesProvider.overrideWithValue(prefs)`. Controllers (e.g. `SelectedLocationController`, `UserPreferencesController`) load their persisted state **synchronously** in the constructor — the router and other consumers depend on the initial value being available immediately on first build. Tests mirror this with `SharedPreferences.setMockInitialValues({...})` and the same override.

Persistence keys are versioned strings: `selected_location.v1`, `user_preferences.v1`, `forecast_cache.v1`. Bump the suffix on schema breaks.

### `forecastProvider` is a `StreamProvider`, not a Future
It yields up to two values: cached forecast (if location matches) → fresh fetch. On network failure with a usable cache, it silently stays on cached data; without a cache, the error propagates. Callers continue to consume `AsyncValue<WeatherForecast>`. Tests override `weatherRepositoryProvider` (never `forecastProvider` itself).

### Outfit recommender
`recommendOutfit(current, today, prefs)` in `features/outfit/controller/outfit_provider.dart` is a pure top-level function; the Riverpod provider is a thin shim. Selection is a 3-layer overlay: `_baseByBracket ← _styleOverlays[style] ← _genderOverlays[gender]` (gender wins over style). `adjustFeelsBySensitivity` shifts the bracket lookup by ±4°C based on `prefs.thermalSensitivity` (0=怕冷 → cooler bracket → warmer outfit). Rainy-day shoes override the catalog. `tip` and `accessory` use raw `feels` (sensitivity-independent) — don't change this; the rationale is documented inline.

### Units
All weather data is stored internally in °C and km/h. Conversion to user-preferred units happens **only at the display boundary** via `core/units/units.dart` helpers (`formatTemperature`, `formatTemperatureShort`, `formatWindSpeed`). Do not store converted values.

### Routing
`go_router` with `StatefulShellRoute.indexedStack` (4 branches: weather/forecast/wardrobe/settings). Riverpod → GoRouter is bridged via a `ValueNotifier<GeoLocation?>` set as `refreshListenable`. The redirect rule:
- no location & not at `/onboarding` & not at `/city-search` → `/onboarding`
- has location & at `/onboarding` → `/weather`

`/city-search` is intentionally whitelisted so onboarding can push it before a location exists. Switch tabs with `navigationShell.goBranch(i)` from `AppShell`; from inside a tab, `context.go(Routes.forecast)` works because go_router resolves to the matching branch.

### Frosted app bar
`buildFrostedAppBar(context, title:)` is a custom `PreferredSizeWidget` shared by settings/wardrobe/forecast. It must add `MediaQuery.viewPaddingOf(context).top` to `preferredSize.height` and use `SafeArea(bottom: false)` internally — `Scaffold` does NOT auto-pad custom app bars (only Material's `AppBar`). Don't "simplify" this.

### Home-screen widget sync
`lib/core/widget/home_widget_sync.dart`. `bindHomeWidgetSync(ref)` is called from `_WeatherAppState.initState` and uses `ref.listenManual` to push to native (`HomeWidget.saveWidgetData` + `HomeWidget.updateWidget`) whenever forecast/outfit/prefs/location change. Android uses `WeatherWidgetProvider.kt` (extends `HomeWidgetProvider` from the package) and reads from SharedPreferences. iOS scaffold lives at `ios/WeatherWidget/` but needs an Xcode-side Widget Extension target + App Group `group.com.softandapp.weather_app` to actually compile (manual one-time step documented in the Swift file's header comment).

## Conventions

- Comments are sparse and explain **why**, not what — preserve the existing tone (tradeoffs, "this looks weird because…", non-obvious invariants). Don't add `// gets the location` style comments.
- Chinese is used for user-facing strings, code comments, and PR/commit messages. English for identifiers.
- Test naming and structure follow the existing files; widget tests use `ProviderScope` with the same two overrides (`sharedPreferencesProvider`, `weatherRepositoryProvider`). When a result and the search input share the same text (e.g. "上海"), use `find.widgetWithText(InkWell, ...)` or assert on the unique subtitle to avoid ambiguous matches.

## Design system

`DESIGN.md` is the source of truth for tokens (Vibrant Morning palette, Plus Jakarta Sans, 20px+ corner radii, tonal-layer elevation). `core/theme/app_colors.dart` and `app_typography.dart` mirror it — do not introduce ad-hoc colors or text styles in feature code; extend the token set instead.
