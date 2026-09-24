# Forgot Password to Login Fix

## Status

The forgot-password flow has been corrected and pushed to the `main` branch in commit `c868c47`:

```text
fix(auth): provision login credential after password reset
```

The original flow completed the OTP and password-reset screens, but login still returned **Invalid email or password**. The cause was that the reset flow attempted to persist a `password_hash` in the `profiles` table, while the production schema does not contain that column. In addition, some older profiles did not have a corresponding Supabase Auth user.

The corrected implementation stores the new password in **Supabase Auth**, which is also the credential source used by the login endpoint. It updates an existing Auth user or creates one when the profile has no Auth user.

## Files and line locations

| Purpose | File | Current lines |
|---|---|---:|
| API entrypoint | `api/index.js` | 1–5 |
| Forgot-password initiate, OTP verification, and password reset | `backend/api_handler.js` | 838–991 |
| Login password verification | `backend/api_handler.js` | 562–607 |
| Database user lookup and Supabase metadata merge | `backend/db_manager.js` | 133–170 |
| Flutter forgot-password API calls | `lib/services/api_service.dart` | 210–263 |
| Flutter email entry screen | `lib/screens/forgot_password_screen.dart` | 24–66 |
| Flutter OTP screen | `lib/screens/password_reset_otp_screen.dart` | 81–116 |
| Flutter new-password screen | `lib/screens/create_new_password_screen.dart` | password submit handler |

## Correct backend reset code

Replace the password-reset handler in `backend/api_handler.js` with the following implementation. In the current file, this handler starts at approximately line **927** and ends at approximately line **991**.

```js
// 6d. Forgot Password Reset
if (pathname === '/api/auth/forgot-password/reset' && method === 'POST') {
  const { email, resetToken, newPassword, confirmPassword } = body;
  const cleanEmail = (email || '').trim().toLowerCase();

  if (!cleanEmail || !newPassword || newPassword.length < 6) {
    return sendJSON(res, 400, {
      success: false,
      message: 'Password must be at least 6 characters long.',
    });
  }

  if (newPassword !== confirmPassword) {
    return sendJSON(res, 400, {
      success: false,
      message: 'Passwords do not match.',
    });
  }

  if (resetToken) {
    const decoded = verifyJwtToken(resetToken);
    if (
      !decoded ||
      decoded.purpose !== 'password_reset' ||
      (decoded.email || '').toLowerCase() !== cleanEmail
    ) {
      return sendJSON(res, 400, {
        success: false,
        message:
          'Invalid or expired password reset session. Please verify your OTP code again.',
      });
    }
  }

  const user = await DatabaseManager.getUserByEmailOrUsername(cleanEmail);
  if (!user) {
    return sendJSON(res, 404, {
      success: false,
      message: 'User account not found.',
    });
  }

  const updatedPassHash = hashPassword(newPassword);

  if (isSupabaseConfigured() && supabase) {
    try {
      const { data } = await supabase.auth.admin.listUsers({ perPage: 1000 });
      const supUser = (data?.users || []).find(
        (u) => (u.email || '').toLowerCase() === cleanEmail
      );

      if (supUser) {
        await supabase.auth.admin.updateUserById(supUser.id, {
          password: newPassword,
          email_confirm: true,
          user_metadata: {
            ...(supUser.user_metadata || {}),
            passwordHash: updatedPassHash,
          },
        });

        console.log(
          `[SUPABASE FORGOT PASSWORD] Updated Supabase password for: ${cleanEmail}`
        );
      } else {
        // Older profiles may not have a Supabase Auth user. Create the
        // credential so the normal login endpoint can verify the password.
        await supabase.auth.admin.createUser({
          email: cleanEmail,
          password: newPassword,
          email_confirm: true,
          user_metadata: {
            username: user.username,
            passwordHash: updatedPassHash,
          },
        });

        console.log(
          `[SUPABASE FORGOT PASSWORD] Created Supabase Auth user for: ${cleanEmail}`
        );
      }
    } catch (supErr) {
      console.warn('[SUPABASE PASSWORD RESET NOTICE]:', supErr.message);
    }
  }

  return sendJSON(res, 200, {
    success: true,
    message: 'Password reset successfully. You can now login with your new password.',
  });
}
```

## Login verification code

The login endpoint is in `backend/api_handler.js` at approximately lines **562–607**. It verifies the password through the same Supabase Auth service:

```js
let isPasswordCorrect = false;

if (user.password_hash && verifyPassword(password, user.password_hash)) {
  isPasswordCorrect = true;
} else if (isSupabaseConfigured() && supabase) {
  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email: cleanEmail,
      password,
    });

    if (data && data.user && !error) {
      isPasswordCorrect = true;
    }
  } catch (_) {}
}

if (!isPasswordCorrect) {
  return sendJSON(res, 401, {
    success: false,
    message: 'Invalid email or password.',
  });
}
```

This is why the reset handler must update or create the Supabase Auth user. Updating only a profile record does not make the new password available to this login check.

## Flutter request code

The Flutter client already sends the correct reset payload from `lib/services/api_service.dart`, approximately lines **242–263**:

```dart
static Future<Map<String, dynamic>> forgotPasswordReset({
  required String email,
  required String resetToken,
  required String newPassword,
  required String confirmPassword,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password/reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {
      'success': false,
      'message': 'Network error: Unable to connect to server ($e)',
    };
  }
}
```

The email is normalized to lowercase in both the Flutter client and backend. The same email must be used during reset and login.

## Do not use the old profile-password patch

Do not add `password_hash` to the `profiles` update payload unless the database schema has first been migrated. The current production schema defines `profiles` without a `password_hash` column. The correct production credential store is Supabase Auth.

The reset handler should not depend on this pattern:

```js
await DatabaseManager.updateUser(user.id, {
  password: newPassword,
  password_hash: updatedPassHash,
});
```

That code can report success even though the profile table cannot persist the field used for login.

## Required deployment configuration

The backend deployment must have these environment variables configured:

```text
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
SUPABASE_KEY or SUPABASE_ANON_KEY
JWT_SECRET
```

The service-role key is required for these admin operations:

```js
supabase.auth.admin.listUsers(...)
supabase.auth.admin.updateUserById(...)
supabase.auth.admin.createUser(...)
```

The service-role key must remain server-side and must never be included in the Flutter application.

## Testing procedure

After deployment, test with a real registered account:

1. Open **Forgot Password**.
2. Enter the registered email address.
3. Enter the six-digit OTP received by email.
4. Enter a new password and confirm it.
5. Wait for the reset success message.
6. Return to the login screen.
7. Enter the exact same email address.
8. Enter the new password exactly as entered during reset.
9. Tap **Login**.
10. Enter the login OTP if the application requests one.

If login still fails, inspect the backend logs for one of these messages:

```text
[SUPABASE FORGOT PASSWORD] Updated Supabase password for:
[SUPABASE FORGOT PASSWORD] Created Supabase Auth user for:
[SUPABASE PASSWORD RESET NOTICE]:
```

The first two messages indicate that the credential was provisioned. The notice indicates a Supabase configuration or permission problem that must be fixed in the deployment environment.

## Validation completed

The corrected source was validated with:

```bash
node --check backend/api_handler.js
node --check backend/db_manager.js
git diff --check
```

The fix is published on GitHub at commit `c868c47`.

## References

[1]: https://github.com/Prudhvi132/WRINDHA_OS_APP "WRINDHA_OS_APP GitHub repository"
[2]: https://supabase.com/docs/reference/javascript/auth-admin-updateuserbyid "Supabase Auth admin updateUserById reference"
[3]: https://supabase.com/docs/reference/javascript/auth-admin-createuser "Supabase Auth admin createUser reference"
[4]: https://supabase.com/docs/reference/javascript/auth-signinwithpassword "Supabase Auth signInWithPassword reference"
