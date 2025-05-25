<h1 align="center">Business Logic App - Real Estate 📱</h1>
<div align="center">
  Designed to enhance the efficiency of internal processes within a real estate company.
  <br>
  <br>
  [![Flutter](https://img.shields.io/badge/Flutter-blue?style=flat-square&logo=flutter)](https://flutter.dev/)
  [![Firebase](https://img.shields.io/badge/Firebase-orange?style=flat-square&logo=firebase)](https://firebase.google.com/)
  [![Cloudinary](https://img.shields.io/badge/Cloudinary-blue?style=flat-square&logo=cloudinary)](https://cloudinary.com/)
  [![Google Cloud](https://img.shields.io/badge/Google%20Cloud-blue?style=flat-square&logo=google-cloud)](https://cloud.google.com/)
  [![Vercel](https://img.shields.io/badge/Vercel-black?style=flat-square&logo=vercel)](https://vercel.com/)
  [![GitHub](https://img.shields.io/badge/GitHub-Repository-gray?style=flat-square&logo=github)](https://github.com/LeoFreyre/adminrentalho-app-real-estate-control)
</div>

## 🌟 Features

This app is designed to cover business logic with 2 main roles: **Owner** and **Employee**.

### 🏠 **Owner Module (Admin)**

#### 1. **Cleaning & Housekeeping**
- **Smart Assignment**: 
  - Assign tasks to individual employees or groups
  - Automatic checkout detection system from Smoobu API
  - Task prioritization by date and time
- **Task Management**:
  - Three states: Pending/In Progress/Completed
  - Limit of 5 multimedia files per state
  - Integrated video player with controls
- **Real-Time Synchronization**:
  - Automatic updates via Firestore
  - Visual notifications for state changes

#### 2. **Maintenance Services**
- **Complete Ticket Management**:
  - Create/Edit with title, message and multimedia
  - Assignment to specific employees
  - Historical records with chronological order
- **Advanced Multimedia System**:
  - Photo and video support (camera/gallery)
  - Interactive carousel preview
  - Cloudinary storage with optimization
- **Access Control**:
  - Restriction by employee groups  
  - Granular permissions for editing

#### 3. **Document Management**
- **Smoobu Integration**:
  - Automatic booking synchronization
  - Blocked booking filtering
  - Complete guest details visualization
- **Check-In Workflow**:
  - Document received marking system
  - Verifiable states (Pending/Completed)
  - Historical records organized by dates

### 👷 **Employee Module**

#### 1. **Cleaning Tasks**
- **Real-Time Interaction**:
  - Status updates from UI
  - Visual notifications for new tasks
  - Date/time reminder system
- **Integrated Multimedia System**:
  - Direct camera capture
  - Multiple upload with preview
  - Organization by phase (process/completed)

#### 2. **Maintenance**
- **Assigned Ticket Management**:
  - Real-time progress updates
  - Direct communication with administrators
  - Evidence system with multimedia
- **Diagnostic Tools**:
  - Explanatory video recording
  - Time-stamped photos
  - Cloud storage integration

#### 3. **Document Verification**
- **Check-In Interface**:
  - List organized by arrival dates
  - Quick marking system
  - Access to complete booking details
  - Visual document verification

### 🛠 **General Technical Features**

#### 🔒 Security and Access
- Firebase Auth authentication
- Role-based access control (admin/employee)
- Configurable group restrictions
- Real-time permission validation

#### 📱 Multiplatform
- Native support for iOS and Android
- Adaptive UI for different devices
- Specific function restrictions in web version

#### 📊 Integrations
- **Firebase Firestore**: Bidirectional synchronization
- **Cloudinary**: Optimized multimedia management
- **Smoobu API**: Automatic booking sync

#### 🎨 Advanced UI/UX
- Dynamic tab system
- Smooth transition animations
- Responsive design with visual feedback
- Interactive modals with gestures

#### ⚙️ Key Technologies
- **Flutter 3.0+** with Null Safety
- **Firebase**: Auth/Firestore/Storage
- **Cloudinary SDK**: Media optimization
- **Smoobu API**: Booking integration
- **Image Picker & Video Player**: Multimedia management
- **Intl**: Date/time formatting

*[Note: Current version 1.2.0 - Support for iOS 15+/Android 10+]*

## 📦 Installation

1. Clone the repository:
```bash
git clone https://github.com/LeoFreyre/adminrentalho-app-real-estate-control.git
cd adminrentalho-app-real-estate-control
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Install iOS dependencies (macOS only):
```bash
cd ios
pod install
cd ..
```

4. Configure Firebase:
   - Create a new Firebase project
   - Add your Android and iOS apps to the project
   - Download and place the configuration files:
     - `google-services.json` in `android/app/`
     - `GoogleService-Info.plist` in `ios/Runner/`
   - Enable Authentication, Firestore, and Storage in Firebase Console

5. Set up Android and iOS emulators:
   - **Android**: Install Android Studio and create an AVD
   - **iOS** (macOS only): Install Xcode and iOS Simulator

6. Run the application:
```bash
flutter run
```

## 🚀 Usage

Make sure to properly configure Firebase and connect it to your project. Set up Android and iOS emulators (if working with macOS) before running the application.

The app provides different interfaces based on user roles:
- **Owners/Admins**: Full access to property management, task assignment, and employee oversight
- **Employees**: Access to assigned tasks, maintenance tickets, and document verification

## 💻 Technology Stack

- **Flutter** - Cross-platform mobile development
- **Firebase** - Backend services and real-time database
- **Cloudinary** - Media management and optimization
- **Vercel** - Web deployment platform

### External Tools
- **Homebrew** - Package manager for macOS
- **Node.js** - JavaScript runtime for additional tooling

## 📱 Screenshots

*[Screenshots section - 9 images in 3-3-3 grid format would be displayed here]*

## 🌐 Live

Visit the web version of the project: https://suite-adminrentalho.web.app

## 📄 License

This project is licensed under the MIT License.