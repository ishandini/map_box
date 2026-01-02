# Quick Start Guide - Walking Challenge Feature

## 🚀 Getting Started in 5 Minutes

### Step 1: Install Dependencies

```bash
cd /Users/ishanweerasooriya/Documents/FlutterApps/map_box
flutter pub get
```

### Step 2: Add Your Route Data

Place your route JSON file at:
```
assets/jsons/bankok.json
```

If you don't have a route file yet, create a sample one:

```json
[
  {
    "lat": 13.70374,
    "long": 100.57545,
    "distance": 0,
    "steps": 0,
    "zooml": 750,
    "action": "native_post",
    "link": "2457",
    "flag_act": "landmarke",
    "flag_deact": "landmarkd",
    "stepstonext": 16796,
    "nextcity": "Bangkok",
    "city": "Bangkok Port",
    "citymsg": "Welcome to Bangkok Port!",
    "cityimg": "https://via.placeholder.com/400",
    "wc": "where it all begins",
    "currentcity": "Bangkok Port"
  },
  {
    "lat": 13.70380,
    "long": 100.57550,
    "distance": 50,
    "steps": 100,
    "zooml": 750,
    "action": "-",
    "link": "-",
    "flag_act": "landmarke",
    "flag_deact": "landmarkd",
    "stepstonext": 16796,
    "nextcity": "Bangkok City",
    "city": "-",
    "citymsg": "-",
    "cityimg": "-",
    "wc": "-",
    "currentcity": "-"
  }
]
```

### Step 3: Run the App

```bash
flutter run
```

### Step 4: Test the Feature

1. **Launch the app** and tap "Show Map"
2. **Watch animations**:
   - Rotation animation (6 seconds)
   - Fly to location (8 seconds)
   - Route path drawing (2.5 seconds)
3. **Test step counter**:
   - Use **+** button to add 1000 steps
   - Use **-** button to subtract 1000 steps
   - Watch the green progress path extend
4. **Interact with landmarks**:
   - Tap on orange circle markers
   - View landmark details in bottom sheet

## 📱 Key Features at a Glance

| Feature | Description |
|---------|-------------|
| **Full Route Path** | Gray line showing complete route |
| **Progress Path** | Green line showing completed portion |
| **Landmark Markers** | Orange (reached) or gray (locked) circles |
| **Animated Drawing** | Smooth 2.5s path animation on first load |
| **Step Counter** | Real-time progress updates |
| **Landmark Info** | Tap markers to see details |

## 🎨 Visual Guide

```
Map Display:
┌─────────────────────────────┐
│  [-]  Steps: 5000  [+]      │  ← Test controls
├─────────────────────────────┤
│                             │
│   ╭─gray route path──────╮ │  ← Full route (gray)
│   │  ●──green progress─● │ │  ← Progress (green)
│   │  │                  │ │
│   │  🔴 Landmark (reached)│ │  ← Orange markers
│   │  │                  │ │
│   │  ⚪ Landmark (locked) │ │  ← Gray markers
│   ╰─────────────────────╯ │
│                             │
└─────────────────────────────┘
```

## 🔧 Integrating Real Step Counter

### Option 1: Pedometer Package

```bash
flutter pub add pedometer
```

```dart
// Update: lib/core/services/step_counter_service.dart
import 'package:pedometer/pedometer.dart';

class StepCounterService {
  static Stream<int>? _stepCountStream;
  static int _currentSteps = 0;

  static void initialize() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream?.listen((StepCount event) {
      _currentSteps = event.steps;
    });
  }

  static int getUserStepCount() {
    return _currentSteps;
  }
}
```

### Option 2: Health Package

```bash
flutter pub add health
```

```dart
// Update: lib/core/services/step_counter_service.dart
import 'package:health/health.dart';

class StepCounterService {
  static final Health _health = Health();

  static Future<int> getUserStepCount() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    final steps = await _health.getTotalStepsInInterval(midnight, now);
    return steps ?? 0;
  }
}
```

## 📊 Step Count Update Flow

```dart
// Anywhere in your app with access to RouteBloc:

// 1. Get current step count
final steps = StepCounterService.getUserStepCount();

// 2. Update RouteBloc
context.read<RouteBloc>().add(UpdateUserStepsEvent(steps));

// 3. Map automatically updates progress
```

## 🎯 Common Use Cases

### Use Case 1: Manual Step Input

```dart
TextFormField(
  onChanged: (value) {
    final steps = int.tryParse(value) ?? 0;
    context.read<RouteBloc>().add(UpdateUserStepsEvent(steps));
  },
)
```

### Use Case 2: Periodic Step Updates

```dart
Timer.periodic(Duration(seconds: 10), (timer) {
  final steps = StepCounterService.getUserStepCount();
  context.read<RouteBloc>().add(UpdateUserStepsEvent(steps));
});
```

### Use Case 3: Background Step Sync

```dart
@override
void initState() {
  super.initState();
  // Listen to step changes
  StepCounterService.stepStream.listen((steps) {
    context.read<RouteBloc>().add(UpdateUserStepsEvent(steps));
  });
}
```

## 🎨 Customization Quick Tips

### Change Route Color

Edit `lib/features/walking_challenge/presentation/utils/map_layer_manager.dart`:

```dart
LineLayer(
  lineColor: 0xFF1E88E5,  // Blue instead of gray
  lineWidth: 6.0,          // Thicker line
)
```

### Change Progress Color

```dart
LineLayer(
  lineColor: 0xFFE91E63,  // Pink instead of green
  lineOpacity: 0.8,        // Semi-transparent
)
```

### Adjust Animation Speed

Edit `lib/features/walking_challenge/presentation/widgets/animated_map_view.dart`:

```dart
_pathAnimationController = AnimationController(
  duration: const Duration(milliseconds: 5000), // 5 seconds instead of 2.5
);
```

## 📁 Project Structure Overview

```
lib/
├── core/                          # Core utilities
│   ├── di/                       # Dependency injection
│   ├── error/                    # Error handling
│   ├── services/                 # Services (step counter)
│   └── usecase/                  # Base use case
│
├── features/walking_challenge/    # Feature module
│   ├── domain/                   # Business logic
│   ├── data/                     # Data management
│   └── presentation/             # UI components
│
├── animated_map_view.dart        # Entry point (exports feature)
└── main.dart                     # App initialization
```

## 🐛 Troubleshooting

### Issue: Route not showing

**Solution:**
```bash
# 1. Check if JSON exists
ls -la assets/jsons/bankok.json

# 2. Verify assets in pubspec.yaml
cat pubspec.yaml | grep -A 3 "assets:"

# 3. Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Issue: "No step updates"

**Check:**
1. Verify `UpdateUserStepsEvent` is dispatched
2. Check BLoC state with Flutter DevTools
3. Ensure `getUserStepCount()` returns correct value

### Issue: Poor performance

**Solutions:**
1. Reduce waypoint count in JSON
2. Increase simplification tolerance
3. Lower animation frame rate

## 📚 Next Steps

1. ✅ **Read** [WALKING_CHALLENGE_README.md](WALKING_CHALLENGE_README.md) for complete documentation
2. ✅ **Integrate** real step counter using one of the methods above
3. ✅ **Customize** colors and animations to match your brand
4. ✅ **Test** with your actual route data (bankok.json)
5. ✅ **Deploy** to production

## 💡 Pro Tips

1. **Development Mode**: Use the +/- buttons for quick testing
2. **Production Mode**: Replace test buttons with real step counter
3. **Performance**: Simplify routes with 10k+ points for smooth rendering
4. **UX**: Add loading indicators during route data load
5. **Accessibility**: Add semantic labels for screen readers

## 🎉 You're Ready!

Your walking challenge feature is now fully implemented with:
- ✅ Clean architecture
- ✅ BLoC state management
- ✅ Animated path drawing
- ✅ Progress tracking
- ✅ Landmark system
- ✅ Performance optimization

**Happy coding!** 🚀

---

Need help? Check the [full documentation](WALKING_CHALLENGE_README.md) or review the inline code comments.
