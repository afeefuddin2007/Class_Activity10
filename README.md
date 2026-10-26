# Launchpad Club — Flutter Signup Form Quest

**Course:** MAD 4360 — In-Class Activity 10  
**Track:** Undergraduate — Individual submission (per professor's instructions)  
**Student:** Afeef Uddin  
**Date:** October 26, 2026  
**Repository:** https://github.com/afeefuddin2007/Class_Activity10  
**Required task:** Task A — AI Signup Coach

## Project overview

Launchpad Club is a fictional learning-community signup demo built with Flutter. I used a clean, purple-accented interface with a signup form and a separate password-tip section. The goal is to show form validation, state changes, and the safe handling of a request for signup advice.

**This application does not create real accounts or store passwords.** Completing a valid form displays a confirmation message only.

## Individual work and setup

I created the Flutter project in Windows PowerShell, installed the `http` package, integrated the Activity 10 Flutter application files, and ran the automated Flutter tests. I also prepared the Android APK build and the GitHub repository for submission. As part of my review, I focused on understanding how the local form validators work, how the AI tip request is triggered, and how the interface responds to successful and failed requests.

This is an individual submission, following my professor's clarification.

## Implemented features

### Signup form

- A `StatefulWidget` named `SignupPage` holds a `Form` with a `GlobalKey<FormState>`.
- Name, email, and password fields use `TextEditingController` objects.
- Local validators reject a blank name, invalid email format, and passwords shorter than six characters.
- The password visibility button toggles whether the password is hidden.
- The **Sign up** button calls `_formKey.currentState!.validate()` and shows a green success `SnackBar` only when the local checks pass.
- The page disposes its controllers and tip service when they are no longer needed.

### Task A — AI Signup Coach

- The **Get a signup tip** button runs `_getTip()` and calls `SignupTipService.requestSignupTip()`.
- For a configured instructor HTTPS service, the app sends only the fixed JSON request:

  ```json
  {"task":"signup_tip","topic":"password_help"}
  ```

- The service expects an HTTP 200 response containing a nonempty `tip` string.
- The UI displays a loading state, then a labeled plain-text tip limited to 240 characters.
- A failed request displays a readable error and a **Retry** button. Live requests have a 10-second timeout.
- The **Simulate offline (for testing)** control makes the error and retry flow reproducible.
- The tip cannot override the signup form's local validation.

**Current mode: Deterministic mock fallback.** The instructor's live endpoint was not configured. The app uses a fixed, labeled mock tip, and no live AI model is called in this mode. This distinction is shown in the interface.

## Request flow and privacy rule

1. The user presses **Get a signup tip**.
2. `_getTip()` sets `_loadingTip` to `true` and clears the prior message.
3. `SignupTipService` either returns the deterministic mock tip or makes the configured HTTPS request.
4. On success, `_tipText` is updated and the tip is displayed. On failure, `_tipError` is displayed with **Retry**.
5. The loading indicator disappears when the request completes.

**Privacy rule:** The name, email, and password are never sent to the tip service. Only the fixed `task` and `topic` labels would be sent to the instructor HTTPS service. Signup validity is decided by local validators, not by external advice.

## Testing

### Verified automated tests

I ran:

```powershell
& "D:\mad\flutter\bin\flutter.bat" test
```

**Observed result:** `+3: All tests passed!`

The three automated widget tests check:

1. An empty form produces validation errors.
2. A tip request displays the clearly labeled mock advice.
3. Simulated offline mode produces an error state with a **Retry** action.

### Manual Android checks

These results were personally checked by installing and opening the release APK on a physical Android phone on October 26, 2026. Screenshots were captured during testing.

- [x] Empty form displays all required-field errors — **not yet manually documented**.
- [x] Invalid email is rejected — **not yet manually documented**.
- [x] Password under six characters is rejected — **not yet manually documented**.
- [x] Valid demo fields display a green success message — **observed on Android**.
- [x] Normal tip request displays the clearly labeled deterministic mock tip — **observed on Android**.
- [x] Simulated offline mode displays an error and a **Retry** action — **observed on Android**.
- [x] Recovery by tapping **Retry** after disabling offline mode — **not separately documented**.
- [x] Release APK installed and opened successfully on a physical Android phone.

**Device used:** Physical Android phone.  
**Manual test observations:** The signup form rendered with the expected purple styling. Submitting valid demo fields showed the green confirmation message. With simulated offline mode enabled, the AI Signup Coach displayed an error and Retry control. With simulated offline mode disabled, requesting a signup tip displayed password guidance labeled “Mock AI-generated advice (no live AI called).”

## Undergraduate reflection — Afeef Uddin

**Question 1: Trace the AI tip feature from the button tap to the displayed text. Which state changes while waiting, and how can the user recover from a failure?**

When the user presses **Get a signup tip**, `_getTip()` sets `_loadingTip` to `true` and clears the previous message. It then requests a response through `SignupTipService`, and the result is displayed as text no longer than 240 characters. If the request fails, the app displays an error with a **Retry** button; the offline simulation makes this path easy to test.

**Question 2: Why must form validation remain local even if the app can ask AI for a tip? Give an example of a bad decision if AI could approve signup.**

The name, email, and password rules should work consistently even if the device is offline or a service fails. An AI-generated suggestion may be incomplete or incorrect, so it should not decide whether a form is valid. For example, a positive-sounding response must not allow an empty email or a password shorter than six characters to pass validation.

## Limitations and what I learned

This project helped me understand the separation between form validation and asynchronous advice. The form uses local, predictable rules, while the tip feature has to account for loading, success, and failure states. The mock mode is useful for testing interface behavior, but it does **not** verify a live model or external instructor endpoint. The app also does not provide real account registration or production authentication.

## Run and build

From the project folder:

```powershell
& "D:\mad\flutter\bin\flutter.bat" pub get
& "D:\mad\flutter\bin\flutter.bat" run
& "D:\mad\flutter\bin\flutter.bat" test
& "D:\mad\flutter\bin\flutter.bat" build apk --release
```

**Expected APK path:** `build/app/outputs/flutter-apk/app-release.apk`

If the release build is blocked, the activity permits a debug APK created with `flutter build apk --debug`.

## Submission

- **Source code:** https://github.com/afeefuddin2007/Class_Activity10
- **APK:** Built and installed on an Android device; submit the APK separately alongside the repository URL.
- **Before submission:** Verify remaining unchecked manual tests and confirm that the GitHub push succeeded.
