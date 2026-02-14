import Foundation
import SwiftUI
import Combine

struct FlightOffer: Codable {
    let id: String
    let price: FlightPrice
    let itineraries: [Itinerary]
}

struct FlightPrice: Codable {
    let total: String
    let currency: String
}

struct Itinerary: Codable {
    let duration: String
    let segments: [FlightSegment]
}

struct FlightSegment: Codable {
    let departure: FlightPoint
    let arrival: FlightPoint
    let carrierCode: String
    let number: String
}

struct FlightPoint: Codable {
    let iataCode: String
    let at: String
}

struct AmadeusAuthResponse: Codable {
    let access_token: String
    let expires_in: Int
    let token_type: String
}

struct AmadeusFlightResponse: Codable {
    let data: [FlightOffer]
}

// MARK: - Airport Proximity Models

struct NearbyAirport {
    let code: String
    let name: String
    let distance: Double // in miles
    let coordinates: (latitude: Double, longitude: Double)
}

struct AlternativeFlightResult {
    let originalAirport: String
    let alternativeAirport: String
    let distance: Double // miles from original airport
    let flightOffers: [FlightOffer]
}

// Airport database with coordinates (major US airports)
private let airportDatabase: [String: (name: String, lat: Double, lon: Double)] = [
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
    "LGW": ("London Gatwick", 51.1537, -0.1821),
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
    "SAT": ("San Antonio International", 29.5337, -98.4698),
    // International airports
    "LHR": ("London Heathrow", 51.4700, -0.4543),
    "CDG": ("Charles de Gaulle", 49.0097, 2.5479),
    "FRA": ("Frankfurt am Main", 50.0379, 8.5622),
    "AMS": ("Amsterdam Schiphol", 52.3105, 4.7683),
    "MAD": ("Madrid-Barajas", 40.4839, -3.5680),
    "FCO": ("Rome Fiumicino", 41.8003, 12.2389),
    "MUC": ("Munich", 48.3538, 11.7861),
    "ZUR": ("Zurich", 47.4647, 8.5492),
    "VIE": ("Vienna International", 48.1103, 16.5697),
    "CPH": ("Copenhagen", 55.6181, 12.6506),
    "ARN": ("Stockholm Arlanda", 59.6519, 17.9186),
    "OSL": ("Oslo", 60.1939, 11.1004),
    "HEL": ("Helsinki", 60.3172, 24.9633),
    "YYZ": ("Toronto Pearson", 43.6777, -79.6248),
    "YVR": ("Vancouver International", 49.1967, -123.1815),
    "NRT": ("Tokyo Narita", 35.7653, 140.3864),
    "ICN": ("Seoul Incheon", 37.4602, 126.4407),
    "SIN": ("Singapore Changi", 1.3644, 103.9915),
    "HKG": ("Hong Kong International", 22.3080, 113.9185),
    "SYD": ("Sydney Kingsford Smith", -33.9399, 151.1753),
    "MEL": ("Melbourne", -37.6690, 144.8410)
]

@MainActor
class FlightSearchService: ObservableObject {
    private let apiKey: String
    private let apiSecret: String
    private var accessToken: String?
    private var tokenExpiresAt: Date?
    
    @Published var isSearching = false
    @Published var lastError: FlightSearchError?
    
    // Rate limiting properties
    private var lastRequestTime: Date = Date.distantPast
    private var requestQueue = DispatchQueue(label: "flight-search-rate-limiter", qos: .userInitiated)
    private let minRequestInterval: TimeInterval = 0.05 // 50ms minimum between requests
    
    nonisolated let objectWillChange = ObservableObjectPublisher()
    
    init(apiKey: String, apiSecret: String) {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
    }
    
    // MARK: - Nearby Airport Search
    
    private func findNearbyAirports(to airportCode: String, within radiusMiles: Double = 60.0) -> [NearbyAirport] {
        guard let targetAirport = airportDatabase[airportCode.uppercased()] else {
            print("⚠️ Airport '\(airportCode)' not found in database")
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
    
    // MARK: - Enhanced Flight Search with Nearby Airports
    
    func searchFlightsWithNearbyFallback(
        from origin: String,
        to destination: String,
        departureDate: Date,
        returnDate: Date
    ) async throws -> AlternativeFlightResult? {
        print("🔍 Starting enhanced search from \(origin) to \(destination)")
        
        // First, try the original airport
        do {
            let offers = try await searchFlightsWithFallback(
                from: origin,
                to: destination,
                departureDate: departureDate,
                returnDate: returnDate
            )
            
            if !offers.isEmpty {
                print("✅ Found flights from original airport \(origin)")
                return AlternativeFlightResult(
                    originalAirport: origin,
                    alternativeAirport: origin,
                    distance: 0.0,
                    flightOffers: offers
                )
            }
        } catch {
            print("❌ Failed to search from original airport \(origin): \(error)")
        }
        
        // If no flights found, search nearby airports
        print("🔍 No flights from \(origin), searching nearby airports...")
        let nearbyAirports = findNearbyAirports(to: origin, within: 60.0)
        
        if nearbyAirports.isEmpty {
            print("⚠️ No nearby airports found within 60 miles of \(origin)")
            return nil
        }
        
        print("📍 Found \(nearbyAirports.count) nearby airports:")
        for airport in nearbyAirports.prefix(5) {
            print("  • \(airport.code) - \(airport.name) (\(String(format: "%.1f", airport.distance)) miles)")
        }
        
        // Try each nearby airport until we find flights
        for nearbyAirport in nearbyAirports {
            print("🛫 Trying alternative airport: \(nearbyAirport.code) (\(String(format: "%.1f", nearbyAirport.distance)) miles from \(origin))")
            
            do {
                let offers = try await searchFlightsWithFallback(
                    from: nearbyAirport.code,
                    to: destination,
                    departureDate: departureDate,
                    returnDate: returnDate
                )
                
                if !offers.isEmpty {
                    print("✅ Found \(offers.count) flights from alternative airport \(nearbyAirport.code)")
                    return AlternativeFlightResult(
                        originalAirport: origin,
                        alternativeAirport: nearbyAirport.code,
                        distance: nearbyAirport.distance,
                        flightOffers: offers
                    )
                } else {
                    print("❌ No flights found from \(nearbyAirport.code)")
                }
            } catch {
                print("❌ Failed to search from \(nearbyAirport.code): \(error)")
                // Continue to next airport
            }
            
            // Add small delay between attempts to respect rate limits
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        print("❌ No flights found from \(origin) or any nearby airports within 60 miles")
        return nil
    }
    
    // MARK: - Rate Limiting
    
    private func enforceRateLimit() async {
        let now = Date()
        let timeSinceLastRequest = now.timeIntervalSince(lastRequestTime)
        
        if timeSinceLastRequest < minRequestInterval {
            let delay = minRequestInterval - timeSinceLastRequest
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        lastRequestTime = Date()
    }
    
    // MARK: - Authentication
    
    func authenticate() async throws -> String {
        // Check if we have a valid token
        if let token = accessToken,
           let expiresAt = tokenExpiresAt,
           expiresAt > Date().addingTimeInterval(60) { // 1 minute buffer
            return token
        }
        
        // Apply rate limiting before making the request
        await enforceRateLimit()
        
        let url = URL(string: "\(Config.amadeusBaseURL)/v1/security/oauth2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyData = "grant_type=client_credentials&client_id=\(apiKey)&client_secret=\(apiSecret)"
        request.httpBody = bodyData.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FlightSearchError.authenticationFailed
        }
        
        let authResponse = try JSONDecoder().decode(AmadeusAuthResponse.self, from: data)
        
        self.accessToken = authResponse.access_token
        self.tokenExpiresAt = Date().addingTimeInterval(TimeInterval(authResponse.expires_in))
        
        return authResponse.access_token
    }
    
    // MARK: - Flight Search
    
    func searchFlights(
        from origin: String,
        to destination: String,
        departureDate: Date,
        returnDate: Date
    ) async throws -> [FlightOffer] {
        isSearching = true
        lastError = nil
        
        defer {
            isSearching = false
        }
        
        print("🔐 Getting authentication token...")
        
        // Get authentication token (with rate limiting if needed)
        let token = try await authenticate()
        
        print("✅ Authentication successful")
        
        // Apply rate limiting before making the search request
        await enforceRateLimit()
        
        print("⏱️ Rate limit enforced, making API request...")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var urlComponents = URLComponents(string: "\(Config.amadeusBaseURL)/v2/shopping/flight-offers")!
        urlComponents.queryItems = [
            URLQueryItem(name: "originLocationCode", value: origin),
            URLQueryItem(name: "destinationLocationCode", value: destination),
            URLQueryItem(name: "departureDate", value: dateFormatter.string(from: departureDate)),
            URLQueryItem(name: "returnDate", value: dateFormatter.string(from: returnDate)),
            URLQueryItem(name: "adults", value: "1"),
            URLQueryItem(name: "currencyCode", value: "USD"),
            URLQueryItem(name: "max", value: "10"), // Increased to get more options including connections
            URLQueryItem(name: "nonStop", value: "false"), // Explicitly allow connecting flights
            URLQueryItem(name: "maxPrice", value: "10000") // Set a reasonable max price to avoid extremely expensive options
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🌐 Making API request to: \(urlComponents.url?.absoluteString ?? "unknown")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw FlightSearchError.networkError
        }
        
        print("📨 HTTP Response: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200:
            print("✅ API request successful")
            let flightResponse = try JSONDecoder().decode(AmadeusFlightResponse.self, from: data)
            print("📊 Found \(flightResponse.data.count) flight offers")
            return flightResponse.data
        case 400:
            print("❌ Bad request (400) - Invalid parameters")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response body: \(responseString)")
            }
            let error = FlightSearchError.invalidRequest
            lastError = error
            throw error
        case 401:
            print("❌ Unauthorized (401) - Authentication failed")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response body: \(responseString)")
            }
            let error = FlightSearchError.authenticationFailed
            lastError = error
            throw error
        case 429:
            print("❌ Rate limit exceeded (429)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response body: \(responseString)")
            }
            let error = FlightSearchError.rateLimitExceeded
            lastError = error
            throw error
        default:
            print("❌ Unexpected status code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response body: \(responseString)")
            }
            let error = FlightSearchError.networkError
            lastError = error
            throw error
        }
    }
    
    // MARK: - Connecting Flight Search
    
    func searchFlightsWithFallback(
        from origin: String,
        to destination: String,
        departureDate: Date,
        returnDate: Date
    ) async throws -> [FlightOffer] {
        // First, try the regular search (which already allows connections)
        let offers = try await searchFlights(
            from: origin,
            to: destination,
            departureDate: departureDate,
            returnDate: returnDate
        )
        
        // If we got results, return them
        if !offers.isEmpty {
            return offers
        }
        
        // If no results, try searching with more flexible parameters
        print("🔄 No direct flights found, trying with more flexible search...")
        
        return try await searchFlightsWithMoreFlexibility(
            from: origin,
            to: destination,
            departureDate: departureDate,
            returnDate: returnDate
        )
    }
    
    private func searchFlightsWithMoreFlexibility(
        from origin: String,
        to destination: String,
        departureDate: Date,
        returnDate: Date
    ) async throws -> [FlightOffer] {
        // Apply rate limiting before making the search request
        await enforceRateLimit()
        
        // Get authentication token
        let token = try await authenticate()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var urlComponents = URLComponents(string: "\(Config.amadeusBaseURL)/v2/shopping/flight-offers")!
        urlComponents.queryItems = [
            URLQueryItem(name: "originLocationCode", value: origin),
            URLQueryItem(name: "destinationLocationCode", value: destination),
            URLQueryItem(name: "departureDate", value: dateFormatter.string(from: departureDate)),
            URLQueryItem(name: "returnDate", value: dateFormatter.string(from: returnDate)),
            URLQueryItem(name: "adults", value: "1"),
            URLQueryItem(name: "currencyCode", value: "USD"),
            URLQueryItem(name: "max", value: "20"), // More results
            URLQueryItem(name: "nonStop", value: "false"), // Allow connections
            URLQueryItem(name: "maxPrice", value: "15000"), // Higher max price
            URLQueryItem(name: "travelClass", value: "ECONOMY") // Specify economy to get more options
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🌐 Making flexible API request to: \(urlComponents.url?.absoluteString ?? "unknown")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FlightSearchError.networkError
        }
        
        switch httpResponse.statusCode {
        case 200:
            let flightResponse = try JSONDecoder().decode(AmadeusFlightResponse.self, from: data)
            print("📊 Flexible search found \(flightResponse.data.count) flight offers")
            return flightResponse.data
        case 400:
            throw FlightSearchError.invalidRequest
        case 401:
            throw FlightSearchError.authenticationFailed
        case 429:
            throw FlightSearchError.rateLimitExceeded
        default:
            throw FlightSearchError.networkError
        }
    }
    
    // MARK: - Search All Combinations (Optimized)
    
    func searchAllCombinations(meeting: Meeting, progressCallback: @escaping (Double, String) -> Void) async throws -> [FlightSearchResult] {
        isSearching = true
        lastError = nil
        
        defer {
            isSearching = false
        }
        
        var allResults: [FlightSearchResult] = []
        
        // Group attendees by home airport to avoid duplicate API calls
        let attendeesByAirport = Dictionary(grouping: meeting.attendees) { attendee in
            attendee.homeAirport.uppercased()
        }
        
        // Create a cache to store flight search results and alternative airport info by route (origin-destination)
        var flightCache: [String: [FlightOffer]] = [:]
        var alternativeAirportCache: [String: AlternativeFlightResult] = [:]
        
        let uniqueRoutes = attendeesByAirport.keys.count * meeting.potentialLocations.count
        let totalAttendees = meeting.attendees.count
        let totalPossibleResults = totalAttendees * meeting.potentialLocations.count
        
        var completedRoutes = 0
        var processedAttendeeResults = 0
        
        print("🔍 Optimized search starting:")
        print("  📊 \(meeting.attendees.count) attendees from \(attendeesByAirport.keys.count) unique airports")
        print("  📍 \(meeting.potentialLocations.count) potential locations")
        print("  🚀 Making \(uniqueRoutes) API calls instead of \(totalPossibleResults)")
        print("  💰 Estimated savings: \(totalPossibleResults - uniqueRoutes) API calls (\(Int(Double(totalPossibleResults - uniqueRoutes) / Double(totalPossibleResults) * 100))%)")
        
        // First, perform unique API searches grouped by airport
        for (homeAirport, attendeesFromAirport) in attendeesByAirport {
            print("✈️  Processing airport \(homeAirport) (\(attendeesFromAirport.count) attendees: \(attendeesFromAirport.map(\.name).joined(separator: ", ")))")
            
            // Validate home airport data
            guard !homeAirport.isEmpty, homeAirport.count == 3 else {
                print("  ⚠️ Invalid home airport code: '\(homeAirport)'")
                completedRoutes += meeting.potentialLocations.count
                processedAttendeeResults += attendeesFromAirport.count * meeting.potentialLocations.count
                continue
            }
            
            for (locationIndex, location) in meeting.potentialLocations.enumerated() {
                print("  📍 Searching route \(locationIndex + 1)/\(meeting.potentialLocations.count): \(homeAirport) → \(location.cityName) (\(location.airportCode))")
                
                // Validate location data
                guard !location.airportCode.isEmpty, location.airportCode.count == 3 else {
                    print("    ⚠️ Invalid airport code: '\(location.airportCode)' for \(location.cityName)")
                    completedRoutes += 1
                    processedAttendeeResults += attendeesFromAirport.count
                    continue
                }
                
                // Skip if same airport (no point searching from/to same place)
                if homeAirport == location.airportCode.uppercased() {
                    print("    ⚠️ Skipping search - same airport: \(homeAirport)")
                    completedRoutes += 1
                    processedAttendeeResults += attendeesFromAirport.count
                    continue
                }
                
                let routeKey = "\(homeAirport)-\(location.airportCode.uppercased())"
                
                do {
                    // Update progress for route search
                    let routeProgress = Double(completedRoutes) / Double(uniqueRoutes) * 0.7 // Use 70% of progress for API calls
                    let message = "Searching route \(homeAirport) → \(location.cityName) (affects \(attendeesFromAirport.count) attendees)"
                    await MainActor.run {
                        progressCallback(routeProgress, message)
                    }
                    
                    print("    🛫 Making API call: \(homeAirport) → \(location.airportCode)")
                    
                    // Try enhanced search with nearby airport fallback
                    let alternativeResult = try await searchFlightsWithNearbyFallback(
                        from: homeAirport,
                        to: location.airportCode,
                        departureDate: meeting.actualStartDate,
                        returnDate: meeting.actualEndDate
                    )
                    
                    if let result = alternativeResult {
                        let offers = result.flightOffers
                        print("    ✅ API call successful, found \(offers.count) offers")
                        
                        // Store the flight offers and alternative airport info in cache
                        flightCache[routeKey] = offers
                        alternativeAirportCache[routeKey] = result
                        
                        // Log if an alternative airport was used
                        if result.alternativeAirport != result.originalAirport {
                            print("    🔄 Used alternative airport: \(result.alternativeAirport) (\(String(format: "%.1f", result.distance)) miles from \(result.originalAirport))")
                        }
                        
                        // Log connection details for the cheapest option
                        if let cheapest = offers.first {
                            if let outbound = cheapest.itineraries.first {
                                let stops = max(0, outbound.segments.count - 1)
                                print("    💰 Best option: $\(cheapest.price.total) with \(stops) stop\(stops == 1 ? "" : "s")")
                                
                                if stops > 0 {
                                    let connections = outbound.segments.map { $0.departure.iataCode + "→" + $0.arrival.iataCode }.joined(separator: ", ")
                                    print("      🔄 Connection route: \(connections)")
                                }
                            }
                        }
                    } else {
                        print("    ❌ No flights found from \(homeAirport) or nearby airports")
                        flightCache[routeKey] = [] // Cache empty results
                        alternativeAirportCache[routeKey] = AlternativeFlightResult(
                            originalAirport: homeAirport,
                            alternativeAirport: homeAirport,
                            distance: 0.0,
                            flightOffers: []
                        )
                    }
                    
                    completedRoutes += 1
                    print("    ✅ Completed route search \(completedRoutes)/\(uniqueRoutes)")
                    
                } catch FlightSearchError.rateLimitExceeded {
                    print("    🚫 Rate limit exceeded, waiting before retry...")
                    // If we hit rate limit, wait a bit longer and retry
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    
                    // Retry once
                    do {
                        print("    🔄 Retrying API call: \(homeAirport) → \(location.airportCode)")
                        
                        let alternativeResult = try await searchFlightsWithNearbyFallback(
                            from: homeAirport,
                            to: location.airportCode,
                            departureDate: meeting.actualStartDate,
                            returnDate: meeting.actualEndDate
                        )
                        
                        if let result = alternativeResult {
                            let offers = result.flightOffers
                            flightCache[routeKey] = offers
                            alternativeAirportCache[routeKey] = result
                            
                            if result.alternativeAirport != result.originalAirport {
                                print("    🔄 Retry successful using alternative airport: \(result.alternativeAirport) (\(String(format: "%.1f", result.distance)) miles)")
                            }
                            
                            if let cheapest = offers.first {
                                if let outbound = cheapest.itineraries.first {
                                    let stops = max(0, outbound.segments.count - 1)
                                    print("    ✅ Retry successful, best option: $\(cheapest.price.total) with \(stops) stop\(stops == 1 ? "" : "s")")
                                }
                            }
                        } else {
                            print("    ❌ Retry failed: No flights found from \(homeAirport) or nearby airports")
                            flightCache[routeKey] = []
                            alternativeAirportCache[routeKey] = AlternativeFlightResult(
                                originalAirport: homeAirport,
                                alternativeAirport: homeAirport,
                                distance: 0.0,
                                flightOffers: []
                            )
                        }
                        
                        completedRoutes += 1
                        print("    ✅ Completed route search \(completedRoutes)/\(uniqueRoutes) (after retry)")
                    } catch {
                        print("    ❌ Failed to search route \(homeAirport) → \(location.cityName) after retry: \(error)")
                        flightCache[routeKey] = [] // Cache empty results to avoid re-attempting
                        alternativeAirportCache[routeKey] = AlternativeFlightResult(
                            originalAirport: homeAirport,
                            alternativeAirport: homeAirport,
                            distance: 0.0,
                            flightOffers: []
                        )
                        completedRoutes += 1
                        // Continue with other searches even if one fails
                    }
                } catch {
                    print("    ❌ Failed to search route \(homeAirport) → \(location.cityName): \(error)")
                    print("    📋 Error details: \(error.localizedDescription)")
                    if let flightError = error as? FlightSearchError {
                        print("    🏷️ Flight error type: \(flightError)")
                        
                        // Check if this is a fatal error that should stop the search
                        switch flightError {
                        case .authenticationFailed:
                            print("    🚨 Authentication failed - this might affect subsequent searches")
                            // Continue for now, but log it as a potential issue
                        case .rateLimitExceeded:
                            print("    🚨 Rate limit exceeded - adding extra delay")
                            // Add extra delay to help with rate limiting
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second extra
                        default:
                            break
                        }
                    }
                    flightCache[routeKey] = [] // Cache empty results to avoid re-attempting
                    alternativeAirportCache[routeKey] = AlternativeFlightResult(
                        originalAirport: homeAirport,
                        alternativeAirport: homeAirport,
                        distance: 0.0,
                        flightOffers: []
                    )
                    completedRoutes += 1
                    // Continue with other searches even if one fails
                }
            }
            print("  ✅ Completed all routes from \(homeAirport)")
        }
        
        print("🎯 API search phase complete! Now processing results for individual attendees...")
        
        // Second phase: Apply cached results to all attendees
        for attendee in meeting.attendees {
            print("👤 Processing results for \(attendee.name) from \(attendee.homeAirport)")
            
            let homeAirport = attendee.homeAirport.uppercased()
            
            for location in meeting.potentialLocations {
                let routeKey = "\(homeAirport)-\(location.airportCode.uppercased())"
                
                // Update progress for result processing
                let apiProgress = 0.7 // API calls completed
                let resultProgress = Double(processedAttendeeResults) / Double(totalPossibleResults) * 0.3 // Remaining 30% for processing
                let totalProgress = apiProgress + resultProgress
                let message = "Processing results for \(attendee.name) → \(location.cityName)"
                await MainActor.run {
                    progressCallback(totalProgress, message)
                }
                
                // Get cached flight offers for this route
                if let offers = flightCache[routeKey], let cheapest = offers.first {
                    let alternativeResult = alternativeAirportCache[routeKey]
                    let result = createFlightSearchResult(
                        from: cheapest,
                        attendee: attendee,
                        location: location,
                        meeting: meeting,
                        alternativeResult: alternativeResult
                    )
                    allResults.append(result)
                    
                    let airportInfo = alternativeResult?.alternativeAirport != alternativeResult?.originalAirport ? 
                        " (via \(alternativeResult?.alternativeAirport ?? "unknown"))" : ""
                    print("  ✅ Added cached result for \(attendee.name) → \(location.cityName)\(airportInfo): $\(cheapest.price.total)")
                } else {
                    print("  ⚠️ No cached results found for \(attendee.name) → \(location.cityName)")
                }
                
                processedAttendeeResults += 1
            }
        }
        
        print("🎉 Optimized search completed!")
        print("  📊 Made \(uniqueRoutes) API calls to generate \(allResults.count) flight results")
        print("  💰 Saved \(totalPossibleResults - uniqueRoutes) API calls compared to individual searches")
        print("  ⚡ Efficiency: \(Int(Double(totalPossibleResults - uniqueRoutes) / Double(totalPossibleResults) * 100))% fewer API calls")
        
        // Final progress update
        await MainActor.run {
            progressCallback(1.0, "Search completed! Found \(allResults.count) flight options.")
        }
        
        return allResults
    }
    
    // MARK: - Optimization Analytics
    
    func getSearchOptimizationStats(for meeting: Meeting) -> SearchOptimizationStats {
        let attendeesByAirport = Dictionary(grouping: meeting.attendees) { attendee in
            attendee.homeAirport.uppercased()
        }
        
        let uniqueAirports = attendeesByAirport.keys.count
        let totalAttendees = meeting.attendees.count
        let totalLocations = meeting.potentialLocations.count
        
        let standardSearches = totalAttendees * totalLocations
        let optimizedSearches = uniqueAirports * totalLocations
        let apiCallsSaved = standardSearches - optimizedSearches
        let efficiencyPercentage = apiCallsSaved > 0 ? Int(Double(apiCallsSaved) / Double(standardSearches) * 100) : 0
        
        let airportGroups = attendeesByAirport.map { (airport, attendees) in
            AirportGroup(airport: airport, attendeeCount: attendees.count, attendeeNames: attendees.map(\.name))
        }.sorted { $0.attendeeCount > $1.attendeeCount }
        
        return SearchOptimizationStats(
            totalAttendees: totalAttendees,
            uniqueAirports: uniqueAirports,
            totalLocations: totalLocations,
            standardApiCalls: standardSearches,
            optimizedApiCalls: optimizedSearches,
            apiCallsSaved: apiCallsSaved,
            efficiencyPercentage: efficiencyPercentage,
            airportGroups: airportGroups
        )
    }
    
    // MARK: - Helper Methods
    
    private func createFlightSearchResult(
        from offer: FlightOffer,
        attendee: Attendee,
        location: Location,
        meeting: Meeting,
        alternativeResult: AlternativeFlightResult? = nil
    ) -> FlightSearchResult {
        // Parse outbound flight (first itinerary)
        let outboundItinerary = offer.itineraries.first
        let outboundDetails = createFlightDetails(
            from: outboundItinerary,
            defaultDepartureAirport: alternativeResult?.alternativeAirport ?? attendee.homeAirport,
            defaultArrivalAirport: location.airportCode,
            originalRequestedAirport: alternativeResult != nil ? attendee.homeAirport : nil
        )
        
        // Parse return flight (second itinerary if available)
        let returnItinerary = offer.itineraries.count > 1 ? offer.itineraries[1] : nil
        let returnDetails = createFlightDetails(
            from: returnItinerary,
            defaultDepartureAirport: location.airportCode,
            defaultArrivalAirport: alternativeResult?.alternativeAirport ?? attendee.homeAirport,
            originalRequestedAirport: alternativeResult != nil ? attendee.homeAirport : nil
        )
        
        // Create alternative airport info if applicable
        var alternativeAirportInfo: AlternativeAirportInfo? = nil
        if let altResult = alternativeResult,
           altResult.alternativeAirport != altResult.originalAirport {
            let altAirportName = airportDatabase[altResult.alternativeAirport]?.name
            alternativeAirportInfo = AlternativeAirportInfo(
                originalAirport: altResult.originalAirport,
                alternativeAirport: altResult.alternativeAirport,
                distanceInMiles: altResult.distance,
                alternativeAirportName: altAirportName
            )
        }
        
        return FlightSearchResult(
            attendee: attendee,
            destination: location,
            outboundFlight: outboundDetails,
            returnFlight: returnDetails,
            totalPrice: Decimal(string: offer.price.total) ?? 0,
            currency: offer.price.currency,
            searchedAt: Date(),
            alternativeAirportUsed: alternativeAirportInfo
        )
    }
    
    private func createFlightDetails(
        from itinerary: Itinerary?,
        defaultDepartureAirport: String,
        defaultArrivalAirport: String,
        originalRequestedAirport: String? = nil
    ) -> FlightDetails {
        guard let itinerary = itinerary else {
            return FlightDetails(
                departureDate: Date(),
                arrivalDate: Date(),
                departureAirport: defaultDepartureAirport,
                arrivalAirport: defaultArrivalAirport,
                stops: 0,
                airline: nil,
                duration: nil,
                isFromAlternativeAirport: originalRequestedAirport != nil,
                originalRequestedAirport: originalRequestedAirport
            )
        }
        
        let segments = itinerary.segments
        let firstSegment = segments.first
        let lastSegment = segments.last
        
        // Calculate stops (segments - 1)
        let stops = max(0, segments.count - 1)
        
        // Parse dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        let departureDate: Date = {
            guard let segment = firstSegment else { return Date() }
            let dateString = String(segment.departure.at.prefix(19))
            return dateFormatter.date(from: dateString) ?? Date()
        }()
        
        let arrivalDate: Date = {
            guard let segment = lastSegment else { return Date() }
            let dateString = String(segment.arrival.at.prefix(19))
            return dateFormatter.date(from: dateString) ?? Date()
        }()
        
        // Get primary airline (from first segment)
        let primaryAirline = firstSegment?.carrierCode
        
        // Create a more detailed airline string if there are connections
        let airlineInfo: String? = {
            if stops > 0 {
                let allCarriers = Set(segments.map { $0.carrierCode })
                if allCarriers.count == 1 {
                    return primaryAirline
                } else {
                    return allCarriers.joined(separator: "/")
                }
            }
            return primaryAirline
        }()
        
        return FlightDetails(
            departureDate: departureDate,
            arrivalDate: arrivalDate,
            departureAirport: firstSegment?.departure.iataCode ?? defaultDepartureAirport,
            arrivalAirport: lastSegment?.arrival.iataCode ?? defaultArrivalAirport,
            stops: stops,
            airline: airlineInfo,
            duration: itinerary.duration,
            isFromAlternativeAirport: originalRequestedAirport != nil,
            originalRequestedAirport: originalRequestedAirport
        )
    }
}

enum FlightSearchError: LocalizedError {
    case authenticationFailed
    case invalidRequest
    case rateLimitExceeded
    case networkError
    case noFlightsFound
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "API authentication failed. Please check your credentials."
        case .invalidRequest:
            return "Invalid search parameters. Please check airport codes and dates."
        case .rateLimitExceeded:
            return "Too many searches. Please try again in a few minutes."
        case .networkError:
            return "Network error. Please check your internet connection."
        case .noFlightsFound:
            return "No flights found for this route and date."
        }
    }
}

// MARK: - Optimization Analytics Models

struct SearchOptimizationStats {
    let totalAttendees: Int
    let uniqueAirports: Int
    let totalLocations: Int
    let standardApiCalls: Int
    let optimizedApiCalls: Int
    let apiCallsSaved: Int
    let efficiencyPercentage: Int
    let airportGroups: [AirportGroup]
    
    var summary: String {
        return """
        📊 Search Optimization Stats:
        👥 \(totalAttendees) attendees from \(uniqueAirports) airports
        📍 \(totalLocations) potential locations
        🚀 \(optimizedApiCalls) API calls (vs \(standardApiCalls) without optimization)
        💰 \(apiCallsSaved) API calls saved (\(efficiencyPercentage)% efficiency gain)
        """
    }
}

struct AirportGroup {
    let airport: String
    let attendeeCount: Int
    let attendeeNames: [String]
    
    var description: String {
        return "\(airport): \(attendeeCount) attendee\(attendeeCount == 1 ? "" : "s") (\(attendeeNames.joined(separator: ", ")))"
    }
}