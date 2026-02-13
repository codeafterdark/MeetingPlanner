import SwiftUI

struct ReviewAndSearchView: View {
    @Binding var meeting: Meeting
    @ObservedObject var viewModel: MeetingViewModel
    @EnvironmentObject var appServices: AppServices
    @State private var showingResults = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
                    errorMessage: viewModel.errorMessage
                )
            }
        }
    }
}

struct ReviewView: View {
    let meeting: Meeting
    let estimatedCalls: Int
    let onSearch: () -> Void
    let errorMessage: String?
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
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
                    
                    ForEach(meeting.attendees) { attendee in
                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(.blue)
                            Text(attendee.displayName)
                        }
                        .padding(.horizontal)
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
                
                // Search Button
                Button(action: onSearch) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search Flights")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
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
        .environmentObject(AppServices())
    }
}