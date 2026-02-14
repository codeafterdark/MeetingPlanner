import SwiftUI

@main
struct Meeting_PlannerApp: App {
    @State private var appServices = AppServices()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appServices)
        }
    }
}