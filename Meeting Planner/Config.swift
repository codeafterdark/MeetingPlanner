import Foundation

enum Config {
    static let amadeusAPIKey = Bundle.main.object(
        forInfoDictionaryKey: "AMADEUS_API_KEY"
    ) as? String ?? "your_api_key_here"
    
    static let amadeusAPISecret = Bundle.main.object(
        forInfoDictionaryKey: "AMADEUS_API_SECRET"
    ) as? String ?? "your_api_secret_here"
    
    static let amadeusBaseURL = Bundle.main.object(
        forInfoDictionaryKey: "AMADEUS_BASE_URL"
    ) as? String ?? "https://test.api.amadeus.com"
}