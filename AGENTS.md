# AGENTS.md

Guidance for any contributor or AI agent working in **`photo_manager`**
(`flutter_photo_manager`), including forks.

> **Portability rule for this file:** it is read by many people, across forks,
> using different tools and models. Keep it self‑contained and free of
> machine‑, user‑, or model‑specific assumptions (no hardcoded home paths, no
> "my setup" commands). Prefer environment variables and documented defaults so
> the guidance holds on any host.

## What this project is — and why caution matters

`photo_manager` is a Flutter plugin exposing album/asset (gallery) management
APIs across **Android, iOS, macOS, and OpenHarmony**. It sits very low in the
Flutter ecosystem: many widely‑used packages (image pickers, gallery viewers,
editors) depend on it transitively. A regression or a tightened constraint here
ripples out to a large number of downstream apps.

Treat every change as touching public, widely‑consumed API. The three standing
constraints, in priority order:

1. **Do not move the version floor.** Keep `environment: sdk: ">=2.13.0 <4.0.0"`
   and `flutter: ">=2.2.0"` in `pubspec.yaml` unchanged unless the maintainer
   explicitly asks. Do not use language/SDK features that raise the effective
   floor (e.g. `extension type` needs Dart 3.3, above the current floor).
2. **Preserve compatibility.** Prefer additive changes. Never remove or change
   the signature/semantics of an existing public API; deprecate instead.
3. **Keep native features semantically accurate and cross‑platform consistent.**
   A method must mean the same thing on every platform, return the same shape,
   and degrade predictably where a platform can't support it.

## Repository layout

| Path | What it is |
|------|-----------|
| `lib/photo_manager.dart` | Public barrel (`export`s). Add new public types here. |
| `lib/src/managers/` | `PhotoManager` (static entry), caching, notify managers. |
| `lib/src/types/` | `AssetEntity`, `AssetPathEntity` (`entity.dart`), `DarwinAsset`/`DarwinAssetPath` (`darwin.dart`), enums/types. |
| `lib/src/internal/` | `plugin.dart` (the channel layer), `editor.dart`, `constants.dart`, `enums.dart`. |
| `lib/src/filter/` | Classical + custom filter APIs. |
| `darwin/` | **Shared** iOS/macOS Objective‑C source. `ios/` and `macos/` are symlinks to `darwin/`. |
| `android/src/main/kotlin/com/fluttercandies/photo_manager/` | Android (Kotlin). Unit tests under `android/src/test/`. |
| `ohos/` | OpenHarmony (ArkTS `.ets`). |
| `example/` | Reference app; also where you add manual verification pages. |
| `test/` | Dart unit tests (`flutter test`). |

Darwin packaging is dual: `darwin/photo_manager.podspec` (CocoaPods) **and**
`darwin/photo_manager/Package.swift` (SPM). Keep both consistent when you add
source files, resources, or privacy manifest entries.

## Platform architecture — how to add platform-specific behavior

There is **one** `MethodChannel` (`com.fluttercandies/photo_manager`,
`PMConstants.channelPrefix`). `PMMethodChannel` auto‑injects a `cancelToken`.

Dart side: `PhotoManagerPlugin with BasePlugin, IosPlugin, AndroidPlugin,
OhosPlugin`. **Platform‑specific channel methods live in the matching mixin**
(`IosPlugin`, `AndroidPlugin`, `OhosPlugin`), each guarded with
`assert(Platform.isX)` (or a soft runtime guard returning an empty/neutral value
on unsupported platforms). They are reachable publicly via `PhotoManager.plugin.<method>`.

**Do not bloat `AssetEntity` / `AssetPathEntity` / `PhotoManager` with
platform‑specific members.** The codebase segregates platform APIs behind
namespaces; follow the established pattern that fits:

- **Mutations** → `PhotoManager.editor.darwin` / `.android` / `.ohos`
  (`Editor` in `editor.dart`), each guarded by a platform check that throws `OSError`.
- **Entity‑scoped reads** → `asset.darwin` / `path.darwin`, returning the
  lightweight `DarwinAsset` / `DarwinAssetPath` wrappers in `types/darwin.dart`.
  The getter performs the platform guard; the wrapper only forwards to `plugin`.
- **Library‑level / batch calls** → expose through `PhotoManager.plugin.<method>`
  (e.g. `getCloudIdentifiers`) rather than a bespoke static on `PhotoManager`.
- **Typed extra data** → nested types like `AlbumType.darwin` / `.ohos`.

When you add a channel method, wire all four sides: `PMConstants` string,
Dart mixin method, native handler, and (if user‑facing) the namespaced accessor.
Native dispatch: `PMPlugin.m` (`handleMethodResultHandler:`) for Darwin — mirror
an existing `else if` branch and reuse existing manager routines; Kotlin
`PhotoManagerPlugin.kt` for Android; `PhotoManagerPlugin.ets` for OHOS.

## Cross-platform semantics (non-negotiable)

- Decide the **contract first**: return type, units, null/empty behavior, and
  what happens on each unsupported platform — *then* implement per platform.
- Document per‑platform behavior in dartdoc using the existing bullet style:
  ```
  ///  * Android: ...
  ///  * iOS/macOS: ...
  ///  * OpenHarmony: ...
  ```
- Degrade predictably on unsupported platforms (empty map / `null` / `false` /
  empty list) instead of throwing — the deliberate exception is the `.darwin`
  accessor guard, which throws `OSError` by design.
- Use `@available(iOS x, macOS y, *)` around newer PhotoKit APIs and provide a
  fallback that still compiles and behaves sanely on the version floor. Prefer
  resource/behaviour probing over referencing symbols that may be absent on
  older SDKs.
- Match units and rounding to what the system UI shows (e.g. durations were
  aligned to system‑album display); don't silently truncate.

## Code style & lint

Config: `analysis_options.yaml` (`flutter_lints` + strict overrides). `flutter
analyze` must be **clean** (no errors *or* warnings) before any commit. Key points:

- Formatter: **80‑column**, `trailing_commas: preserve`. Run `dart format .`.
- `require_trailing_commas` is enforced — multiline argument lists need a
  trailing comma (a frequent analyze failure if you hand‑wrap).
- `prefer_single_quotes`, `always_declare_return_types` (**error**),
  `directives_ordering`, `prefer_const_*`, `prefer_final_*`,
  `sort_constructors_first`, `avoid_void_async` (**error**).
- `avoid_print` is on — use `debugPrint` in the example app, never `print`.
- `deprecated_member_use_from_same_package: ignore` — deprecating public API and
  still referencing it internally is expected; keep the `// ignore:` pattern used
  around the existing `darwinType`/`darwinSubtype` shims.
- Match the surrounding file's idiom (comment density, naming, ordering).

## Development principles (production-grade only)

- **No placeholders in delivered code.** No mock data, no `TODO`/`FIXME` left in
  a merged change, no "temporary" implementations. If you must checkpoint with a
  stub for review, say so explicitly and keep it out of the final commit.
- Fix root causes, not symptoms. Before coding, weigh 2–3 approaches and pick the
  smallest, most consistent one; then converge.
- **Minimal diff.** Only touch what the task needs. No opportunistic refactors,
  renames, or file moves. Delete only what this change genuinely obsoletes.
- Handle edge cases; surface errors explicitly — never swallow them silently.
- **Verify third‑party APIs against source, don't guess.** Read the package
  source in your pub cache — use `$PUB_CACHE` when it is set, otherwise the
  platform default (`~/.pub-cache` on macOS/Linux, `%LOCALAPPDATA%\Pub\Cache` on
  Windows) — under `<pub-cache>/hosted/pub.dev/<pkg>-<ver>/` (lib/example/test)
  rather than recalling an API. When analyze says a member is missing, go back to
  the source.
- Run independent reads/verifications in parallel; serialize only real dependencies.
- Be precise about numbers, dates, paths, and references; distinguish fact from
  inference. Keep CHANGELOG/docs matching reality, not optimistic intent.

## Testing & verification

- **Dart:** `flutter test` (unit tests in `test/`). `flutter analyze` and
  `dart format --set-exit-if-changed .` must pass.
- **Native quick check (no full build):** for reasonably self‑contained Darwin
  files, `clang -fsyntax-only -fobjc-arc -isysroot "$(xcrun --sdk macosx
  --show-sdk-path)" -fmodules <file>.m` catches syntax/type errors against the
  real `Photos` SDK. For a brand‑new PhotoKit API, isolate it in a tiny probe
  `.m` (`@import Photos;`) and syntax‑check that first.
- **Full native build:** `cd example && flutter build macos --debug` (or `ios`).
  This compiles the plugin end‑to‑end. It needs a working CocoaPods toolchain; if
  the host manages Ruby through a version manager (rbenv/rvm/asdf/chruby/system),
  activate it the way that host is configured rather than assuming a specific one.
  The Android side: `flutter build apk` / Kotlin unit tests under `android/src/test`.
- **Manual feature checks:** add a page under `example/lib/page/developer/…` and
  gate platform‑specific entries with `if (Platform.isIOS || Platform.isMacOS)`
  (or the relevant platform) both at the entry point *and* inside the page.
- **CI** (must be green before merge): `Analyze`, `Build for
  {Android,iOS,macOS,Windows,Linux,Web}`, `Test {Android,Darwin} build`,
  `publishable`, `CodeQL`, `CodeFactor`. Workflows live in `.github/workflows/`
  (`runnable.yml`, `check-compatibility.yml`, `build-example-apk.yml`,
  `codeql.yml`, `publish.yml`).

## Git & PR conventions

- **Branch from `main`** (never commit directly to `main`). PRs target `main`.
- **Commit titles use gitmoji** + a concise imperative summary — the project's
  actual convention. Common mapping: `✨` feature, `🐛`/`fix:` bug, `📝` docs,
  `⚡️` perf, `♻️` refactor, `🔧` config/tooling, `⬆️` bump deps, `🔥` remove,
  `🔖` release. Commit messages in **English**. (Absorb Conventional‑Commits
  discipline — clear type + scope + body — but express it in the gitmoji style
  this repo uses, not `feat(scope):` prefixes.)
- PR body follows the maintainer style: `## Summary` + tight bullets, and a
  `supersedes/implements #NNNN` line when relevant. Keep it short.
- Squash‑merge; the squash subject carries the `(#PR)` suffix.
- If an AI agent authored the change, add a `Co-Authored-By:` trailer that
  identifies it (e.g. `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`);
  forks using other assistants substitute their own identity.
- **Stage explicitly; never `git add .`.** Do not commit build artifacts or
  regenerated files (`example/**/build/`, `Pods/`, `**/Runner.xcodeproj/project.pbxproj`
  churn from a local build, `xcuserdata`). Revert incidental regen before committing.
- Update `CHANGELOG.md` under the `## Unreleased` section for any user‑facing
  change; when both READMEs document a feature, update `README.md` **and**
  `README-ZH.md`.
- Committing/pushing/merging are outward‑facing: do them only when the maintainer
  asks. Merges may need admin override if branch protection requires a review the
  author can't self‑supply — confirm intent before bypassing.

## Compatibility & deferred migrations

- Additive first. To retire public API, mark it `@Deprecated('Use X instead. '
  'This feature was deprecated after vX.Y.Z')` and keep it working; don't delete.
- Some public wrappers and shims are intentionally shaped for a later,
  **source‑compatible** swap (for example, keeping call sites stable so an
  implementation can change underneath without breaking callers). These deferred
  migrations are annotated in code comments at the relevant declarations — read
  and honor those notes, and don't perform such a migration early or without the
  version‑floor change it depends on.
