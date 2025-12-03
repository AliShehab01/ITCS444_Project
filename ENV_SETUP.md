# Environment Variables Setup

## Overview
The Firebase API keys and sensitive configuration have been moved to environment variables for better security.

## Files Created

1. **`.env`** - Contains your actual Firebase credentials (NOT committed to git)
2. **`.env.example`** - Template file showing required variables (committed to git)
3. **`lib/config/env_config.dart`** - Configuration class to access environment variables

## Setup Instructions

### For New Developers

1. **Copy the example file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` file** and replace the placeholder values with your actual Firebase credentials:
   ```
   FIREBASE_API_KEY=your_actual_api_key_here
   FIREBASE_PROJECT_ID=your_actual_project_id
   FIREBASE_MESSAGING_SENDER_ID=your_actual_sender_id
   FIREBASE_APP_ID=your_actual_app_id
   ```

3. **Run the app:**
   ```bash
   flutter pub get
   flutter run
   ```

## Security Notes

✅ **`.env`** is added to `.gitignore` - your credentials won't be committed to git
✅ **`.env.example`** is tracked in git - team members know what variables are needed
✅ **No hardcoded credentials** - all sensitive data is in environment variables

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `FIREBASE_API_KEY` | Firebase API Key | AIzaSy... |
| `FIREBASE_PROJECT_ID` | Firebase Project ID | testing-22fda |
| `FIREBASE_MESSAGING_SENDER_ID` | Firebase Messaging Sender ID | 421309501948 |
| `FIREBASE_APP_ID` | Firebase App ID | 1:421309501948:web:... |

## Usage in Code

The environment variables are accessed through the `EnvConfig` class:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/env_config.dart';

void main() async {
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Use the config
  print(EnvConfig.firebaseApiKey);
}
```

## Troubleshooting

### Error: "Unable to load asset: .env"
**Solution:** Make sure the `.env` file exists in the project root directory.

### Error: Environment variable is empty
**Solution:** Check that you've filled in all values in the `.env` file.

### Changes to .env not reflecting
**Solution:** 
1. Stop the app
2. Run `flutter clean`
3. Run `flutter pub get`
4. Restart the app

## For Production/Deployment

For different environments (development, staging, production), you can create multiple environment files:

- `.env.development`
- `.env.staging`
- `.env.production`

Then load the appropriate file based on your build configuration.

## Package Used

- **flutter_dotenv**: ^5.1.0
  - Documentation: https://pub.dev/packages/flutter_dotenv
  - Loads environment variables from `.env` files
  - Zero-dependency solution for Flutter

## Important Reminders

⚠️ **NEVER commit the `.env` file to git**
⚠️ **NEVER share your `.env` file publicly**
⚠️ **Always use `.env.example` for documentation**
⚠️ **Rotate keys if accidentally exposed**

## Team Collaboration

When sharing the project:
1. Share the `.env.example` file (already in git)
2. Share the actual credentials through secure channels (email, password manager, etc.)
3. Each team member creates their own `.env` file from the example
