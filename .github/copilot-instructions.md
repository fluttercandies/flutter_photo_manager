# GitHub Copilot Instructions for flutter_photo_manager

## Repository Overview

This is a Flutter plugin that provides assets abstraction management APIs without UI integration. The plugin allows developers to get assets (image/video/audio) on Android, iOS, macOS, and OpenHarmony platforms.

## Core Principles

1. **Minimal Changes**: Make the smallest possible changes to achieve the goal. Avoid refactoring or modifying working code unless absolutely necessary.
2. **Cross-Platform Compatibility**: Ensure changes work across all supported platforms (Android, iOS, macOS, OpenHarmony).
3. **No Breaking Changes**: Maintain backward compatibility unless explicitly required for a major version update.
4. **Documentation**: Update CHANGELOG.md for any code changes that affect users.

## Technology Stack

- **Language**: Dart (>=2.13.0) and Flutter (>=2.2.0)
- **Platforms**: Android (Java/Kotlin), iOS/macOS (Swift/Objective-C), OpenHarmony
- **Package Type**: Flutter plugin with platform channels

## Code Style and Linting

### Dart/Flutter Guidelines

1. **Follow the existing analysis_options.yaml rules**:
   - Use single quotes for strings
   - Always declare return types
   - Prefer const constructors where possible
   - Use trailing commas for better formatting
   - Prefer final for variables that don't change

2. **Formatting**:
   - Run `dart format .` before committing
   - Code must pass `flutter analyze lib` and `flutter analyze example`

3. **Best Practices**:
   - Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
   - Follow Flutter community best practices
   - Maintain consistency with the existing codebase style
   - Use descriptive variable and method names
   - Keep functions small and focused

### Platform-Specific Code

#### Android
- Follow Google's Android development best practices
- Use Java 17 as the target version
- Maintain compatibility with the existing Gradle setup
- Test builds with `flutter build apk`

#### iOS/macOS
- Follow Apple's Swift and Objective-C guidelines
- Ensure code works on both iOS and macOS (macos symlinks to ios)
- Test builds with `flutter build ios --no-codesign` and `flutter build macos`

#### OpenHarmony
- Follow OpenHarmony platform guidelines
- Maintain consistency with Android/iOS implementations

## Testing Requirements

1. **Run existing tests**: `flutter test`
2. **Add tests for new functionality**: Place tests in the `test/` directory
3. **Test cross-platform**: Verify changes don't break platform-specific code
4. **CI must pass**: All checks in runnable.yml workflow must succeed

## Development Workflow

1. **Before Making Changes**:
   - Run `flutter pub get` to install dependencies
   - Run `flutter analyze lib` to check for existing issues
   - Run `flutter test` to ensure tests pass

2. **During Development**:
   - Make minimal, focused changes
   - Test frequently with `flutter analyze` and `flutter test`
   - Verify platform-specific code if touching native implementations

3. **Before Committing**:
   - Update CHANGELOG.md if changes affect users
   - Run `dart format .` to format code
   - Ensure all tests pass
   - Verify example app still works if applicable

## File Structure

- `lib/`: Dart plugin code
- `android/`: Android platform implementation
- `ios/`: iOS and macOS platform implementation (macOS symlinks to iOS)
- `ohos/`: OpenHarmony platform implementation
- `example/`: Example Flutter app demonstrating plugin usage
- `test/`: Unit and widget tests

## Common Patterns

1. **Platform Channels**: Use MethodChannel for communication between Dart and native code
2. **Async Operations**: Media operations are async, use Future and async/await
3. **Permissions**: Handle platform-specific permissions properly
4. **Error Handling**: Provide clear error messages and handle edge cases

## Documentation

- Update inline documentation for public APIs
- Follow dartdoc conventions
- Update README.md if adding new features or changing usage
- Update MIGRATION_GUIDE.md for breaking changes in major versions

## Dependencies

- Avoid adding new dependencies unless absolutely necessary
- If adding dependencies, ensure they:
  - Are well-maintained
  - Have compatible licenses
  - Work on all target platforms
  - Don't introduce security vulnerabilities

## Security Considerations

- Never commit sensitive data or credentials
- Validate input from platform channels
- Handle permissions requests properly
- Be cautious with file system operations
- Follow platform security guidelines

## DO NOT

- Do not remove or modify working code unless necessary
- Do not leave TODO comments in production code
- Do not introduce breaking changes without discussion
- Do not skip tests or CI checks
- Do not add unnecessary complexity
- Do not ignore lint warnings or errors
- Do not modify unrelated code while fixing issues

## Additional Resources

- [Flutter Plugin Development](https://docs.flutter.dev/development/packages-and-plugins/developing-packages)
- [Platform Channel Guide](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Repository README](../README.md)
- [Migration Guide](../MIGRATION_GUIDE.md)
