# KurekTrack - Project Structure

## 📁 Folder Organization

```
KurekTrack/
├── App/
│   └── KurekTrackApp.swift                    # App entry point
│
├── Models/
│   └── (Model files will be extracted here)
│
├── Views/
│   ├── Components/
│   │   ├── MetricCard.swift                   # Large metric display card
│   │   ├── SmallStatCard.swift                # Small statistics card
│   │   └── PermissionView.swift               # Location permission screen
│   │
│   ├── Workout/
│   │   ├── ContentView.swift                  # Main workout screen
│   │   ├── WorkoutModeSelectionView.swift     # Workout mode selection
│   │   └── WebView.swift                      # WebView helper
│   │
│   ├── History/
│   │   └── HistoryView.swift                  # Workout history
│   │
│   ├── Splits/
│   │   └── SplitTimesView.swift               # Split times & analysis
│   │
│   ├── Weather/
│   │   └── WeatherView.swift                  # Weather & water conditions
│   │
│   ├── AudioCoach/
│   │   └── AudioCoachSettingsView.swift       # Audio coaching settings
│   │
│   └── Settings/
│       └── SettingsView.swift                 # App settings & language
│
├── ViewModels/
│   └── WorkoutManager.swift                   # Workout state management
│   └── (Other managers will be extracted here)
│
├── Services/
│   └── LocationService.swift                  # GPS & location tracking
│
└── Resources/
    ├── Assets.xcassets/                       # Images & icons
    └── Localizable.xcstrings                  # Translations (TR/EN)
```

## 🎯 Architecture Pattern

**MVVM (Model-View-ViewModel)**

- **Models**: Data structures (WorkoutRecord, SplitData, etc.)
- **Views**: SwiftUI views organized by feature
- **ViewModels**: Business logic and state management (@ObservableObject)
- **Services**: External services (Location, Weather, etc.)

## 📝 Next Steps

### Xcode Integration

1. Open `KurekTrack.xcodeproj` in Xcode
2. In Project Navigator, you'll see the new folder structure
3. If folders appear yellow (missing references):
   - Right-click on `KurekTrack` folder
   - Select "Add Files to KurekTrack..."
   - Select all new folders and files
   - Make sure "Create groups" is selected
   - Click "Add"

### Model Extraction (TODO)

Files to split further:
- `HistoryView.swift` → Extract `WorkoutRecord` & `HistoryManager` 
- `SplitTimesView.swift` → Extract `SplitData` & `SplitTimesManager`
- `AudioCoachSettingsView.swift` → Extract `AudioCoachManager`
- `WeatherView.swift` → Extract `WeatherData` & models
- `WorkoutModeSelectionView.swift` → Extract `WorkoutMode` & `BoatType`
- `SettingsView.swift` → Extract `SettingsManager`

## ✅ Benefits

- **Clean Architecture**: Easy to navigate and maintain
- **Separation of Concerns**: Each file has a single responsibility
- **Reusable Components**: Shared UI components in one place
- **Scalability**: Easy to add new features
- **Apple Best Practices**: Follows iOS development standards
