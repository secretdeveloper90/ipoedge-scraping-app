# ipoedge_app

A new Flutter project.

## Getting Started

# IPO Edge Flutter App

A Flutter application for managing IPO (Initial Public Offering) data with Firebase integration.

## Features

The app has three main tabs under the IPO section:

### 1. Listing Tab
- Displays a list of all IPOs fetched from the API
- Shows IPO details including company name, sector, issue price, listing price, and gains
- Pull-to-refresh functionality
- Tap to view detailed IPO information

### 2. Management Tab
- **Add IPO**: Enter a company ID to fetch IPO data from the API and save to Firebase
- **View**: Opens a modal showing all IPO details
- **Update**: Fetches latest data from API and updates the existing Firebase record
- **Delete**: Removes the IPO entry from Firebase
- Real-time list of saved IPOs with action buttons

### 3. Yearly Screener Tab
- Filter IPOs by year using a dropdown selector
- Displays IPO screener data for the selected year
- Shows IPO count for the selected year

## API Endpoints

The app integrates with the following API endpoints:

- `GET /api/ipos/listing-details` – Fetch a list of all IPOs
- `GET /api/ipos/company/:companyId` – Fetch IPO data for a specific company
- `GET /api/ipos/screener/:year` – Fetch IPO screener data for a specific year

## Setup Instructions

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio or VS Code with Flutter extensions
- Firebase project (for data storage)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ipoedge-scraping-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase** (Optional - currently disabled)
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add an Android/iOS app to your Firebase project
   - Download the `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
   - Place the configuration files in the appropriate directories
   - Enable Firestore Database in your Firebase project
   - Uncomment Firebase initialization in `lib/main.dart`

4. **Update API URL** (if needed)
   - The app is currently configured to use: `https://ipoedge-scraping-be.vercel.app`
   - To change the API URL, update the `baseUrl` in `lib/services/api_service.dart`

5. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── ipo_model.dart       # IPO data model
├── services/
│   ├── api_service.dart     # API integration service
│   └── firebase_service.dart # Firebase CRUD operations
├── screens/
│   ├── home_screen.dart     # Main screen with bottom navigation
│   ├── listing_tab.dart     # IPO listing tab
│   ├── management_tab.dart  # IPO management tab
│   └── yearly_screener_tab.dart # Yearly screener tab
├── widgets/
│   ├── ipo_card.dart        # Reusable IPO card widget
│   └── ipo_management_card.dart # Management card with actions
└── utils/
    └── constants.dart       # App constants
```

## Dependencies

- `firebase_core`: Firebase SDK core
- `cloud_firestore`: Firestore database
- `http`: HTTP client for API calls
- `provider`: State management (if needed)
- `intl`: Internationalization support

## Features in Detail

### Error Handling
- Network error handling with retry functionality
- User-friendly error messages
- Loading states for all async operations

### UI/UX
- Material Design 3 components
- Responsive design
- Pull-to-refresh functionality
- Confirmation dialogs for destructive actions
- Status indicators for IPO states

### Data Management
- Local caching with Firebase Firestore
- Real-time data synchronization
- Duplicate prevention for IPO entries
- Batch operations support

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Troubleshooting

1. **Firebase Issues**: Ensure Firebase configuration files are properly placed and Firebase is initialized
2. **API Connection**: Check network connectivity and API endpoint availability
3. **Build Issues**: Run `flutter clean` and `flutter pub get` to resolve dependency issues

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.
