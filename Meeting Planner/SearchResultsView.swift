import SwiftUI

struct SearchResultsView: View {
    let results: [LocationAnalysis]
    let meeting: Meeting
    let onStartNewSearch: () -> Void
    @Environment(AppServices.self) var appServices
    
    @State private var selectedLocation: LocationAnalysis?
    @State private var showingSaveConfirmation = false
    @State private var showingEditMeeting = false
    @State private var editableMeeting: Meeting
    
    init(results: [LocationAnalysis], meeting: Meeting, onStartNewSearch: @escaping () -> Void) {
        self.results = results
        self.meeting = meeting
        self.onStartNewSearch = onStartNewSearch
        self._editableMeeting = State(initialValue: meeting)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Search Results")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Locations ranked by total cost")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Results List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, analysis in
                        LocationResultCard(
                            analysis: analysis,
                            rank: index + 1,
                            isWinner: index == 0,
                            onTap: { selectedLocation = analysis }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: saveMeeting) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save Meeting & Results")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                HStack(spacing: 12) {
                    Button("Edit Meeting") {
                        editableMeeting = meeting
                        showingEditMeeting = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("New Search") {
                        onStartNewSearch()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }            .padding(.horizontal)
            .padding(.bottom)
        }
        .sheet(item: $selectedLocation) { analysis in
            LocationDetailView(analysis: analysis, meeting: meeting)
        }
        .sheet(isPresented: $showingEditMeeting) {
            NavigationView {
                TabView {
                    MeetingDetailsView(meeting: $editableMeeting)
                        .tabItem {
                            Label("Details", systemImage: "calendar")
                        }
                    
                    LocationsView(meeting: $editableMeeting)
                        .tabItem {
                            Label("Locations", systemImage: "location")
                        }
                    
                    AttendeesView(meeting: $editableMeeting)
                        .tabItem {
                            Label("Attendees", systemImage: "person.2")
                        }
                }
                .navigationTitle("Edit Meeting")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            editableMeeting = meeting
                            showingEditMeeting = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Search Again") {
                            showingEditMeeting = false
                            onStartNewSearch()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }

        .alert("Meeting Saved", isPresented: $showingSaveConfirmation) {
            Button("OK") { }
        } message: {
            Text("Your meeting and search results have been saved successfully.")
        }
    }
    
    private func saveMeeting() {
        appServices.meetingDataManager.saveMeeting(meeting, searchResults: results)
        showingSaveConfirmation = true
    }
}

struct LocationResultCard: View {
    let analysis: LocationAnalysis
    let rank: Int
    let isWinner: Bool
    let onTap: () -> Void
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = analysis.currency
        return formatter
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Rank Badge
                ZStack {
                    Circle()
                        .fill(isWinner ? Color.green : Color.blue)
                        .frame(width: 40, height: 40)
                    
                    Text("#\(rank)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(analysis.location.cityName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isWinner {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(analysis.location.airportCode)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if analysis.hasPartialResults {
                        Text("\(analysis.successfulFlightSearches) of \(analysis.totalAttendeesSearched) attendees")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        HStack {
                            Text("\(analysis.attendeeCount) attendee\(analysis.attendeeCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Show connecting flight indicator
                            if analysis.hasConnectionFlights {
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Image(systemName: "arrow.triangle.branch")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                Text("connections")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(currencyFormatter.string(from: analysis.totalCost as NSNumber) ?? "$0")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Total Cost")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Avg: \(currencyFormatter.string(from: analysis.averageCostPerPerson as NSNumber) ?? "$0")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(isWinner ? Color.green.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isWinner ? Color.green : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LocationDetailView: View {
    let analysis: LocationAnalysis
    let meeting: Meeting
    @Environment(\.dismiss) private var dismiss
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = analysis.currency
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Summary Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Total Cost Breakdown")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Total Cost:")
                                Spacer()
                                Text(currencyFormatter.string(from: analysis.totalCost as NSNumber) ?? "$0")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Text("Average per person:")
                                Spacer()
                                Text(currencyFormatter.string(from: analysis.averageCostPerPerson as NSNumber) ?? "$0")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Attendees with flights:")
                                Spacer()
                                if analysis.hasPartialResults {
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(analysis.successfulFlightSearches) of \(analysis.totalAttendeesSearched)")
                                            .foregroundColor(.secondary)
                                        Text("(\(analysis.missingFlightCount) missing)")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                } else {
                                    Text("\(analysis.attendeeCount) of \(analysis.totalAttendeesSearched)")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Individual Flight Results
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Individual Flights")
                            .font(.headline)
                        
                        ForEach(analysis.flightResults.sorted { $0.totalPrice < $1.totalPrice }) { result in
                            AttendeeFlightCard(result: result, currencyFormatter: currencyFormatter)
                        }
                    }
                    
                    // Missing Flights Warning (if any)
                    if analysis.hasPartialResults {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("Missing Flight Data")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                            
                            Text("No flights found for \(analysis.missingFlightCount) attendee\(analysis.missingFlightCount == 1 ? "" : "s") to this destination. This may be due to:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("• No available flights on selected dates")
                                Text("• No direct or connecting flights available")
                                Text("• Remote destinations with limited service")
                                Text("• API rate limiting or temporary issues")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Meeting Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Meeting Details")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(label: "Meeting", value: meeting.name)
                            DetailRow(label: "Departure", value: dateFormatter.string(from: meeting.actualStartDate))
                            DetailRow(label: "Return", value: dateFormatter.string(from: meeting.actualEndDate))
                            DetailRow(label: "Location", value: analysis.location.displayName)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle(analysis.location.cityName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AttendeeFlightCard: View {
    let result: FlightSearchResult
    let currencyFormatter: NumberFormatter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.attendee.name)
                    .font(.headline)
                
                Spacer()
                
                Text(currencyFormatter.string(from: result.totalPrice as NSNumber) ?? "$0")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                FlightLegView(
                    from: result.attendee.homeAirport,
                    to: result.destination.airportCode,
                    details: result.outboundFlight,
                    label: "Outbound"
                )
                
                FlightLegView(
                    from: result.destination.airportCode,
                    to: result.attendee.homeAirport,
                    details: result.returnFlight,
                    label: "Return"
                )
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .cornerRadius(8)
    }
}

struct FlightLegView: View {
    let from: String
    let to: String
    let details: FlightDetails
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("\(label):")
                    .fontWeight(.medium)
                Text("\(from) → \(to)")
                
                if let duration = details.duration {
                    Text("•")
                    Text(duration)
                }
                
                Spacer()
            }
            
            HStack {
                if let airline = details.airline {
                    Text(airline)
                        .foregroundColor(.secondary)
                }
                
                if details.stops > 0 {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("\(details.stops) stop\(details.stops == 1 ? "" : "s")")
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct SearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultsView(
            results: [
                LocationAnalysis(
                    location: Location(cityName: "San Francisco", airportCode: "SFO", countryCode: "US"),
                    flightResults: [],
                    totalCost: 1200.00,
                    averageCostPerPerson: 600.00,
                    currency: "USD",
                    totalAttendeesSearched: 2
                ),
                LocationAnalysis(
                    location: Location(cityName: "New York", airportCode: "JFK", countryCode: "US"),
                    flightResults: [],
                    totalCost: 1500.00,
                    averageCostPerPerson: 750.00,
                    currency: "USD",
                    totalAttendeesSearched: 2
                )
            ],
            meeting: Meeting(name: "Test Meeting"),
            onStartNewSearch: {}
        )
    }
}
