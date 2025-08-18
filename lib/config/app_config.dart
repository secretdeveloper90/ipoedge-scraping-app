class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'https://ipoedge-scraping-be.vercel.app';
  
  // Firebase Configuration
  static const String firebaseCollection = 'ipos';
  
  // App Information
  static const String appName = 'IPO Edge';
  static const String appVersion = '1.0.0';
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration refreshTimeout = Duration(seconds: 10);
  
  // UI Configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection and try again.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String unknownErrorMessage = 'An unexpected error occurred. Please try again.';
  static const String noDataMessage = 'No data available.';
  
  // Success Messages
  static const String ipoAddedMessage = 'IPO added successfully';
  static const String ipoUpdatedMessage = 'IPO updated successfully';
  static const String ipoDeletedMessage = 'IPO deleted successfully';
  
  // Validation Messages
  static const String emptyCompanyIdMessage = 'Please enter a company ID';
  static const String duplicateIpoMessage = 'IPO with this company ID already exists';
  static const String ipoNotFoundMessage = 'IPO not found for the given company ID';
}
