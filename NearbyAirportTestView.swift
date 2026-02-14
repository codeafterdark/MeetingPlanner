import SwiftUI

struct NearbyAirportTestView: View {
    @Environment(AppServices.self) var appServices
    @State private var testAirport = ""
    @State private var radiusMiles = 60.0
    @State private var nearbyAirports: [NearbyAirport] = []
    @State private var isLoading = false
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Nearby Airport Search Test")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Test the nearby airport fallback functionality by entering an airport code to see what alternatives are available within the specified radius.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Search Parameters")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Airport Code:")
                                .frame(minWidth: 100, alignment: .leading)
                            TextField("e.g., SFO", text: $testAirport)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textInputAutocapitalization(.characters)
                                .onChange(of: testAirport) { newValue in
                                    testAirport = String(newValue.prefix(3)).uppercased()
                                }
                        }
                        
                        HStack {
                            Text("Radius (miles):")
                                .frame(minWidth: 100, alignment: .leading)
                            Slider(value: $radiusMiles, in: 10...200, step: 10)
                            Text("\(Int(radiusMiles))")
                                .frame(minWidth: 40)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Button(action: {
                    searchNearbyAirports()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "location.magnifyingglass")
                        }
                        Text("Search Nearby Airports")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(testAirport.count == 3 ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(testAirport.count != 3 || isLoading)
                
                if showingResults {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Results")
                            .font(.headline)
                        
                        if nearbyAirports.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "location.slash")
                                    .font(.system(size: 30))
                                    .foregroundColor(.orange)
                                
                                Text("No nearby airports found")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Try increasing the search radius or check if the airport code exists in our database.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(nearbyAirports.indices, id: \.self) { index in
                                        NearbyAirportRow(
                                            airport: nearbyAirports[index],
                                            rank: index + 1
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Airport Fallback Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func searchNearbyAirports() {
        guard testAirport.count == 3 else { return }
        
        isLoading = true
        nearbyAirports = []
        
        // Simulate the flight service search
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Use reflection to access private method (for testing purposes)
            // In a real implementation, you'd make this method public or create a dedicated test method
            self.nearbyAirports = findNearbyAirportsForTesting(
                to: testAirport,
                within: radiusMiles
            )
            
            self.isLoading = false
            self.showingResults = true
        }
    }
    
    // Duplicate of the private method from FlightSearchService for testing
    private func findNearbyAirportsForTesting(to airportCode: String, within radiusMiles: Double = 60.0) -> [NearbyAirport] {
        // Airport database (same as in FlightSearchService)
        let airportDatabase: [String: (name: String, lat: Double, lon: Double)] = [
            "ATL": ("Hartsfield-Jackson Atlanta International", 33.6407, -84.4277),
            "LAX": ("Los Angeles International", 33.9425, -118.4081),
            "ORD": ("Chicago O'Hare International", 41.9742, -87.9073),
            "DFW": ("Dallas/Fort Worth International", 32.8998, -97.0403),
            "DEN": ("Denver International", 39.8561, -104.6737),
            "JFK": ("John F. Kennedy International", 40.6413, -73.7781),
            "SFO": ("San Francisco International", 37.6213, -122.3790),
            "SEA": ("Seattle-Tacoma International", 47.4502, -122.3088),
            "LAS": ("McCarran International", 36.0840, -115.1537),
            "MCO": ("Orlando International", 28.4312, -81.3081),
            "EWR": ("Newark Liberty International", 40.6895, -74.1745),
            "CLT": ("Charlotte Douglas International", 35.2144, -80.9431),
            "PHX": ("Phoenix Sky Harbor International", 33.4484, -112.0740),
            "IAH": ("George Bush Intercontinental", 29.9902, -95.3368),
            "MIA": ("Miami International", 25.7959, -80.2870),
            "BOS": ("Logan International", 42.3656, -71.0096),
            "MSP": ("Minneapolis-Saint Paul International", 44.8848, -93.2223),
            "FLL": ("Fort Lauderdale-Hollywood International", 26.0742, -80.1506),
            "DTW": ("Detroit Metropolitan Wayne County", 42.2162, -83.3554),
            "LGA": ("LaGuardia Airport", 40.7769, -73.8740),
            "PHL": ("Philadelphia International", 39.8729, -75.2437),
            "SLC": ("Salt Lake City International", 40.7899, -111.9791),
            "DCA": ("Ronald Reagan Washington National", 38.8512, -77.0402),
            "IAD": ("Washington Dulles International", 38.9531, -77.4565),
            "SAN": ("San Diego International", 32.7338, -117.1933),
            "TPA": ("Tampa International", 27.9755, -82.5332),
            "PDX": ("Portland International", 45.5898, -122.5951),
            "STL": ("Lambert-St. Louis International", 38.7499, -90.3744),
            "HNL": ("Daniel K. Inouye International", 21.3099, -157.8581),
            "BWI": ("Baltimore-Washington International", 39.1774, -76.6684),
            "MDW": ("Chicago Midway International", 41.7868, -87.7522),
            "AUS": ("Austin-Bergstrom International", 30.1975, -97.6664),
            "BNA": ("Nashville International", 36.1245, -86.6782),
            "OAK": ("Oakland International", 37.7214, -122.2208),
            "SMF": ("Sacramento International", 38.6954, -121.5908),
            "SJC": ("San Jose International", 37.3639, -121.9289),
            "RDU": ("Raleigh-Durham International", 35.8776, -78.7875),
            "MCI": ("Kansas City International", 39.2976, -94.7139),
            "CLE": ("Cleveland Hopkins International", 41.4117, -81.8498),
            "CMH": ("John Glenn Columbus International", 39.9980, -82.8919),
            "IND": ("Indianapolis International", 39.7173, -86.2944),
            "MKE": ("Milwaukee Mitchell International", 42.9472, -87.8966),
            "MSY": ("Louis Armstrong New Orleans International", 29.9934, -90.2581),
            "RIC": ("Richmond International", 37.5052, -77.3197),
            "CVG": ("Cincinnati/Northern Kentucky International", 39.0488, -84.6678),
            "PIT": ("Pittsburgh International", 40.4915, -80.2329),
            "SAT": ("San Antonio International", 29.5337, -98.4698)
        ]
        
        guard let targetAirport = airportDatabase[airportCode.uppercased()] else {
            return []
        }
        
        let targetLat = targetAirport.lat
        let targetLon = targetAirport.lon
        
        var nearbyAirports: [NearbyAirport] = []
        
        for (code, airport) in airportDatabase {
            if code == airportCode.uppercased() {
                continue // Skip the original airport
            }
            
            let distance = calculateDistance(
                lat1: targetLat, lon1: targetLon,
                lat2: airport.lat, lon2: airport.lon
            )
            
            if distance <= radiusMiles {
                nearbyAirports.append(NearbyAirport(
                    code: code,
                    name: airport.name,
                    distance: distance,
                    coordinates: (airport.lat, airport.lon)
                ))
            }
        }
        
        // Sort by distance (closest first)
        return nearbyAirports.sorted { $0.distance < $1.distance }
    }
    
    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadiusMiles = 3959.0
        
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0
        
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) *
                sin(dLon/2) * sin(dLon/2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return earthRadiusMiles * c
    }
}

struct NearbyAirportRow: View {
    let airport: NearbyAirport
    let rank: Int
    
    var body: some View {
        HStack {
            // Rank badge
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 30, height: 30)
                
                Text("\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(airport.code)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", airport.distance)) mi")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Text(airport.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Image(systemName: "airplane")
                .foregroundColor(.blue)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct NearbyAirportTestView_Previews: PreviewProvider {
    static var previews: some View {
        NearbyAirportTestView()
            .environment(AppServices())
    }
}