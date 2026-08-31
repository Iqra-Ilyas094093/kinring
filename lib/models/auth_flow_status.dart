/// UI-facing state for an in-progress auth action (sign in, sign up, etc).
///
/// This is distinct from "is a user logged in" — that comes straight from
/// Firebase's `User?` via `authStateChanges`. This enum only tracks
/// whether the *current screen's* action is loading/errored, so screens
/// can show a spinner or an error message.
enum AuthFlowStatus { idle, loading, success, error }
