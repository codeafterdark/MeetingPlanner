import SwiftUI

@main
struct Meeting_PlannerApp: App {
    @StateObject private var appServices = AppServices()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appServices)
        }
    }
}