Build the 13115 Task Tracker iOS app on the Mac and get it to TestFlight.

Repo: github.com/genfire209/13115-task-tracker. Build from `main`; it has the newest app: bottom tabs, Meets, match screens, sign-in tokens, and names instead of emails for members.

App facts:
- Bundle ID com.robotics13115.taskTracker, team H7UYUF29YB, automatic signing.
- Version is in pubspec.yaml (currently 1.0.0+8).
- 7 earlier builds went to external TestFlight testers, uploaded from this Mac with Xcode and Transporter.
- The new build number must be higher than the last one in App Store Connect. Check there; if the last build was 8, use 1.0.0+9.
- ios/Runner/Info.plist already declares ITSAppUsesNonExemptEncryption = false (the app only uses standard HTTPS), so uploads skip the encryption question.
- Commit as me only. Never add a Co-Authored-By or Claude line to commits.

Steps:
1. `git checkout main && git pull`, and make sure `git status` is clean.
2. `flutter --version`, then `flutter pub get` and `flutter analyze`.
3. Run `flutter test`. test/match_detail_test.dart and test/meets_test.dart read fixtures from test/fixtures/.
4. Bump the build number in pubspec.yaml, commit it on main and push.
5. `cd ios && pod install && cd ..`, then `flutter build ipa --release`.
6. Upload build/ios/ipa/*.ipa with the Transporter app, the same way as before. Or use `xcrun altool --upload-app` if an App Store Connect API key is set up.
7. In App Store Connect → TestFlight, add the build to the external testers group and submit for Beta App Review.

Server: github.com/genfire209/13115-task-tracker-api deploys to Azure on every push to its main. It still serves old app builds (ALLOW_LEGACY_CLIENTS=true in Azure); turn that off once everyone is on this build, because old builds skip the sign-in check.
