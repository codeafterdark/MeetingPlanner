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
    
    // MARK: - Private Methods
    
    private func loadMeetings() {
        guard let data = userDefaults.data(forKey: meetingsKey),
              let meetings = try? JSONDecoder().decode([SavedMeeting].self, from: data) else {
            savedMeetings = []
            return
        }
        savedMeetings = meetings.sorted { $0.savedAt > $1.savedAt }
    }
    
    private func persistMeetings() {
        do {
            let data = try JSONEncoder().encode(savedMeetings)
            userDefaults.set(data, forKey: meetingsKey)
        } catch {
            print("Failed to save meetings: \(error)")
        }
    }
}

// MARK: - SavedMeeting Model

struct SavedMeeting: Identifiable, Codable {
    let id = UUID()
    var meeting: Meeting
    var searchResults: [LocationAnalysis]
    var savedAt: Date
    
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
        case id, location, flightResults, totalCost, averageCostPerPerson, currency
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        location = try container.decode(Location.self, forKey: .location)
        flightResults = try container.decode([FlightSearchResult].self, forKey: .flightResults)
        totalCost = try container.decode(Decimal.self, forKey: .totalCost)
        averageCostPerPerson = try container.decode(Decimal.self, forKey: .averageCostPerPerson)
        currency = try container.decode(String.self, forKey: .currency)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(location, forKey: .location)
        try container.encode(flightResults, forKey: .flightResults)
        try container.encode(totalCost, forKey: .totalCost)
        try container.encode(averageCostPerPerson, forKey: .averageCostPerPerson)
        try container.encode(currency, forKey: .currency)
    }
}