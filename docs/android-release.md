Pending: migrate off AGP 8.x before it's forced.

Current state (as of build 1.0.0+10, 2026-10-31): Gradle 8.14.6, AGP (`com.android.application`) 8.11.1, Kotlin (`org.jetbrains.kotlin.android`) 2.2.20 - the exact minimums Flutter 3.47.2 currently requires. Builds clean with no bypass flags.

Flutter's build output already warns these will "soon" stop being supported, pushing toward Gradle 9.1.0+, AGP 9.0.1+, Kotlin 2.3.20+. Do not casually bump to those - it's a real migration, not a version bump:

- AGP 9 reads only its new DSL by default. There's an opt-out (`android.newDsl=false` in gradle.properties), but Google's own release notes say that opt-out is removed in AGP 10.0 (mid-2026) - it buys time, it doesn't avoid the work.
- `id("kotlin-android")` (used in `android/app/build.gradle.kts`) is not compatible with the new DSL. AGP 9 wants it removed in favor of AGP's own built-in Kotlin support, or opted out via `android.builtInKotlin=false` (same mid-2026 expiry as above).
- AGP 9.0 requires JDK 17 minimum. Whatever JDK this Mac's Android toolchain currently uses for the AGP 8.11 build above is NOT the one on $PATH (`java -version` in a plain shell finds nothing) - find and confirm it before assuming JDK 17 is already satisfied.
- `android.sdk.defaultTargetSdkToCompileSdkIfUnset` defaults to true under AGP 9 - set `targetSdk` explicitly in `app/build.gradle.kts` rather than relying on the old default-to-minSdk behavior.
- R8's `strictFullModeForKeepRules` changes what `-keep class A` implies (no longer the default constructor) - matters if any bundled plugin (Firebase, Google Sign-In, flutter_secure_storage) relies on reflection-constructed classes. No custom `proguard-rules.pro` exists in this project as of this writing, so this is about plugins' own bundled consumer-proguard rules, not anything here - but it's exactly the kind of thing that compiles fine and breaks silently at runtime.

Why this is parked, not done: there's no physical Android device for this project (see the iOS/Android parity note) - real verification goes through a separate remote Linux/emulator setup. A Gradle major-version jump plus a Kotlin-plugin swap is the kind of change that can pass `flutter build apk --release` and still break Google Sign-In or Firebase push at runtime through the reflection/keep-rule changes above. Don't attempt this without a working path to verify on a real Android build afterward, and don't rush it just because a deadline exists - AGP 10 isn't due until mid-2026.

When picking this up: do the full migration (remove `kotlin-android`, set `targetSdk` explicitly, bump Gradle/AGP for real), not just the two opt-out flags - those are the same temporary state we're already avoiding today.
