import SwiftUI
import Foundation
import Combine

@MainActor
class AppServices: ObservableObject {
    let flightService: FlightSearchService
    
    init() {
        self.flightService = FlightSearchService(
            apiKey: Config.amadeusAPIKey,
            apiSecret: Config.amadeusAPISecret
        )
    }
}