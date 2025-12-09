# Mobile App CI/CD Pipeline Setup

**Platform:** Flutter (iOS + Android)  
**Target:** Production-ready CI/CD matching Phase 1 web standards  
**Duration:** Weeks -2 to 0 (before Epic 1 development)  

---

## Overview: Mobile CI/CD Parallel to Web Pipeline

Your Phase 1 CI/CD pipeline set the gold standard for code quality. The mobile CI/CD will mirror that rigor:

```
Web Pipeline (Phase 1)          Mobile Pipeline (Phase 0)
├─ RUFF Linting                 ├─ Dart Linting (flutter analyze)
├─ pytest (unit tests)          ├─ Dart Unit Tests (flutter test)
├─ Jest (frontend tests)        ├─ Widget Tests (Flutter widgets)
├─ Integration Tests            ├─ Integration Tests (flutter drive)
├─ Security Scan (Bandit)       ├─ Security Scan (Dart security)
├─ CodeQL Analysis              ├─ CodeQL for Dart
├─ SonarQube                    ├─ SonarQube for Dart
├─ Docker Build + Push          ├─ Flutter Build (AAB + APK)
└─ Deploy to Codespace/ACR      └─ Deploy to App Store + Play Store
```

---

## Epic 0: Mobile CI/CD Setup Pipeline

### Goal
Establish production-ready CI/CD for Flutter app before development starts.

### What Gets Built

**1. GitHub Actions Workflows**
```
.github/workflows/
├─ mobile-ci.yml               # Runs on every commit
├─ mobile-build.yml            # Build APK/AAB/IPA
├─ mobile-deploy.yml           # Deploy to app stores
└─ mobile-manual-deploy.yml    # Manual release trigger
```

**2. Code Quality Tools**
```
Analysis:
├─ flutter analyze             # Linting + static analysis
├─ dart fix                    # Auto-fix issues
├─ dart format                 # Code formatting
└─ custom_lint                 # Team-specific rules

Testing:
├─ Unit tests (flutter test)
├─ Widget tests (Flutter UI testing)
├─ Integration tests (flutter drive)
└─ Coverage reporting (>80% target)

Security:
├─ Dart analyzer security checks
├─ Pub dependencies vulnerability scan
├─ OWASP mobile security checks
└─ Code signing verification
```

**3. Build Artifacts**
```
Outputs:
├─ iOS: IPA file (TestFlight upload)
├─ Android: AAB (Play Store upload)
├─ Coverage reports (HTML)
├─ Lint reports
└─ Security scan results
```

---

## CI/CD Workflow Details

### **Workflow 1: mobile-ci.yml** (Runs on every commit)

```yaml
name: Mobile CI

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'mobile/**'
      - '.github/workflows/mobile-ci.yml'
  pull_request:
    branches: [ main, develop ]
    paths:
      - 'mobile/**'

jobs:
  code-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'
      
      - name: Flutter Analyze
        run: |
          cd mobile
          flutter analyze
      
      - name: Format Check
        run: |
          cd mobile
          dart format --set-exit-if-changed .
      
      - name: Lint with custom_lint
        run: |
          cd mobile
          dart pub run custom_lint

  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'
      
      - name: Get Dependencies
        run: |
          cd mobile
          flutter pub get
      
      - name: Run Unit Tests
        run: |
          cd mobile
          flutter test \
            --coverage \
            --verbose
      
      - name: Upload Coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: mobile/coverage/lcov.info
          flags: flutter-unit-tests
          minimum: 80

  widget-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'
      
      - name: Get Dependencies
        run: |
          cd mobile
          flutter pub get
      
      - name: Run Widget Tests
        run: |
          cd mobile
          flutter test \
            --tags widget \
            --coverage
      
      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          files: mobile/coverage/lcov.info
          flags: flutter-widget-tests

  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'
      
      - name: Scan Dependencies
        run: |
          cd mobile
          flutter pub audit
      
      - name: Check for Secrets
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./mobile
          base: ${{ github.event.repository.default_branch }}
      
      - name: OWASP Dependency Check
        run: |
          cd mobile
          dart pub cache clean
          dart pub get

  sonarqube:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'
      
      - name: Get Dependencies
        run: |
          cd mobile
          flutter pub get
      
      - name: Run Tests with Coverage
        run: |
          cd mobile
          flutter test --coverage
      
      - name: SonarQube Scan
        uses: SonarSource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        with:
          args: |
            -Dsonar.projectKey=crop-ai-mobile
            -Dsonar.coverage.exclusions=**/*.g.dart,**/*.freezed.dart
            -Dsonar.sources=mobile/lib
            -Dsonar.tests=mobile/test
            -Dsonar.dart.coverage.reportPath=mobile/coverage/lcov.info
```

### **Workflow 2: mobile-build.yml** (Build for all platforms)

```yaml
name: Mobile Build

on:
  push:
    branches: [ main ]
    paths:
      - 'mobile/**'
  workflow_dispatch:

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'
      
      - name: Get Dependencies
        run: |
          cd mobile
          flutter pub get
      
      - name: Build APK
        run: |
          cd mobile
          flutter build apk --release
      
      - name: Build AAB
        run: |
          cd mobile
          flutter build appbundle --release
      
      - name: Upload APK to Artifacts
        uses: actions/upload-artifact@v3
        with:
          name: mobile-android-apk
          path: mobile/build/app/outputs/flutter-apk/app-release.apk
      
      - name: Upload AAB to Artifacts
        uses: actions/upload-artifact@v3
        with:
          name: mobile-android-aab
          path: mobile/build/app/outputs/bundle/release/app-release.aab

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'
      
      - name: Get Dependencies
        run: |
          cd mobile
          flutter pub get
      
      - name: Build iOS
        run: |
          cd mobile
          flutter build ios --release --no-codesign
      
      - name: Build iOS IPA
        run: |
          cd mobile
          flutter build ipa --release \
            --export-options-template=ios/Runner/ExportOptions.plist
      
      - name: Upload IPA to Artifacts
        uses: actions/upload-artifact@v3
        with:
          name: mobile-ios-ipa
          path: mobile/build/ios/ipa/
```

### **Workflow 3: mobile-deploy.yml** (Deploy to app stores)

```yaml
name: Mobile Deploy

on:
  push:
    branches: [ main ]
    paths:
      - 'mobile/**'
  workflow_dispatch:

jobs:
  deploy-android:
    runs-on: ubuntu-latest
    needs: build-android
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'
      
      - name: Download AAB
        uses: actions/download-artifact@v3
        with:
          name: mobile-android-aab
      
      - name: Deploy to Play Store (Beta)
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.ANDROID_SERVICE_ACCOUNT_JSON }}
          packageName: 'com.crop_ai.mobile'
          releaseFiles: 'app-release.aab'
          track: 'beta'
          status: 'completed'

  deploy-ios:
    runs-on: macos-latest
    needs: build-ios
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'
      
      - name: Download IPA
        uses: actions/download-artifact@v3
        with:
          name: mobile-ios-ipa
      
      - name: Deploy to TestFlight
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: 'mobile/build/ios/ipa/cropai.ipa'
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_API_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}
```

### **Workflow 4: mobile-manual-deploy.yml** (Manual release)

```yaml
name: Mobile Manual Deploy

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        type: choice
        options:
          - testflight
          - play-store-beta
          - play-store-production
          - appstore-production
      version:
        description: 'Release version (e.g., 1.0.0)'
        required: true
        type: string

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'
      
      - name: Update Version
        run: |
          cd mobile
          sed -i "s/^version: .*/version: ${{ github.event.inputs.version }}/" pubspec.yaml
      
      - name: Get Dependencies
        run: |
          cd mobile
          flutter pub get
      
      - name: Build for Deployment
        run: |
          cd mobile
          flutter build appbundle --release
          flutter build ipa --release
      
      - name: Deploy to App Store
        if: env.environment == 'appstore-production'
        run: echo "Deploy to App Store..."
```

---

## Code Quality Standards

### **1. Dart Linting Rules** (`analysis_options.yaml`)

```yaml
# Mobile analysis_options.yaml
analyzer:
  exclude:
    - 'build/**'
    - 'lib/generated/**'
    - 'lib/**/*.g.dart'
    - 'lib/**/*.freezed.dart'
  
  errors:
    missing_required_param: error
    missing_return: error
    todo: ignore
    dead_code: warning
  
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false

linter:
  rules:
    # Error Rules
    - avoid_empty_else
    - avoid_print
    - avoid_relative_import_paths
    - avoid_returning_null_for_future
    - avoid_slow_async_io
    - cancel_subscriptions
    - close_sinks
    - comment_references
    - control_flow_in_finally
    - empty_statements
    - hash_and_equals
    - invariant_booleans
    - iterable_contains_unrelated_type
    - list_remove_unrelated_type
    - no_adjacent_strings_in_list
    - no_duplicate_case_values
    - prefer_void_to_null
    - throw_in_finally
    - unnecessary_statements
    - unrelated_type_equality_checks
    
    # Style Rules
    - always_declare_return_types
    - always_put_control_body_on_new_line
    - always_put_required_named_parameters_first
    - annotate_overrides
    - avoid_bool_literals_in_conditional_expressions
    - avoid_catches_without_on_clauses
    - avoid_catching_errors
    - avoid_double_and_int_checks
    - avoid_field_initializers_in_const_classes
    - avoid_function_literals_in_foreach_calls
    - avoid_null_checks_in_equality_operators
    - avoid_positional_boolean_parameters
    - avoid_private_typedef_functions
    - avoid_redundant_argument_values
    - avoid_returning_null
    - avoid_returning_null_for_async_futures
    - avoid_returning_null_for_void
    - avoid_returning_this
    - avoid_setters_without_getters
    - avoid_shadowing_type_parameters
    - avoid_single_cascade_in_expression_statements
    - avoid_types_as_parameter_names
    - avoid_types_on_attached_field_definitions
    - avoid_types_on_extension_declarations
    - avoid_types_on_function_declaration_return_types
    - avoid_unnecessary_containers
    - avoid_void_async
    - await_only_futures
    - camel_case_extensions
    - camel_case_types
    - cascade_invocations
    - cast_nullable_to_non_nullable
    - combinators_ordering
    - comment_references
    - constant_identifier_names
    - curly_braces_in_flow_control_structures
    - dangling_library_doc_comments
    - directives_ordering
    - empty_catches
    - empty_constructor_bodies
    - eol_only_unix_endings
    - file_names
    - implementation_imports
    - leading_newlines_in_multiline_strings
    - library_names
    - library_prefixes
    - library_private_types_in_public_api
    - null_closures
    - null_check_on_nullable_type_parameter
    - null_to_void
    - omit_local_variable_types
    - one_member_abstracts
    - only_throw_errors
    - overridden_fields
    - package_api_docs
    - package_names
    - package_prefixed_library_names
    - parameter_assignments
    - prefer_adjacent_string_concatenation
    - prefer_asserts_in_initializer_lists
    - prefer_asserts_with_message
    - prefer_collection_literals
    - prefer_conditional_assignment
    - prefer_const_constructors
    - prefer_const_constructors_in_immutables
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_constructors_over_static_methods
    - prefer_contains
    - prefer_equal_for_default_values
    - prefer_expression_function_bodies
    - prefer_final_fields
    - prefer_final_in_for_each
    - prefer_final_locals
    - prefer_for_elements_to_map_fromIterable
    - prefer_foreach
    - prefer_function_declarations_over_variables
    - prefer_generic_function_type_aliases
    - prefer_if_elements_to_conditional_expressions
    - prefer_if_null_to_conditional_expressions
    - prefer_if_on_single_line_is_else
    - prefer_initializing_formals
    - prefer_inlined_adds
    - prefer_int_literals
    - prefer_interpolation_to_compose_strings
    - prefer_int_literals
    - prefer_is_empty
    - prefer_is_not_empty
    - prefer_is_not_operator
    - prefer_is_operator
    - prefer_iterable_whereType
    - prefer_mixin
    - prefer_null_aware_operators
    - prefer_null_coalescing_operators
    - prefer_relative_imports
    - prefer_single_quotes
    - prefer_spread_collections
    - provide_deprecation_message
    - recursive_getters
    - sized_box_for_whitespace
    - sized_box_shrink_expand
    - slash_for_doc_comments
    - sort_child_properties_last
    - sort_constructors_first
    - sort_pub_dependencies
    - sort_unnamed_constructors_first
    - tighten_type_of_initializing_formals
    - type_annotate_public_apis
    - type_init_formals
    - unawaited_futures
    - unnecessary_await_in_return
    - unnecessary_brace_in_string_interps
    - unnecessary_const
    - unnecessary_constructor_name
    - unnecessary_getters_setters
    - unnecessary_lambdas
    - unnecessary_library_directive
    - unnecessary_new
    - unnecessary_null_aware_assignments
    - unnecessary_null_checks
    - unnecessary_null_in_if_null_operators
    - unnecessary_null_to_nullable_checks
    - unnecessary_nullable_for_final_variable_declarations
    - unnecessary_parenthesis
    - unnecessary_string_escapes
    - unnecessary_string_interpolations
    - unnecessary_to_list_in_spreads
    - unsafe_html
    - use_build_context_synchronously
    - use_full_hex_values_for_flutter_colors
    - use_function_type_syntax_for_parameters
    - use_getters_to_track_state
    - use_if_null_to_convert_nullability
    - use_is_even_rather_than_modulo
    - use_key_in_widget_constructors
    - use_late_for_private_fields_and_variables
    - use_named_constants
    - use_raw_strings
    - use_rethrow_when_possible
    - use_setters_to_change_properties
    - use_string_buffers
    - use_test_throws_matchers
    - use_to_enum_name
    - void_checks
```

### **2. Unit Test Standards**

```dart
// Example: test_coverage_requirements.md

Minimum Coverage: 80%

Test Categories:
├─ Models (100% coverage)
│  └─ All data structures, serialization
├─ Services (90% coverage)
│  └─ API calls, storage, sync logic
├─ Providers (85% coverage)
│  └─ State management
├─ Utilities (90% coverage)
│  └─ Helpers, formatters
└─ Widgets (60% coverage - UI hard to test)
   └─ Critical user flows

Test Structure:
├─ Arrange (setup test data)
├─ Act (perform action)
└─ Assert (verify result)

Mocking:
├─ Dio HTTP client
├─ Firebase services
├─ SQLite database
└─ Location services
```

### **3. Widget Test Standards**

```
Target: 60% coverage of critical screens

Priority Screens:
├─ FarmListScreen (high priority)
├─ PredictionScreen (high priority)
├─ ChaupalFeedScreen (medium priority)
└─ MarketplaceScreen (medium priority)

Test Cases per Screen:
├─ Initial load
├─ Data display
├─ User interactions
├─ Error states
├─ Offline mode
└─ Navigation flows
```

### **4. Integration Test Standards**

```
Target: Critical user journeys

Journeys:
├─ Epic 1: Login → View farms → Check weather
├─ Epic 2: Get AI prediction → Share result
├─ Epic 3: View feed → Create post → Like comment
└─ Epic 4: Browse marketplace → Request service → Chat
```

---

## Security Scanning

### **Mobile Security Checks**

```
1. Dependency Vulnerabilities
   └─ flutter pub audit
   └─ Pub dependency scanner (SonarQube)

2. Secrets Detection
   └─ trufflesecurity/trufflehog

3. Code Analysis
   └─ dartanalyzer security checks
   └─ Unsafe patterns detection
   └─ Permission analysis

4. Code Signing
   └─ iOS: Apple Developer certificate validation
   └─ Android: keystore verification

5. API Security
   └─ HTTPS enforcement
   └─ Certificate pinning validation
   └─ Auth token handling
```

---

## Build Artifacts & Versioning

### **Artifact Management**

```
Version Format: MAJOR.MINOR.PATCH+BUILD

Example: 1.0.0+100 (1.0.0 is semver, 100 is build number)

Artifact Storage:
├─ Android APK (for testing)
├─ Android AAB (for Play Store)
├─ iOS IPA (for TestFlight)
├─ Coverage reports (HTML)
├─ Lint reports (JSON)
└─ Security scan reports
```

### **Release Channels**

```
Development Flow:
develop branch
    ↓
    ├─ flutter-ci: Tests + Analysis ✓
    ├─ flutter-build: Build APK/IPA ✓
    └─ Manual testing (internal)
        ↓
main branch (merge after testing)
    ↓
    ├─ flutter-ci: Full suite ✓
    ├─ flutter-build: All artifacts ✓
    ├─ flutter-deploy: Beta channels ✓
    │  └─ TestFlight (iOS Beta)
    │  └─ Play Store Beta (Android)
    └─ Manual trigger for production
       └─ App Store (iOS)
       └─ Play Store Stable (Android)
```

---

## Secrets & Environment Variables

### **GitHub Secrets Required**

```
Flutter-specific:
├─ ANDROID_SERVICE_ACCOUNT_JSON     # Play Store API
├─ APPSTORE_ISSUER_ID               # App Store Connect
├─ APPSTORE_API_KEY_ID              # App Store Connect
├─ APPSTORE_API_PRIVATE_KEY         # App Store Connect
├─ ANDROID_KEYSTORE                 # APK signing (base64)
├─ ANDROID_KEYSTORE_PASSWORD        # APK signing
├─ ANDROID_KEY_ALIAS                # APK signing
└─ ANDROID_KEY_PASSWORD             # APK signing

Shared (from Phase 1):
├─ SONAR_TOKEN                      # SonarQube
├─ GITHUB_TOKEN                     # Already available
└─ Firebase secrets (from Firebase Console)
```

---

## Metrics & Monitoring

### **Key Metrics to Track**

```
Code Quality:
├─ Coverage (target: 80%)
├─ Lint issues (target: 0)
├─ Security vulnerabilities (target: 0)
└─ Build success rate (target: 100%)

Build Performance:
├─ Unit test time (target: <2min)
├─ Build time (APK, target: <5min)
├─ Build time (IPA, target: <10min)
└─ Total CI time (target: <15min)

Deployment:
├─ App store submission time
├─ Beta to production cycle (target: 1 week)
└─ Release success rate (target: 99%)
```

---

## Acceptance Criteria for Epic 0

- [ ] All 4 workflows created and passing
- [ ] Unit tests run: `flutter test --coverage`
- [ ] Coverage reports generate: >80% target
- [ ] Linting passes: `flutter analyze` returns 0 issues
- [ ] Formatting checked: `dart format --set-exit-if-changed .`
- [ ] Security scan runs: No high/critical issues
- [ ] SonarQube analysis passing
- [ ] Android APK builds: <5min
- [ ] iOS IPA builds: <10min (on macOS)
- [ ] Artifacts upload to GitHub (all formats)
- [ ] Manual deploy workflow works
- [ ] Documentation complete (all workflows documented)
- [ ] Team can trigger manual releases
- [ ] Secrets configured in GitHub
- [ ] All tools parity with Phase 1 web pipeline

---

## Team & Timeline

### Team:
- 1 DevOps Engineer (full-time, 1 week)
- 1 Backend Dev (part-time, setup Firebase)

### Timeline:
- **Days 1-2:** Setup workflows + Firebase
- **Days 3-4:** Configure testing + coverage
- **Days 5:** Security scanning + SonarQube
- **Day 6:** Documentation + team training
- **Day 7:** Validation + adjustments

**Total: 1 week before Epic 1 starts**

---

## Next Steps

1. Create `.github/workflows/mobile-ci.yml`
2. Create `.github/workflows/mobile-build.yml`
3. Create `.github/workflows/mobile-deploy.yml`
4. Create `.github/workflows/mobile-manual-deploy.yml`
5. Create `mobile/analysis_options.yaml`
6. Setup Firebase project + credentials
7. Add secrets to GitHub
8. Test all workflows with dummy commits
9. Document runbook for the team
10. Train team on release process

---

**This pipeline ensures mobile app quality = Phase 1 web app quality ✅**

