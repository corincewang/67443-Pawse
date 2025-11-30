# Contest Auto-Rotation System

## Overview
The app now features an automatic contest rotation system with 50+ pre-generated contest themes that randomly selects and creates new contests when old ones expire.

## How It Works

### 1. **Contest Themes**
- 50+ creative contest prompts stored in `ContestThemeGenerator`
- Themes are randomly selected when creating new contests
- Categories include:
  - Cute (adorable poses, puppy eyes, etc.)
  - Funny (derp faces, silly positions, etc.)
  - Active (action shots, zoomies, etc.)
  - Seasonal (winter, spring, summer, fall themes)
  - And more!

### 2. **Automatic Rotation**
The system automatically:
- Checks every hour for expired contests
- Deactivates contests that have passed their end date
- Creates new contests using random unused themes
- Ensures there's always at least one active contest

### 3. **Components**

#### `ContestThemeGenerator` Service
- Contains 50+ pre-defined contest themes as a static array
- Simple random selection from the pool
- No database storage needed - themes are hardcoded
- Can be extended to use AI APIs (OpenAI, etc.) for dynamic generation

#### `ContestRotationService`
- Background service that runs on app launch
- Checks every hour for expired contests
- Automatically rotates and creates new contests

#### `ContestController` (Enhanced)
New methods:
- `createContestFromRandomTheme()` - Create contest using random theme from generator
- `rotateExpiredContests()` - Check and rotate expired contests
- `initializeContestSystem()` - Set up the entire system
- `ensureActiveContest()` - Ensure at least one active contest exists

## Usage

### Initial Setup
The system initializes automatically when the app launches. It will:
1. Check for expired contests
2. Create an active contest if none exists
3. Start the hourly rotation timer

### Admin View
Use `ContestAdminView` for testing and management:
- View available theme count
- View active contest count
- Create contests on demand
- Force rotation check
- Initialize system

### Adding to Your App
To access the admin view (for testing), add it to your navigation:
```swift
NavigationLink("Contest Admin") {
    ContestAdminView()
}
```

## Configuration

### Contest Duration
Default: 7 days
To change: Modify the `durationDays` parameter in `createContestFromRandomTheme()`

### Rotation Check Interval
Default: Every hour (3600 seconds)
To change: Modify the timer interval in `ContestRotationService.startService()`

### Theme Pool Size
Default: 50+ themes hardcoded
To add more: Edit the `themes` array in `ContestThemeGenerator`

## Future Enhancements

### AI Integration
The system is designed to support AI-generated themes:

1. **OpenAI Integration**
   - Uncomment the `generateAIThemes()` method in `ContestThemeGenerator`
   - Add OpenAI API key to your config
   - Implement API call to generate creative themes

2. **Example Implementation**:
```swift
// In ContestThemeGenerator.swift
static func generateAIThemes(count: Int) async throws -> [ContestTheme] {
    let prompt = """
    Generate \(count) creative pet photo contest themes.
    Make them fun, engaging, and suitable for all pets.
    """
    
    // Call OpenAI API
    let response = try await OpenAIService.generateCompletion(prompt: prompt)
    
    // Parse and return themes
    return parseThemes(from: response)
}
```

## Data Structure

### Contest Themes
- Stored as a static array in `ContestThemeGenerator.themes`
- No database storage required
- 50+ pre-defined themes
- Randomly selected when creating contests

## Testing

1. **Test Automatic Rotation**:
   - Create a contest with 1-day duration
   - Wait 24 hours or manually change end_date in Firestore
   - Check that new contest is created automatically

2. **Test Theme Selection**:
   - Open ContestAdminView
   - Create multiple contests
   - Verify different random themes are selected

3. **Manual Testing**:
```swift
// In your app or test file
Task {
    let controller = ContestController()
    
    // Create contest with random theme
    let contestId = try await controller.createContestFromRandomTheme()
    print("Created contest: \(contestId)")
    
    // Rotate contests
    try await controller.rotateExpiredContests()
}
```

## Troubleshooting

**Want to add more themes?**
- Edit the `themes` array in `ContestThemeGenerator.swift`
- Add your custom theme strings

**Contests not rotating?**
- Check that ContestRotationService started (see console logs)
- Verify app is running in foreground for timer to work
- For production, implement background tasks or server-side rotation

**Same themes repeating?**
- Themes are randomly selected from the pool, so duplicates can occur
- Add more themes to the array to increase variety
- Or implement AI integration for truly unique themes each time
