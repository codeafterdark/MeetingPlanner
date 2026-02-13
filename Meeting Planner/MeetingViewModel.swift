import SwiftUI
import Foundation

@MainActor
class MeetingViewModel: ObservableObject {
    @Published var meeting = Meeting()
    @Published var isSearching: Bool = false
    @Published var searchProgress: Double = 0.0
    @Published var progressMessage: String = ""
    @Published var results: [LocationAnalysis] = []
    @Published var errorMessage: String?
    @Published var shouldDismiss: Bool = false
    
    private var searchTask: Task<Void, Never>?
    
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
    
    private func performSearch(using flightService: FlightSearchService) async {
        isSearching = true
        errorMessage = nil
        results = []
        
        let totalSearches = meeting.attendees.count * meeting.potentialLocations.count
        var completedSearches = 0
        
        do {
            var allResults: [FlightSearchResult] = []
            
            for attendee in meeting.attendees {
                for location in meeting.potentialLocations {
                    guard !Task.isCancelled else {
                        isSearching = false
                        return
                    }
                    
                    // Update progress
                    let progress = Double(completedSearches) / Double(totalSearches)
                    searchProgress = progress
                    progressMessage = "Searching \(attendee.homeAirport) → \(location.airportCode)..."
                    
                    do {
                        let offers = try await flightService.searchFlights(
                            from: attendee.homeAirport,
                            to: location.airportCode,
                            departureDate: meeting.actualStartDate,
                            returnDate: meeting.actualEndDate
                        )
                        
                        if let cheapest = offers.first {
                            let result = FlightSearchResult(
                                attendee: attendee,
                                destination: location,
                                outboundFlight: FlightDetails(
                                    departureDate: meeting.actualStartDate,
                                    arrivalDate: meeting.actualStartDate,
                                    departureAirport: attendee.homeAirport,
                                    arrivalAirport: location.airportCode,
                                    stops: max(0, (cheapest.itineraries.first?.segments.count ?? 1) - 1),
                                    airline: cheapest.itineraries.first?.segments.first?.carrierCode,
                                    duration: cheapest.itineraries.first?.duration
                                ),
                                returnFlight: FlightDetails(
                                    departureDate: meeting.actualEndDate,
                                    arrivalDate: meeting.actualEndDate,
                                    departureAirport: location.airportCode,
                                    arrivalAirport: attendee.homeAirport,
                                    stops: 0,
                                    airline: nil,
                                    duration: nil
                                ),
                                totalPrice: Decimal(string: cheapest.price.total) ?? 0,
                                currency: cheapest.price.currency,
                                searchedAt: Date()
                            )
                            allResults.append(result)
                        }
                    } catch {
                        print("Search failed for \(attendee.name) to \(location.cityName): \(error)")
                        // Continue with other searches
                    }
                    
                    completedSearches += 1
                    
                    // Rate limiting delay
                    try? await Task.sleep(nanoseconds: 500_000_000)
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
                    currency: results.first?.currency ?? "USD"
                )
            }
            
            // Sort by total cost (ascending)
            self.results = analyses.sorted { $0.totalCost < $1.totalCost }
            
            searchProgress = 1.0
            progressMessage = "Search complete!"
            
            // Small delay to show completion, then dismiss
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
        } catch {
            errorMessage = error.localizedDescription
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
}