/// Result of the app-launch session check.
///
/// This is a placeholder model — once Firebase Auth is wired in, the real
/// check (valid session / unverified email / no session) will populate this
/// same enum, so `SplashViewModel` and `SplashScreen` don't need to change.
enum AuthStatus {
  checking,
  loggedIn,
  emailUnverified,
  loggedOut,
}
