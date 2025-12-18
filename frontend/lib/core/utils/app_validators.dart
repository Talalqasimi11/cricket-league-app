// lib/core/utils/app_validators.dart

class AppValidators {
  /// Formats a phone number to E.164 format for Pakistan (e.g., 923XXXXXXXXX)
  static String formatPhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    if (digits.startsWith('92')) {
      return digits;
    } else if (digits.startsWith('0')) {
      return '92${digits.substring(1)}'; // Remove leading 0, add 92
    } else if (digits.length == 10) {
      return '92$digits'; // Assume local number, add 92
    }
    
    return digits;
  }

  /// Validates Pakistan phone number format
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    final digits = value.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length < 10) {
      return 'Please enter a valid phone number';
    }
    
    // Optional: Strict check for Pakistan prefixes if needed
    // if (!digits.startsWith('92') && !digits.startsWith('0') && digits.length != 10) {
    //   return 'Please enter a valid Pakistan phone number';
    // }
    
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    // Simple but effective regex for email validation
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String originalPassword) {
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
  
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) return 'OTP is required';
    if (value.length != 6) return 'OTP must be 6 digits';
    return null;
  }
}