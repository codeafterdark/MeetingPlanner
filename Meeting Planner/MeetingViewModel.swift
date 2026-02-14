import SwiftUI
import Foundation

@MainActor
@Observable
class MeetingViewModel {
    var meeting = Meeting()
    var isSearching: Bool = false
    var searchProgress: Double = 0.0
    var progressMessage: String = ""
    var results: [LocationAnalysis] = []
    var errorMessage: String?
    var shouldDismiss: Bool = false
    
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init() {
        // Default init
    }
    
    init(meeting: Meeting, searchResults: [LocationAnalysis] = []) {
        self.meeting = meeting
        self.results = searchResults
    }
    
    // MARK: - Search Management
    
    func searchFlights(using flightService: FlightSearchService) {
        guard !isSearching else { return }
        
        searchTask = Task {
            await performSearch(using: flightService)
        }
    }
    
    func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
        isSearching = false
        searchProgress = 0.0
        progressMessage = ""
    }
    
    // MARK: - Meeting Management
    
    func saveMeeting(using dataManager: MeetingDataManager) {
        dataManager.saveMeeting(meeting, searchResults: results)
    }
    
    func loadMeeting(_ meeting: Meeting, searchResults: [LocationAnalysis] = []) {
        self.meeting = meeting
        self.results = searchResults
    }
    
    private func performSearch(using flightService: FlightSearchService) async {
        isSearching = true
        errorMessage = nil
        results = []
        
        // Log optimization statistics before starting search
        let optimizationStats = flightService.getSearchOptimizationStats(for: meeting)
        print("🚀 Flight Search Optimization:")
        print(optimizationStats.summary)
        
        for group in optimizationStats.airportGroups {
            print("  📍 \(group.description)")
        }
        
        do {
            // Use the FlightSearchService's rate-limited search method with progress callback
            let allResults = try await flightService.searchAllCombinations(meeting: meeting) { progress, message in
                Task { @MainActor in
                    self.searchProgress = progress
                    self.progressMessage = message
                }
            }
            
            // Process results
            let grouped = Dictionary(grouping: allResults, by: { $0.destination.id })
            
            let analyses = grouped.compactMap { locationId, results -> LocationAnalysis? in
                guard let location = results.first?.destination else { return nil }
                
                let totalCost = results.reduce(Decimal(0)) { $0 + $1.totalPrice }
                let averageCost = results.isEmpty ? Decimal(0) : totalCost / Decimal(results.count)
                
                return LocationAnalysis(
                    location: location,
                    flightResults: results,
                    totalCost: totalCost,
                    averageCostPerPerson: averageCost,
                    currency: results.first?.currency ?? "USD",
                    totalAttendeesSearched: meeting.attendees.count
                )
            }
            
            // Sort by total cost (ascending)
            self.results = analyses.sorted { $0.totalCost < $1.totalCost }
            
            searchProgress = 1.0
            progressMessage = "Search complete! Optimization saved \(optimizationStats.apiCallsSaved) API calls (\(optimizationStats.efficiencyPercentage)% more efficient)"
            
            // Log final optimization results
            print("✅ Search completed with optimization:")
            print("  🎯 Generated \(allResults.count) flight results")
            print("  📊 Used \(optimizationStats.optimizedApiCalls) API calls instead of \(optimizationStats.standardApiCalls)")
            print("  💰 Saved \(optimizationStats.apiCallsSaved) API calls (\(optimizationStats.efficiencyPercentage)% efficiency)")
            
            // Small delay to show completion, then dismiss
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Search failed: \(error.localizedDescription)")
        }
        
        isSearching = false
    }
    
    func resetSearch() {
        results = []
        searchProgress = 0.0
        progressMessage = ""
        errorMessage = nil
    }
}

// MARK: - Validation Extensions

extension MeetingViewModel {
    var isValidForSearch: Bool {
        !meeting.name.isEmpty &&
        meeting.potentialLocations.count >= 2 &&
        meeting.attendees.count >= 1 &&
        meeting.startDate > Date()
    }
    
    var estimatedAPICallsCount: Int {
        meeting.attendees.count * meeting.potentialLocations.count
    }
    
    func getOptimizedAPICallsCount(using flightService: FlightSearchService) -> Int {
        let stats = flightService.getSearchOptimizationStats(for: meeting)
        return stats.optimizedApiCalls
    }
    
    func getAPICallsSavings(using flightService: FlightSearchService) -> (saved: Int, percentage: Int) {
        let stats = flightService.getSearchOptimizationStats(for: meeting)
        return (stats.apiCallsSaved, stats.efficiencyPercentage)
    }
}