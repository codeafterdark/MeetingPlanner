import Foundation

struct Meeting: Identifiable, Codable {
    var id = UUID()
    var name: String
    var startDate: Date
    var numberOfDays: Int
    var travelBufferBefore: Int  // days before meeting
    var travelBufferAfter: Int   // days after meeting
    var potentialLocations: [Location]
    var attendees: [Attendee]
    var createdAt: Date
    
    init(
        name: String = "",
        startDate: Date = Date().addingTimeInterval(86400 * 7), // Default to 1 week from now
        numberOfDays: Int = 1,
        travelBufferBefore: Int = 1,
        travelBufferAfter: Int = 1,
        potentialLocations: [Location] = [],
        attendees: [Attendee] = []
    ) {
        self.name = name
        self.startDate = startDate
        self.numberOfDays = numberOfDays
        self.travelBufferBefore = travelBufferBefore
        self.travelBufferAfter = travelBufferAfter
        self.potentialLocations = potentialLocations
        self.attendees = attendees
        self.createdAt = Date()
    }
    
    // Computed properties
    var actualStartDate: Date {
        Calendar.current.date(byAdding: .day, value: -travelBufferBefore, to: startDate) ?? startDate
    }
    
    var actualEndDate: Date {
        let meetingEndDate = Calendar.current.date(byAdding: .day, value: numberOfDays - 1, to: startDate) ?? startDate
        return Calendar.current.date(byAdding: .day, value: travelBufferAfter, to: meetingEndDate) ?? meetingEndDate
    }
}

struct Location: Identifiable, Codable, Hashable {
    var id = UUID()
    var cityName: String
    var airportCode: String  // IATA code (e.g., "JFK", "LAX")
    var countryCode: String  // ISO country code (e.g., "US", "GB")
    
    var displayName: String {
        "\(cityName) (\(airportCode))"
    }
}

struct Attendee: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var homeAirport: String  // IATA code
    
    var displayName: String {
        "\(name) - \(homeAirport)"
    }
}

struct FlightSearchResult: Identifiable, Codable {
    var id = UUID()
    var attendee: Attendee
    var destination: Location
    var outboundFlight: FlightDetails
    var returnFlight: FlightDetails
    var totalPrice: Decimal
    var currency: String
    var searchedAt: Date
}

struct FlightDetails: Codable {
    var departureDate: Date
    var arrivalDate: Date
    var departureAirport: String
    var arrivalAirport: String
    var stops: Int
    var airline: String?
    var duration: String?  // e.g., "3h 45m"
}

struct LocationAnalysis: Identifiable {
    var id = UUID()
    var location: Location
    var flightResults: [FlightSearchResult]
    var totalCost: Decimal
    var averageCostPerPerson: Decimal
    var currency: String
    
    // Computed
    var attendeeCount: Int {
        flightResults.count
    }
}