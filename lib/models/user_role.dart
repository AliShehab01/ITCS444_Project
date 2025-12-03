enum UserRole {
  admin, // Donor
  renter,
  guest,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin (Donor)';
      case UserRole.renter:
        return 'Renter';
      case UserRole.guest:
        return 'Guest';
    }
  }

  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.renter:
        return 'renter';
      case UserRole.guest:
        return 'guest';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'renter':
        return UserRole.renter;
      case 'guest':
        return UserRole.guest;
      default:
        return UserRole.guest;
    }
  }
}
