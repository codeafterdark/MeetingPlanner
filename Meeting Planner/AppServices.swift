import SwiftUI
import Foundation

@MainActor
@Observable
class AppServices {
    var flightService: FlightSearchService
    var meetingDataManager: MeetingDataManager
    
    init() {
        self.flightService = FlightSearchService(
            apiKey: Config.amadeusAPIKey,
            apiSecret: Config.amadeusAPISecret
        )
        self.meetingDataManager = MeetingDataManager()
    }
}