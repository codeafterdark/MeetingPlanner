import Foundation
import SwiftUI

@MainActor
@Observable
class MeetingDataManager {
    private let userDefaults = UserDefaults.standard
    private let meetingsKey = "SavedMeetings"
    
    var savedMeetings: [SavedMeeting] = []
    
    init() {
        loadMeetings()
    }
    
    // MARK: - Save Meeting
    
    func saveMeeting(_ meeting: Meeting, searchResults: [LocationAnalysis] = []) {
        let savedMeeting = SavedMeeting(
            meeting: meeting,
            searchResults: searchResults,
            savedAt: Date()
        )
        
        savedMeetings.append(savedMeeting)
        print("💼 Saving meeting: \(meeting.name), total meetings: \(savedMeetings.count)")
        persistMeetings()
    }
    
    // MARK: - Delete Meeting
    
    func deleteMeeting(withId id: UUID) {
        savedMeetings.removeAll { $0.id == id }
        persistMeetings()
    }
    
    func deleteMeetings(at offsets: IndexSet) {
        savedMeetings.remove(atOffsets: offsets)
        persistMeetings()
    }
    
    // MARK: - Load Meeting
    
    func loadMeeting(withId id: UUID) -> SavedMeeting? {
        return savedMeetings.first { $0.id == id }
    }
    
    // MARK: - Update Meeting
    
    func updateMeeting(_ savedMeeting: SavedMeeting) {
        if let index = savedMeetings.firstIndex(where: { $0.id == savedMeeting.id }) {
            savedMeetings[index] = savedMeeting
            persistMeetings()
        }
    }
    
    // MARK: - Sample Data
    
    func createSampleMeeting() {
        // Create sample locations
        let locations = [
            Location(cityName: "New York", airportCode: "JFK", countryCode: "US"),
            Location(cityName: "San Francisco", airportCode: "SFO", countryCode: "US"),
            Location(cityName: "London", airportCode: "LHR", countryCode: "GB")
        ]
        
        // Create sample attendees
        let attendees = [
            Attendee(name: "Alice Johnson", homeAirport: "LAX"),
            Attendee(name: "Bob Smith", homeAirport: "ORD"),
            Attendee(name: "Charlie Brown", homeAirport: "ATL"),
            Attendee(name: "Diana Prince", homeAirport: "DEN")
        ]
        
        // Create sample meeting
        let sampleMeeting = Meeting(
            name: "Q1 Strategy Meeting",
            startDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
            numberOfDays: 3,
            travelBufferBefore: 1,
            travelBufferAfter: 1,
            potentialLocations: locations,
            attendees: attendees
        )
        
        // Create some sample search results
        let sampleSearchResults: [LocationAnalysis] = locations.map { location in
            let flightResults = attendees.map { attendee in
                FlightSearchResult(
                    attendee: attendee,
                    destination: location,
                    outboundFlight: FlightDetails(
                        departureDate: sampleMeeting.actualStartDate,
                        arrivalDate: Calendar.current.date(byAdding: .hour, value: 4, to: sampleMeeting.actualStartDate) ?? sampleMeeting.actualStartDate,
                        departureAirport: attendee.homeAirport,
                        arrivalAirport: location.airportCode,
                        stops: 0,
                        airline: "Sample Airlines",
                        duration: "4h 0m"
                    ),
                    returnFlight: FlightDetails(
                        departureDate: sampleMeeting.actualEndDate,
                        arrivalDate: Calendar.current.date(byAdding: .hour, value: 4, to: sampleMeeting.actualEndDate) ?? sampleMeeting.actualEndDate,
                        departureAirport: location.airportCode,
                        arrivalAirport: attendee.homeAirport,
                        stops: 0,
                        airline: "Sample Airlines",
                        duration: "4h 0m"
                    ),
                    totalPrice: Decimal(Double.random(in: 300...800)),
                    currency: "USD",
                    searchedAt: Date()
                )
            }
            
            let totalCost = flightResults.reduce(Decimal(0)) { $0 + $1.totalPrice }
            let averageCost = totalCost / Decimal(flightResults.count)
            
            return LocationAnalysis(
                location: location,
                flightResults: flightResults,
                totalCost: totalCost,
                averageCostPerPerson: averageCost,
                currency: "USD",
                totalAttendeesSearched: attendees.count
            )
        }
        
        saveMeeting(sampleMeeting, searchResults: sampleSearchResults)
    }
    
    // MARK: - Private Methods
    
    private func loadMeetings() {
        guard let data = userDefaults.data(forKey: meetingsKey),
              let meetings = try? JSONDecoder().decode([SavedMeeting].self, from: data) else {
            print("🔍 No saved meetings found or failed to decode")
            savedMeetings = []
            return
        }
        savedMeetings = meetings.sorted { $0.savedAt > $1.savedAt }
        print("📊 Loaded \(savedMeetings.count) saved meetings")
    }
    
    private func persistMeetings() {
        do {
            let data = try JSONEncoder().encode(savedMeetings)
            userDefaults.set(data, forKey: meetingsKey)
            print("💾 Persisted \(savedMeetings.count) meetings")
        } catch {
            print("Failed to save meetings: \(error)")
        }
    }
}

// MARK: - SavedMeeting Model

struct SavedMeeting: Identifiable, Codable {
    let id: UUID
    var meeting: Meeting
    var searchResults: [LocationAnalysis]
    var savedAt: Date
    
    init(meeting: Meeting, searchResults: [LocationAnalysis], savedAt: Date) {
        self.id = UUID()
        self.meeting = meeting
        self.searchResults = searchResults
        self.savedAt = savedAt
    }
    
    var hasSearchResults: Bool {
        !searchResults.isEmpty
    }
    
    var bestLocation: LocationAnalysis? {
        searchResults.min { $0.totalCost < $1.totalCost }
    }
}

// Make LocationAnalysis Codable for persistence
extension LocationAnalysis: Codable {
    enum CodingKeys: String, CodingKey {
        case id, location, flightResults, totalCost, averageCostPerPerson, currency, totalAttendeesSearched
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        location = try container.decode(Location.self, forKey: .location)
        flightResults = try container.decode([FlightSearchResult].self, forKey: .flightResults)
        totalCost = try container.decode(Decimal.self, forKey: .totalCost)
        averageCostPerPerson = try container.decode(Decimal.self, forKey: .averageCostPerPerson)
        currency = try container.decode(String.self, forKey: .currency)
        totalAttendeesSearched = try container.decode(Int.self, forKey: .totalAttendeesSearched)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(location, forKey: .location)
        try container.encode(flightResults, forKey: .flightResults)
        try container.encode(totalCost, forKey: .totalCost)
        try container.encode(averageCostPerPerson, forKey: .averageCostPerPerson)
        try container.encode(currency, forKey: .currency)
        try container.encode(totalAttendeesSearched, forKey: .totalAttendeesSearched)
    }
}