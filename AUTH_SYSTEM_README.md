# Authentication System Documentation

## Overview
This authentication system implements secure user authentication with role-based access control for the ITCS444 project. It uses Firebase Authentication and Firestore for user management.

## Features Implemented

### 1. User Roles
- **Admin (Donor)**: Can add items, manage donations, view rental requests, and access analytics
- **Renter**: Can browse items, request rentals, view rental history, and manage favorites
- **Guest**: Browse-only access to view available items (no rental capabilities)

### 2. Authentication Features
- ✅ Email/Password registration and login
- ✅ Guest mode (anonymous authentication)
- ✅ Secure password validation (minimum 6 characters)
- ✅ Role-based access control
- ✅ Firebase integration for user data persistence

### 3. User Profile
The profile page includes:
- Full Name
- Email (read-only)
- Contact Number
- ID Number
- Preferred Contact Method (Email, Phone, or SMS)
- Role Badge (color-coded)
- Account creation date
- Edit profile functionality (not available for guests)
- Sign out functionality

### 4. Security Features
- Password visibility toggle
- Password confirmation during registration
- Email validation
- Firebase error handling with user-friendly messages
- Protected routes based on user roles

## Project Structure

```
lib/
├── models/
│   ├── user_model.dart          # User data model
│   └── user_role.dart           # User role enum and extensions
├── services/
│   └── auth_service.dart        # Authentication service
├── screens/
│   ├── login_screen.dart        # Login page
│   ├── register_screen.dart     # Registration page
│   ├── profile_page.dart        # User profile page
│   └── home/
│       ├── admin_home.dart      # Admin dashboard
│       ├── renter_home.dart     # Renter dashboard
│       └── guest_home.dart      # Guest view
└── main.dart                    # App entry point with auth wrapper
```

## Usage Guide

### For Users

#### Registration
1. Launch the app
2. Click "Register" on the login screen
3. Fill in all required fields:
   - Full Name
   - Email
   - Password (minimum 6 characters)
   - Confirm Password
   - Contact Number
   - ID Number
   - Select Role (Admin or Renter)
   - Choose Preferred Contact Method
4. Click "Register" to create your account

#### Login
1. Enter your email and password
2. Click "Login"
3. You'll be redirected to your role-specific dashboard

#### Guest Mode
1. Click "Continue as Guest" on the login screen
2. Browse available items (read-only access)
3. Login anytime to access full features

#### Profile Management
1. Click the profile icon in the app bar
2. View your profile information
3. Click the edit icon to update:
   - Name
   - Contact Number
   - ID Number
   - Preferred Contact Method
4. Click "Save Changes" to update your profile

### For Developers

#### Adding New Authentication Methods
Edit `lib/services/auth_service.dart` to add new authentication methods (e.g., Google Sign-In, Facebook Login)

#### Customizing User Roles
1. Edit `lib/models/user_role.dart` to add new roles
2. Update the switch statements in home navigation logic
3. Create corresponding home screen in `lib/screens/home/`

#### Modifying User Model
Edit `lib/models/user_model.dart` to add new user fields. Remember to:
- Update `toMap()` method
- Update `fromMap()` factory
- Update Firestore write operations
- Update UI forms accordingly

## Firestore Database Structure

```
users (collection)
└── {userId} (document)
    ├── uid: string
    ├── email: string
    ├── name: string
    ├── contact: string
    ├── idNumber: string
    ├── preferredContactMethod: string
    ├── role: string (admin/renter/guest)
    └── createdAt: timestamp
```

## Security Rules (Recommended)

Add these rules to your Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Users can read their own data
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Users can create their own profile during registration
      allow create: if request.auth != null && request.auth.uid == userId;
      
      // Users can update their own profile (except role)
      allow update: if request.auth != null 
                    && request.auth.uid == userId
                    && request.resource.data.role == resource.data.role;
      
      // Admins can read all user data
      allow read: if request.auth != null 
                  && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## Testing the System

### Test User Scenarios

1. **Admin Registration and Login**
   - Register as Admin role
   - Login and verify Admin dashboard appears
   - Check profile page shows Admin badge
   - Verify admin-specific actions are visible

2. **Renter Registration and Login**
   - Register as Renter role
   - Login and verify Renter dashboard appears
   - Check profile page shows Renter badge
   - Verify renter-specific actions are visible

3. **Guest Mode**
   - Click "Continue as Guest"
   - Verify limited access (browse only)
   - Check that rental and favorite actions prompt login
   - Verify guest badge in interface

4. **Profile Management**
   - Login as any role (except guest)
   - Navigate to profile
   - Edit and save profile information
   - Verify changes persist after logout/login

5. **Authentication Flow**
   - Test invalid email format
   - Test password mismatch
   - Test short password (< 6 characters)
   - Test sign out functionality

## Known Limitations

- Guest users cannot edit their profile
- Email cannot be changed after registration (Firebase limitation)
- Role cannot be changed after registration (security measure)
- Password reset functionality requires email configuration

## Future Enhancements

- [ ] Email verification
- [ ] Password reset via email
- [ ] Social media authentication (Google, Facebook)
- [ ] Two-factor authentication
- [ ] User search and admin management panel
- [ ] Profile picture upload
- [ ] Role upgrade requests
- [ ] Activity logging and audit trails

## Troubleshooting

### Common Issues

**Issue**: User cannot login after registration
- **Solution**: Check Firebase console for the user account. Verify email/password is correct.

**Issue**: Profile data not loading
- **Solution**: Ensure Firestore security rules allow the user to read their own data.

**Issue**: Guest mode not working
- **Solution**: Enable Anonymous Authentication in Firebase Console.

**Issue**: Registration fails with "email already in use"
- **Solution**: User should use the login screen instead, or use password reset if forgotten.

## Contact & Support

For issues or questions about the authentication system:
- Check Firebase Console for backend issues
- Review error messages in the app
- Check Firestore database structure
- Verify Firebase configuration in `main.dart`

## Version History

- **v1.0.0** (December 2025)
  - Initial authentication system
  - Role-based access control
  - User profile management
  - Guest mode implementation
