import SwiftUI

struct NearbyAirportExamplesView: View {
    let examples: [AirportExample] = [
        AirportExample(
            primaryAirport: "SJC",
            primaryName: "San Jose International",
            region: "San Francisco Bay Area",
            nearbyAirports: [
                ("OAK", "Oakland International", 28.2),
                ("SFO", "San Francisco International", 34.8)
            ],
            description: "Silicon Valley travelers can use Oakland or SFO as alternatives to San Jose when direct flights aren't available."
        ),
        AirportExample(
            primaryAirport: "LGA",
            primaryName: "LaGuardia Airport",
            region: "New York Area",
            nearbyAirports: [
                ("JFK", "John F. Kennedy International", 14.8),
                ("EWR", "Newark Liberty International", 17.5)
            ],
            description: "Manhattan-based attendees have three major airport options within easy reach."
        ),
        AirportExample(
            primaryAirport: "DCA",
            primaryName: "Ronald Reagan National",
            region: "Washington D.C. Area",
            nearbyAirports: [
                ("IAD", "Washington Dulles International", 28.1),
                ("BWI", "Baltimore-Washington International", 44.7)
            ],
            description: "D.C. area has excellent airport coverage with three major options."
        ),
        AirportExample(
            primaryAirport: "MDW",
            primaryName: "Chicago Midway International",
            region: "Chicago Area",
            nearbyAirports: [
                ("ORD", "Chicago O'Hare International", 17.3)
            ],
            description: "Chicago travelers benefit from having both Midway and O'Hare as options."
        ),
        AirportExample(
            primaryAirport: "BUR",
            primaryName: "Hollywood Burbank Airport",
            region: "Los Angeles Area",
            nearbyAirports: [
                ("LAX", "Los Angeles International", 35.2)
            ],
            description: "Burbank offers a smaller airport experience with LAX as a major hub fallback."
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nearby Airport Examples")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Real-world examples of how the nearby airport fallback system works in major metropolitan areas.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    LazyVStack(spacing: 16) {
                        ForEach(examples, id: \.primaryAirport) { example in
                            AirportExampleCard(example: example)
                        }
                    }
                    .padding(.horizontal)
                    
                    // How it works section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How It Works")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            StepCard(
                                step: 1,
                                title: "Original Search",
                                description: "System attempts to find flights from the attendee's preferred airport",
                                icon: "airplane.departure",
                                color: .blue
                            )
                            
                            StepCard(
                                step: 2,
                                title: "Nearby Search",
                                description: "If no flights found, searches airports within 60 miles automatically",
                                icon: "location.magnifyingglass",
                                color: .orange
                            )
                            
                            StepCard(
                                step: 3,
                                title: "Best Option",
                                description: "Returns flights from the closest alternative airport with available routes",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    Color.clear.frame(height: 20) // Bottom padding
                }
            }
            .navigationTitle("Airport Fallback Examples")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AirportExampleCard: View {
    let example: AirportExample
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(example.region)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(example.nearbyAirports.count + 1) airports")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                
                Text(example.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Primary Airport
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("PRIMARY")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                    
                    Text(example.primaryAirport)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(example.primaryName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "airplane")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Nearby Airports
            if !example.nearbyAirports.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "location.circle")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("NEARBY ALTERNATIVES")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    
                    VStack(spacing: 6) {
                        ForEach(example.nearbyAirports.indices, id: \.self) { index in
                            let airport = example.nearbyAirports[index]
                            HStack {
                                Text(airport.0)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                                    .frame(minWidth: 40)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(airport.1)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                    
                                    Text("\(String(format: "%.1f", airport.2)) miles away")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right.circle")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct StepCard: View {
    let step: Int
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            // Step number
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                
                Text("\(step)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct AirportExample {
    let primaryAirport: String
    let primaryName: String
    let region: String
    let nearbyAirports: [(String, String, Double)] // code, name, distance
    let description: String
}

struct NearbyAirportExamplesView_Previews: PreviewProvider {
    static var previews: some View {
        NearbyAirportExamplesView()
    }
}