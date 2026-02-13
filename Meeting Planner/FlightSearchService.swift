import Foundation

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
    
    init(apiKey: String, apiSecret: String) {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
    }
    
    // MARK: - Authentication
    
    func authenticate() async throws -> String {
        // Check if we have a valid token
        if let token = accessToken,
           let expiresAt = tokenExpiresAt,
           expiresAt > Date().addingTimeInterval(60) { // 1 minute buffer
            return token
        }
        
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
            URLQueryItem(name: "max", value: "5")
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FlightSearchError.networkError
        }
        
        switch httpResponse.statusCode {
        case 200:
            let flightResponse = try JSONDecoder().decode(AmadeusFlightResponse.self, from: data)
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
    
    func searchAllCombinations(meeting: Meeting) async throws -> [FlightSearchResult] {
        var allResults: [FlightSearchResult] = []
        
        for attendee in meeting.attendees {
            for location in meeting.potentialLocations {
                do {
                    let offers = try await searchFlights(
                        from: attendee.homeAirport,
                        to: location.airportCode,
                        departureDate: meeting.actualStartDate,
                        returnDate: meeting.actualEndDate
                    )
                    
                    if let cheapest = offers.first { // Assuming API returns sorted by price
                        let result = FlightSearchResult(
                            attendee: attendee,
                            destination: location,
                            outboundFlight: FlightDetails(
                                departureDate: meeting.actualStartDate,
                                arrivalDate: meeting.actualStartDate,
                                departureAirport: attendee.homeAirport,
                                arrivalAirport: location.airportCode,
                                stops: cheapest.itineraries.first?.segments.count ?? 0 - 1,
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
                    
                    // Rate limiting delay
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                } catch {
                    print("Failed to search flights for \(attendee.name) to \(location.cityName): \(error)")
                    // Continue with other searches even if one fails
                }
            }
        }
        
        return allResults
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