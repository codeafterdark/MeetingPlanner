import Foundation

// MARK: - Airport Search Models

struct AmadeusAirportResponse: Codable {
    let data: [AirportData]
}

struct AirportData: Codable, Identifiable {
    let id: String
    let type: String
    let name: String
    let iataCode: String
    let address: AirportAddress
    let geoCode: GeoCode?
    
    var displayName: String {
        "\(address.cityName) (\(iataCode))"
    }
    
    var cityAndCountry: String {
        if let countryName = address.countryName {
            return "\(address.cityName), \(countryName)"
        }
        return address.cityName
    }
}

struct AirportAddress: Codable {
    let cityName: String
    let countryCode: String
    let countryName: String?
    let stateCode: String?
}

struct GeoCode: Codable {
    let latitude: Double
    let longitude: Double
}

// MARK: - Airport Search Service

@MainActor
class AirportSearchService: ObservableObject {
    private let apiKey: String
    private let apiSecret: String
    private var accessToken: String?
    private var tokenExpiresAt: Date?
    
    @Published var isSearching = false
    @Published var searchResults: [AirportData] = []
    @Published var lastError: String?
    
    // Rate limiting
    private var lastRequestTime: Date = Date.distantPast
    private let minRequestInterval: TimeInterval = 0.1 // 100ms between requests
    
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
    
    private func authenticate() async throws -> String {
        // Check if we have a valid token
        if let token = accessToken,
           let expiresAt = tokenExpiresAt,
           expiresAt > Date().addingTimeInterval(60) {
            return token
        }
        
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
            throw AirportSearchError.authenticationFailed
        }
        
        let authResponse = try JSONDecoder().decode(AmadeusAuthResponse.self, from: data)
        
        self.accessToken = authResponse.access_token
        self.tokenExpiresAt = Date().addingTimeInterval(TimeInterval(authResponse.expires_in))
        
        return authResponse.access_token
    }
    
    // MARK: - Airport Search
    
    func searchAirports(for query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        lastError = nil
        searchResults = []
        
        defer {
            isSearching = false
        }
        
        do {
            let token = try await authenticate()
            await enforceRateLimit()
            
            var urlComponents = URLComponents(string: "\(Config.amadeusBaseURL)/v1/reference-data/locations")!
            
            // Determine if it's a city search or state search
            let isStateSearch = query.count == 2 && query.allSatisfy(\.isLetter)
            
            if isStateSearch {
                // Search by state code
                urlComponents.queryItems = [
                    URLQueryItem(name: "subType", value: "AIRPORT"),
                    URLQueryItem(name: "view", value: "FULL"),
                    URLQueryItem(name: "page[limit]", value: "20"),
                    URLQueryItem(name: "page[offset]", value: "0"),
                    URLQueryItem(name: "sort", value: "analytics.travelers.score"),
                    URLQueryItem(name: "countryCode", value: "US"),
                ]
                
                // We'll filter by state after getting results since Amadeus doesn't have direct state filtering
            } else {
                // Search by city name or airport code
                urlComponents.queryItems = [
                    URLQueryItem(name: "keyword", value: query),
                    URLQueryItem(name: "subType", value: "AIRPORT"),
                    URLQueryItem(name: "view", value: "FULL"),
                    URLQueryItem(name: "page[limit]", value: "10"),
                    URLQueryItem(name: "page[offset]", value: "0"),
                    URLQueryItem(name: "sort", value: "analytics.travelers.score")
                ]
            }
            
            var request = URLRequest(url: urlComponents.url!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AirportSearchError.networkError
            }
            
            switch httpResponse.statusCode {
            case 200:
                let airportResponse = try JSONDecoder().decode(AmadeusAirportResponse.self, from: data)
                
                if isStateSearch {
                    // Filter results by state code
                    let filteredResults = airportResponse.data.filter { airport in
                        airport.address.stateCode?.uppercased() == query.uppercased()
                    }
                    searchResults = Array(filteredResults.prefix(20))
                } else {
                    searchResults = airportResponse.data
                }
                
            case 400:
                lastError = "Invalid search parameters"
            case 401:
                lastError = "Authentication failed"
            case 429:
                lastError = "Too many requests. Please try again later."
            default:
                lastError = "Search failed with status code: \(httpResponse.statusCode)"
            }
            
        } catch {
            lastError = error.localizedDescription
            print("Airport search error: \(error)")
        }
    }
}

// MARK: - Error Types

enum AirportSearchError: LocalizedError {
    case authenticationFailed
    case networkError
    case invalidQuery
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Failed to authenticate with Amadeus API"
        case .networkError:
            return "Network error occurred"
        case .invalidQuery:
            return "Invalid search query"
        }
    }
}