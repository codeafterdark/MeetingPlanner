import SwiftUI

struct ReviewAndSearchView: View {
    @Binding var meeting: Meeting
    var viewModel: MeetingViewModel
    @Environment(AppServices.self) var appServices
    @State private var showingResults = false
    
    var body: some View {
        if viewModel.isSearching {
            SearchProgressView(
                progress: viewModel.searchProgress,
                message: viewModel.progressMessage,
                onCancel: { viewModel.cancelSearch() }
            )
        } else if !viewModel.results.isEmpty {
            SearchResultsView(
                results: viewModel.results,
                meeting: meeting,
                onStartNewSearch: { 
                    viewModel.resetSearch()
                }
            )
        } else {
            ReviewView(
                meeting: meeting,
                estimatedCalls: viewModel.estimatedAPICallsCount,
                onSearch: {
                    viewModel.searchFlights(using: appServices.flightService)
                },
                errorMessage: viewModel.errorMessage,
                onSaveMeeting: {
                    appServices.meetingDataManager.saveMeeting(meeting)
                }
            )
        }
    }
}

struct ReviewView: View {
    let meeting: Meeting
    let estimatedCalls: Int
    let onSearch: () -> Void
    let errorMessage: String?
    let onSaveMeeting: () -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var estimatedSearchDuration: String {
        let searchCount = estimatedCalls
        // Each API call has a minimum 50ms delay, plus processing time
        let estimatedSeconds = Double(searchCount) * 0.1 // Conservative estimate of 100ms per call
        
        if estimatedSeconds < 60 {
            return "\(Int(estimatedSeconds)) seconds"
        } else {
            let minutes = Int(estimatedSeconds / 60)
            let remainingSeconds = Int(estimatedSeconds.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(remainingSeconds)s"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    Text("Review & Search")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    // Meeting Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Meeting Summary")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            SummaryRow(label: "Meeting Name", value: meeting.name)
                            SummaryRow(label: "Travel Dates", value: "\(dateFormatter.string(from: meeting.actualStartDate)) - \(dateFormatter.string(from: meeting.actualEndDate))")
                            SummaryRow(label: "Locations", value: "\(meeting.potentialLocations.count) cities")
                            SummaryRow(label: "Attendees", value: "\(meeting.attendees.count) people")
                            SummaryRow(label: "Estimated API Calls", value: "\(estimatedCalls)")
                            SummaryRow(label: "Estimated Duration", value: estimatedSearchDuration)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Locations List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Potential Locations")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(meeting.potentialLocations) { location in
                            HStack {
                                Image(systemName: "location")
                                    .foregroundColor(.blue)
                                Text(location.displayName)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Attendees List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Attendees")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // Debug information
                        Text("Debug: Total attendees in array: \(meeting.attendees.count)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                        
                        ForEach(meeting.attendees) { attendee in
                            HStack {
                                Image(systemName: "person")
                                    .foregroundColor(.blue)
                                Text(attendee.displayName)
                                Spacer()
                                Text("ID: \(attendee.id.uuidString.prefix(8))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Show all attendee details for debugging
                        if !meeting.attendees.isEmpty {
                            Text("Debug: All attendees:")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                            
                            ForEach(Array(meeting.attendees.enumerated()), id: \.offset) { index, attendee in
                                Text("[\(index)]: \(attendee.name) - \(attendee.homeAirport)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.red)
                                Text("Error")
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                            Text(errorMessage)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemRed).opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    // Bottom spacing to ensure button isn't hidden
                    Color.clear
                        .frame(height: 120)
                }
                .padding(.bottom, 20)
            }
            
            // Search button at bottom
            VStack(spacing: 8) {
                Text("⚠️ Flight searches are rate-limited to comply with API requirements")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 12) {
                    Button(action: {
                        onSaveMeeting()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save Meeting")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        print("Search Flights button tapped") 
                        onSearch()
                    }) {
                        HStack {
                            Image(systemName: "airplane")
                            Text("Search Flights")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                
                Text("Save your meeting details or search for flights to find the best location")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.bottom)
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 0.5),
                alignment: .top
            )
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct SearchProgressView: View {
    let progress: Double
    let message: String
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(1.2)
                
                Text(message)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text("\(Int(progress * 100))% Complete")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button("Cancel Search") {
                onCancel()
            }
            .foregroundColor(.red)
            .padding(.bottom)
        }
    }
}

struct ReviewAndSearchView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewAndSearchView(
            meeting: .constant(Meeting(
                name: "Test Meeting",
                potentialLocations: [
                    Location(cityName: "San Francisco", airportCode: "SFO", countryCode: "US"),
                    Location(cityName: "New York", airportCode: "JFK", countryCode: "US")
                ],
                attendees: [
                    Attendee(name: "John Doe", homeAirport: "LAX"),
                    Attendee(name: "Jane Smith", homeAirport: "ORD")
                ]
            )),
            viewModel: MeetingViewModel()
        )
        .environment(AppServices())
    }
}