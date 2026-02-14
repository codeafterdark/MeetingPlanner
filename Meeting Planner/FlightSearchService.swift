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
    
    // MARK: - Search All Combinations
    
    func searchAllCombinations(meeting: Meeting, progressCallback: @escaping (Double, String) -> Void) async throws -> [FlightSearchResult] {
        isSearching = true
        lastError = nil
        
        defer {
            isSearching = false
        }
        
        var allResults: [FlightSearchResult] = []
        let totalSearches = meeting.attendees.count * meeting.potentialLocations.count
        var completedSearches = 0
        
        print("🔍 Starting search for \(meeting.attendees.count) attendees and \(meeting.potentialLocations.count) locations (\(totalSearches) total searches)")
        
        for (attendeeIndex, attendee) in meeting.attendees.enumerated() {
            print("👤 Processing attendee \(attendeeIndex + 1)/\(meeting.attendees.count): \(attendee.name) from \(attendee.homeAirport)")
            
            // Validate attendee data
            guard !attendee.homeAirport.isEmpty, attendee.homeAirport.count == 3 else {
                print("  ⚠️ Invalid home airport code: '\(attendee.homeAirport)' for \(attendee.name)")
                completedSearches += meeting.potentialLocations.count
                continue
            }
            
            for (locationIndex, location) in meeting.potentialLocations.enumerated() {
                print("  📍 Searching location \(locationIndex + 1)/\(meeting.potentialLocations.count): \(location.cityName) (\(location.airportCode))")
                
                // Validate location data
                guard !location.airportCode.isEmpty, location.airportCode.count == 3 else {
                    print("    ⚠️ Invalid airport code: '\(location.airportCode)' for \(location.cityName)")
                    completedSearches += 1
                    continue
                }
                
                // Skip if same airport (no point searching from/to same place)
                if attendee.homeAirport.uppercased() == location.airportCode.uppercased() {
                    print("    ⚠️ Skipping search - same airport: \(attendee.homeAirport)")
                    completedSearches += 1
                    continue
                }
                
                do {
                    // Update progress
                    let progress = Double(completedSearches) / Double(totalSearches)
                    let message = "Searching flights for \(attendee.name) to \(location.cityName)..."
                    await MainActor.run {
                        progressCallback(progress, message)
                    }
                    
                    print("  🛫 Making API call: \(attendee.homeAirport) → \(location.airportCode)")
                    
                    let offers = try await searchFlightsWithFallback(
                        from: attendee.homeAirport,
                        to: location.airportCode,
                        departureDate: meeting.actualStartDate,
                        returnDate: meeting.actualEndDate
                    )
                    
                    print("  ✅ API call successful, found \(offers.count) offers")
                    
                    if let cheapest = offers.first { // Assuming API returns sorted by price
                        let result = createFlightSearchResult(from: cheapest, attendee: attendee, location: location, meeting: meeting)
                        allResults.append(result)
                        
                        // Log connection details
                        if let outbound = cheapest.itineraries.first {
                            let stops = max(0, outbound.segments.count - 1)
                            print("  💰 Added result: $\(cheapest.price.total) with \(stops) stop\(stops == 1 ? "" : "s")")
                            
                            if stops > 0 {
                                let connections = outbound.segments.map { $0.departure.iataCode + "→" + $0.arrival.iataCode }.joined(separator: ", ")
                                print("    🔄 Connection route: \(connections)")
                            }
                        }
                    } else {
                        print("  ⚠️ No offers found for this route")
                    }
                    
                    completedSearches += 1
                    print("  ✅ Completed search \(completedSearches)/\(totalSearches)")
                    
                } catch FlightSearchError.rateLimitExceeded {
                    print("  🚫 Rate limit exceeded, waiting before retry...")
                    // If we hit rate limit, wait a bit longer and retry
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    
                    // Retry once
                    do {
                        print("  🔄 Retrying API call: \(attendee.homeAirport) → \(location.airportCode)")
                        
                        let offers = try await searchFlightsWithFallback(
                            from: attendee.homeAirport,
                            to: location.airportCode,
                            departureDate: meeting.actualStartDate,
                            returnDate: meeting.actualEndDate
                        )
                        
                        if let cheapest = offers.first {
                            let result = createFlightSearchResult(from: cheapest, attendee: attendee, location: location, meeting: meeting)
                            allResults.append(result)
                            
                            // Log connection details
                            if let outbound = cheapest.itineraries.first {
                                let stops = max(0, outbound.segments.count - 1)
                                print("  ✅ Retry successful, added result: $\(cheapest.price.total) with \(stops) stop\(stops == 1 ? "" : "s")")
                            }
                        }
                        completedSearches += 1
                        print("  ✅ Completed search \(completedSearches)/\(totalSearches) (after retry)")
                    } catch {
                        print("  ❌ Failed to search flights for \(attendee.name) to \(location.cityName) after retry: \(error)")
                        completedSearches += 1
                        // Continue with other searches even if one fails
                    }
                } catch {
                    print("  ❌ Failed to search flights for \(attendee.name) to \(location.cityName): \(error)")
                    print("  📋 Error details: \(error.localizedDescription)")
                    if let flightError = error as? FlightSearchError {
                        print("  🏷️ Flight error type: \(flightError)")
                        
                        // Check if this is a fatal error that should stop the search
                        switch flightError {
                        case .authenticationFailed:
                            print("  🚨 Authentication failed - this might affect subsequent searches")
                            // Continue for now, but log it as a potential issue
                        case .rateLimitExceeded:
                            print("  🚨 Rate limit exceeded - adding extra delay")
                            // Add extra delay to help with rate limiting
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second extra
                        default:
                            break
                        }
                    }
                    completedSearches += 1
                    // Continue with other searches even if one fails
                }
            }
            print("✅ Completed all locations for attendee: \(attendee.name)")
        }
        
        print("🎉 Search completed! Found \(allResults.count) results out of \(totalSearches) attempted searches")
        
        // Final progress update
        await MainActor.run {
            progressCallback(1.0, "Search completed!")
        }
        
        return allResults
    }
    
    // MARK: - Helper Methods
    
    private func createFlightSearchResult(
        from offer: FlightOffer,
        attendee: Attendee,
        location: Location,
        meeting: Meeting
    ) -> FlightSearchResult {
        // Parse outbound flight (first itinerary)
        let outboundItinerary = offer.itineraries.first
        let outboundDetails = createFlightDetails(
            from: outboundItinerary,
            defaultDepartureAirport: attendee.homeAirport,
            defaultArrivalAirport: location.airportCode
        )
        
        // Parse return flight (second itinerary if available)
        let returnItinerary = offer.itineraries.count > 1 ? offer.itineraries[1] : nil
        let returnDetails = createFlightDetails(
            from: returnItinerary,
            defaultDepartureAirport: location.airportCode,
            defaultArrivalAirport: attendee.homeAirport
        )
        
        return FlightSearchResult(
            attendee: attendee,
            destination: location,
            outboundFlight: outboundDetails,
            returnFlight: returnDetails,
            totalPrice: Decimal(string: offer.price.total) ?? 0,
            currency: offer.price.currency,
            searchedAt: Date()
        )
    }
    
    private func createFlightDetails(
        from itinerary: Itinerary?,
        defaultDepartureAirport: String,
        defaultArrivalAirport: String
    ) -> FlightDetails {
        guard let itinerary = itinerary else {
            return FlightDetails(
                departureDate: Date(),
                arrivalDate: Date(),
                departureAirport: defaultDepartureAirport,
                arrivalAirport: defaultArrivalAirport,
                stops: 0,
                airline: nil,
                duration: nil
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
            duration: itinerary.duration
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