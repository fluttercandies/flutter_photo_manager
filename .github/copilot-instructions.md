# Copilot Instructions for flutter_photo_manager

## Project Overview

`photo_manager` is a Flutter plugin that provides assets abstraction management APIs for Android, iOS, macOS, and OpenHarmony platforms. It allows Flutter applications to access and manage photos, videos, and audio files without UI integration.

## Project Structure

```
flutter_photo_manager/
├── lib/                    # Dart/Flutter public API
├── android/                # Android (Kotlin) implementation
├── darwin/                 # iOS/macOS (Objective-C) shared implementation
├── ohos/                   # OpenHarmony implementation
├── example/                # Flutter example app
├── test/                   # Dart unit tests
└── .github/
    └── agents/            # Custom agents for specialized tasks
```

## Coding Standards

### Dart/Flutter Code

Follow the conventions defined in `analysis_options.yaml`:

- **Always declare return types** for functions and methods
- **Use single quotes** for strings (e.g., `'hello'` not `"hello"`)
- **Require trailing commas** in multi-line parameter lists and collections
- **Prefer const constructors** where possible
- **Use final** for fields, locals, and for-each variables where appropriate
- **Avoid print statements** - use proper logging instead
- **Always put control body on new line** for if/else/for/while statements
- Use camel case for types and non-constant identifiers
- Sort constructors first, unnamed constructors first
- Sort child properties last in widget trees

### Platform-Specific Code

#### Android (Kotlin)
- Located in `android/src/main/kotlin/com/fluttercandies/photo_manager/`
- Follow Kotlin coding conventions
- Use proper null safety (`?`, `!!`)
- Maintain compatibility with the JVM target version

#### iOS/macOS (Objective-C)
- Located in `darwin/photo_manager/Sources/photo_manager/`
- Use Objective-C with proper memory management
- Follow Apple's naming conventions
- Ensure thread safety for PHPhotoLibrary operations (always use main thread)
- Handle async operations properly to avoid memory access issues

#### OpenHarmony
- Located in `ohos/`
- Follow OpenHarmony platform conventions

## Development Workflow

### Making Changes

1. **Minimal Changes**: Make the smallest possible changes to address the issue
2. **Update CHANGELOG.md**: Always update the CHANGELOG.md file for code changes
   - Add entries under the "Unreleased" section
   - Categorize as: Features, Improvements, Fixes, Breaking Changes
3. **No TODOs**: Do not leave TODO comments; implement complete solutions
4. **Follow existing style**: Match the coding style of the surrounding code

### Testing and Validation

Run these commands to validate changes:

```bash
# Format Dart code
dart format . -o none --set-exit-if-changed

# Analyze Dart code
flutter analyze lib
flutter analyze example

# Run tests
flutter test

# Dry run documentation generation
dart doc --dry-run .
```

### Building Platform-Specific Code

```bash
# Android build
cd example && flutter build apk --release

# iOS build (macOS only)
cd example && flutter build ios --no-codesign

# macOS build (macOS only)
cd example && flutter build macos --debug
```

## Important Considerations

### Multi-Platform Plugin
- Changes may affect multiple platforms simultaneously
- Test platform-specific implementations when modifying core functionality
- Be aware of platform-specific APIs and limitations

### Version Compatibility
- Minimum Dart SDK: 2.13.0
- Minimum Flutter: 2.2.0
- Android: Handle different Android versions (Q/29+, 13/33+, 14/34+)
- iOS: Consider iOS-specific features (Live Photos, iCloud, limited access)

### Common Patterns

1. **Asset Management**: Core abstractions are `AssetEntity` and `AssetPathEntity`
2. **Permissions**: Handle platform-specific permission models
3. **Filtering**: Use `FilterOptionGroup` and `CustomFilter` for queries
4. **Caching**: Be aware of platform-specific caching mechanisms
5. **Async Operations**: Many operations are asynchronous; handle properly

### Documentation
- Keep README.md and README-ZH.md in sync for significant changes
- Update MIGRATION_GUIDE.md for breaking changes
- Maintain accurate code documentation for public APIs

## Related Resources

- Repository: https://github.com/fluttercandies/flutter_photo_manager
- Flutter Plugin Development: https://flutter.dev/docs/development/packages-and-plugins
- Existing custom agent: `.github/agents/pr-agent.agent.md`

## Best Practices

1. **Security**: Handle permissions and user privacy appropriately
2. **Performance**: Be mindful of memory usage when dealing with media files
3. **Error Handling**: Provide clear error messages and handle edge cases
4. **Backwards Compatibility**: Maintain compatibility unless explicitly breaking
5. **Thread Safety**: Especially important for iOS/macOS PHPhotoLibrary operations
