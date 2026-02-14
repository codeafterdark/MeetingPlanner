import SwiftUI

struct SearchOptimizationView: View {
    let meeting: Meeting
    let flightSearchService: FlightSearchService
    
    private var stats: SearchOptimizationStats {
        flightSearchService.getSearchOptimizationStats(for: meeting)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Search Optimization")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("API call optimization for your meeting")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Efficiency Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "speedometer")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(stats.efficiencyPercentage)% More Efficient")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Reduced API calls by \(stats.apiCallsSaved)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(stats.optimizedApiCalls)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("API calls")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
            // Comparison Card
            VStack(alignment: .leading, spacing: 16) {
                Text("API Call Comparison")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    HStack {
                        HStack {
                            Image(systemName: "minus.circle")
                                .foregroundColor(.red)
                            Text("Without optimization")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(stats.standardApiCalls) calls")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("With optimization")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(stats.optimizedApiCalls) calls")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Savings")
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("-\(stats.apiCallsSaved) calls")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Airport Groups
            VStack(alignment: .leading, spacing: 12) {
                Text("Attendee Grouping")
                    .font(.headline)
                
                Text("Attendees grouped by home airport to avoid duplicate searches")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVStack(spacing: 8) {
                    ForEach(stats.airportGroups, id: \.airport) { group in
                        AirportGroupCard(group: group)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Optimization Stats")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AirportGroupCard: View {
    let group: AirportGroup
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "airplane.departure")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text(group.airport)
                        .font(.headline)
                        .fontWeight(.medium)
                }
                
                Text("\(group.attendeeCount) attendee\(group.attendeeCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                ForEach(group.attendeeNames, id: \.self) { name in
                    Text(name)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct SearchOptimizationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchOptimizationView(
                meeting: Meeting(
                    name: "Team Meeting",
                    startDate: Date(),
                    numberOfDays: 3,
                    potentialLocations: [
                        Location(cityName: "San Francisco", airportCode: "SFO", countryCode: "US"),
                        Location(cityName: "New York", airportCode: "JFK", countryCode: "US")
                    ],
                    attendees: [
                        Attendee(name: "John Doe", homeAirport: "LAX"),
                        Attendee(name: "Jane Smith", homeAirport: "LAX"),
                        Attendee(name: "Bob Johnson", homeAirport: "ORD"),
                        Attendee(name: "Alice Brown", homeAirport: "DFW")
                    ]
                ),
                flightSearchService: FlightSearchService(apiKey: "", apiSecret: "")
            )
        }
    }
}