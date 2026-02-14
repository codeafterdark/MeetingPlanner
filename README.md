# Meeting Planner

A powerful iOS app that helps you find the most cost-effective meeting locations by analyzing flight costs for all attendees. Perfect for businesses, remote teams, and event planners who need to bring people together from different locations.

## Features

- **Smart Location Analysis**: Compare flight costs across multiple potential meeting destinations
- **Multi-Attendee Support**: Add attendees with their home airports for comprehensive cost analysis
- **Real-Time Flight Data**: Integration with Amadeus Flight API for current flight prices and schedules
- **Travel Buffer Management**: Configure arrival and departure buffers for optimal travel planning
- **Meeting Persistence**: Save and manage multiple meetings with full search history
- **Cost Optimization**: Automatically identify the most cost-effective location for your group
- **Detailed Flight Information**: View connections, duration, airlines, and pricing details
- **Intuitive SwiftUI Interface**: Native iOS design with smooth animations and accessibility support

## Requirements

- iOS 17.0+ / iPadOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Amadeus API credentials (for flight data)

## Installation

### Using Xcode

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/meeting-planner.git
   ```
2. Open `MeetingPlanner.xcodeproj` in Xcode
3. Configure your API credentials (see Configuration section)
4. Build and run the project

## Configuration

### API Setup

1. Sign up for an [Amadeus for Developers](https://developers.amadeus.com/) account
2. Create a new app to get your API key and secret
3. Create a `Config.swift` file in your project:

```swift
import Foundation

struct Config {
    static let amadeusAPIKey = "your_amadeus_api_key"
    static let amadeusAPISecret = "your_amadeus_api_secret"
}
```

⚠️ **Important**: Add `Config.swift` to your `.gitignore` to keep your API credentials secure.

## Usage

### Creating a Meeting

```swift
// Create a new meeting
let meeting = Meeting(
    name: "Q1 Strategy Meeting",
    startDate: Date().addingTimeInterval(86400 * 14), // 2 weeks from now
    numberOfDays: 3,
    travelBufferBefore: 1,
    travelBufferAfter: 1,
    potentialLocations: [
        Location(cityName: "New York", airportCode: "JFK", countryCode: "US"),
        Location(cityName: "San Francisco", airportCode: "SFO", countryCode: "US")
    ],
    attendees: [
        Attendee(name: "Alice Johnson", homeAirport: "LAX"),
        Attendee(name: "Bob Smith", homeAirport: "ORD")
    ]
)
```

### Searching Flight Options

```swift
// Initialize services
let appServices = AppServices()

// Search for flights
Task {
    let results = await appServices.flightService.searchFlights(
        for: meeting,
        to: meeting.potentialLocations
    )
    
    // Analyze costs by location
    let bestLocation = results.min { $0.totalCost < $1.totalCost }
    print("Best location: \(bestLocation?.location.displayName)")
}
```

### Managing Saved Meetings

```swift
// Save a meeting with search results
appServices.meetingDataManager.saveMeeting(meeting, searchResults: locationAnalysis)

// Load saved meetings
let savedMeetings = appServices.meetingDataManager.savedMeetings

// Delete a meeting
appServices.meetingDataManager.deleteMeeting(withId: meetingId)
```

## Screenshots

<!-- Add screenshots of your app here -->
![Meeting Details](screenshots/meeting-details.png)
![Flight Search Results](screenshots/search-results.png)
![Saved Meetings](screenshots/saved-meetings.png)

## Architecture

This project follows the **MVVM pattern** with modern Swift concurrency and uses:

- **SwiftUI**: Modern declarative UI framework
- **Swift Concurrency**: async/await for flight API calls
- **@Observable**: New Swift observation framework for state management
- **UserDefaults**: Local persistence for saved meetings
- **Combine**: Reactive programming for API responses
- **Foundation**: Core Swift framework features

### Key Components

- `MeetingDataManager`: Handles meeting persistence and CRUD operations
- `FlightSearchService`: Manages Amadeus API integration and flight searches
- `AppServices`: Central service coordinator using dependency injection
- `Models.swift`: Core data models with Codable support
- `LocationAnalysis`: Cost analysis and comparison logic

## API Integration

The app integrates with the **Amadeus Flight API** for real-time flight data:

- **Authentication**: OAuth2 with automatic token refresh
- **Rate Limiting**: Built-in request throttling to respect API limits
- **Error Handling**: Comprehensive error types and user-friendly messages
- **Data Transformation**: Converts API responses to app-specific models

## Testing

Run tests using Xcode's test navigator or from the command line:

```bash
xcodebuild test -scheme MeetingPlanner -destination "platform=iOS Simulator,name=iPhone 15 Pro"
```

The project uses Swift Testing framework for unit tests:

```swift
import Testing
@testable import MeetingPlanner

@Suite("Meeting Analysis Tests")
struct MeetingAnalysisTests {
    @Test("Location analysis calculates total costs correctly")
    func testLocationCostCalculation() async throws {
        let meeting = Meeting(name: "Test Meeting")
        let flightResults = [/* mock flight results */]
        
        let analysis = LocationAnalysis(
            location: testLocation,
            flightResults: flightResults,
            totalCost: Decimal(1000),
            averageCostPerPerson: Decimal(500),
            currency: "USD",
            totalAttendeesSearched: 2
        )
        
        #expect(analysis.attendeeCount == 2)
        #expect(analysis.averageCostPerPerson == Decimal(500))
    }
}
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/enhanced-search`)
3. Commit your changes (`git commit -m 'Add flight filtering options'`)
4. Push to the branch (`git push origin feature/enhanced-search`)
5. Open a Pull Request

Please make sure to:
- Update tests for new functionality
- Follow existing code style and patterns
- Test with sample data before requesting API calls
- Document any new API endpoints or models

## Code Style

This project follows Swift's official style guidelines and includes:

- Consistent naming conventions for models and services
- Proper use of access control (`private`, `@MainActor`, etc.)
- Swift Concurrency best practices
- SwiftUI view composition patterns

## Roadmap

- [ ] **Calendar Integration**: Sync with iOS Calendar app
- [ ] **Advanced Filtering**: Filter flights by duration, stops, airlines
- [ ] **Cost Trends**: Historical price tracking and predictions
- [ ] **Group Preferences**: Attendee preferences for airlines and travel times
- [ ] **Expense Reporting**: Export meeting costs for expense management
- [ ] **Apple Watch App**: Quick meeting overview and notifications

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **Amadeus for Developers**: Providing comprehensive flight data API
- **Apple**: SwiftUI and modern iOS development frameworks
- **IATA**: Airport code standards for global location support
- Built with ❤️ using Swift and SwiftUI

## Contact

Project Link: [https://github.com/yourusername/meeting-planner](https://github.com/yourusername/meeting-planner)

---

*Meeting Planner makes it easy to bring your team together by finding the most cost-effective meeting locations. Start planning smarter meetings today!*
