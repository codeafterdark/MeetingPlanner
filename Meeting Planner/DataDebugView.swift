import SwiftUI

import SwiftUI

/// A debug view to help troubleshoot data persistence issues
struct DataDebugView: View {
    @Environment(AppServices.self) var appServices
    @Environment(\.dismiss) private var dismiss
    @State private var testResult = ""
    @State private var showTestResult = false
    
    private var dataManager: MeetingDataManager {
        appServices.meetingDataManager
    }
    
    var body: some View {
        NavigationView {
            Form {
                currentDataStatusSection
                searchOptimizationSection
                testOperationsSection
                dataManagementSection
                currentMeetingsSection
            }
            .navigationTitle("🔧 Data Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Debug Result", isPresented: $showTestResult) {
                Button("OK") { }
            } message: {
                Text(testResult)
            }
        }
    }
    
    // MARK: - View Sections
    
    private var currentDataStatusSection: some View {
        Section("Current Data Status") {
            meetingCountRow
            debugPrintButton
        }
    }
    
    private var searchOptimizationSection: some View {
        Section("Flight Search Optimization") {
            if let latestMeeting = dataManager.savedMeetings.first {
                optimizationStatsRow(for: latestMeeting)
                NavigationLink("View Detailed Stats") {
                    SearchOptimizationView(
                        meeting: latestMeeting.meeting,
                        flightSearchService: appServices.flightService
                    )
                }
            } else {
                Text("No meetings available")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func optimizationStatsRow(for savedMeeting: SavedMeeting) -> some View {
        let stats = appServices.flightService.getSearchOptimizationStats(for: savedMeeting.meeting)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Latest Meeting Efficiency:")
                Spacer()
                Text("\(stats.efficiencyPercentage)%")
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            HStack {
                Text("API calls saved:")
                Spacer()
                Text("\(stats.apiCallsSaved)")
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("Unique airports:")
                Spacer()
                Text("\(stats.uniqueAirports)/\(stats.totalAttendees)")
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            }
        }
    }
    
    private var meetingCountRow: some View {
        HStack {
            Text("Meetings in memory:")
            Spacer()
            Text("\(dataManager.savedMeetings.count)")
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
        }
    }
    
    private var debugPrintButton: some View {
        Button("Debug Print Status") {
            debugPrintStatus()
        }
        .foregroundStyle(.blue)
    }
    
    private var testOperationsSection: some View {
        Section("Test Operations") {
            createTestButton
            updateTestButton
            reloadTestButton
            debugMeetingDatesButton
            smartUpdateTestButton
        }
    }
    
    private var createTestButton: some View {
        Button("Create Test Meeting") {
            createTestMeeting()
        }
        .foregroundStyle(.green)
    }
    
    private var updateTestButton: some View {
        Button("Test Update Meeting") {
            updateTestMeeting()
        }
        .foregroundStyle(.orange)
    }
    
    private var reloadTestButton: some View {
        Button("Force Reload Test") {
            performReloadTest()
        }
        .foregroundStyle(.blue)
    }
    
    private var dataManagementSection: some View {
        Section("Data Management") {
            addSampleButton
            clearSearchResultsButton
            clearDataButton
        }
    }
    
    private var addSampleButton: some View {
        Button("Add Sample Data") {
            addSampleData()
        }
        .foregroundStyle(.blue)
    }
    
    private var clearSearchResultsButton: some View {
        Button("Clear All Search Results") {
            clearAllSearchResults()
        }
        .foregroundStyle(.orange)
    }
    
    private var clearDataButton: some View {
        Button("Clear All Data", role: .destructive) {
            clearAllData()
        }
        .foregroundStyle(.red)
    }
    
    @ViewBuilder
    private var currentMeetingsSection: some View {
        if !dataManager.savedMeetings.isEmpty {
            Section("Current Meetings") {
                ForEach(dataManager.savedMeetings.prefix(5)) { meeting in
                    meetingRow(meeting)
                }
                
                if dataManager.savedMeetings.count > 5 {
                    moreItemsText
                }
            }
        }
    }
    
    private func meetingRow(_ savedMeeting: SavedMeeting) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(savedMeeting.meeting.name)
                    .font(.headline)
                
                if savedMeeting.meeting.name.contains("Dev in person Meeting") {
                    Text("🔍")
                        .font(.caption)
                }
            }
            
            meetingInfoRow(savedMeeting)
            
            // Show actual meeting dates for debugging
            Text("Meeting: \(savedMeeting.meeting.startDate, formatter: dateFormatter)")
                .font(.caption2)
                .foregroundStyle(.blue)
            
            Text("Saved: \(savedMeeting.savedAt, formatter: dateFormatter)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            if savedMeeting.hasSearchResults {
                HStack {
                    searchResultsText(savedMeeting)
                    Spacer()
                    Button("Clear") {
                        dataManager.clearSearchResults(for: savedMeeting.id)
                    }
                    .font(.caption2)
                    .foregroundStyle(.orange)
                }
            } else {
                Text("No search results")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func meetingInfoRow(_ savedMeeting: SavedMeeting) -> some View {
        HStack {
            Label("\(savedMeeting.meeting.attendees.count)", systemImage: "person.2")
            Spacer()
            Label("\(savedMeeting.meeting.potentialLocations.count)", systemImage: "location")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    
    private func searchResultsText(_ savedMeeting: SavedMeeting) -> some View {
        Text("Has \(savedMeeting.searchResults.count) search results")
            .font(.caption2)
            .foregroundStyle(.green)
    }
    
    private var moreItemsText: some View {
        Text("... and \(dataManager.savedMeetings.count - 5) more")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    
    private var debugMeetingDatesButton: some View {
        Button("Debug Meeting Dates") {
            debugMeetingDates()
        }
        .foregroundStyle(.purple)
    }
    
    private var smartUpdateTestButton: some View {
        Button("Test Smart Update") {
            testSmartUpdate()
        }
        .foregroundStyle(.indigo)
    }
    
    // MARK: - Helper Functions
    
    private func testSmartUpdate() {
        guard var firstMeeting = dataManager.savedMeetings.first else {
            testResult = "❌ No meetings found to test. Create a test meeting first."
            showTestResult = true
            return
        }
        
        let originalName = firstMeeting.meeting.name
        let originalStartDate = firstMeeting.meeting.startDate
        let originalHasResults = firstMeeting.hasSearchResults
        
        // Make a significant change that should clear search results
        firstMeeting.meeting.startDate = Calendar.current.date(byAdding: .day, value: 7, to: originalStartDate) ?? originalStartDate
        firstMeeting.meeting.name = "\(originalName) - SMART UPDATE TEST"
        
        // Add sample search results if none exist (to test clearing)
        if !firstMeeting.hasSearchResults {
            firstMeeting.searchResults = [
                LocationAnalysis(
                    location: Location(cityName: "Test City", airportCode: "TST", countryCode: "US"),
                    flightResults: [],
                    totalCost: 1000,
                    averageCostPerPerson: 500,
                    currency: "USD",
                    totalAttendeesSearched: 2
                )
            ]
        }
        
        // Use the smart update method
        dataManager.updateMeeting(firstMeeting)
        
        // Check the result
        let updatedMeeting = dataManager.savedMeetings.first { $0.id == firstMeeting.id }
        let resultsWereCleared = updatedMeeting?.searchResults.isEmpty ?? false
        
        let lines = [
            "🧠 Smart Update Test Results:",
            "Original: \(originalName)",
            "Updated: \(firstMeeting.meeting.name)",
            "Date changed: ✅",
            "Had results before: \(originalHasResults ? "Yes" : "No")",
            "Results cleared: \(resultsWereCleared ? "✅ Yes" : "❌ No")",
            "",
            resultsWereCleared ? "✅ Smart update worked correctly!" : "❌ Search results should have been cleared"
        ]
        
        testResult = lines.joined(separator: "\n")
        showTestResult = true
    }
    
    private func debugMeetingDates() {
        guard let devMeeting = dataManager.savedMeetings.first(where: { $0.meeting.name.contains("Dev in person Meeting") }) else {
            testResult = "❌ Could not find 'Dev in person Meeting'"
            showTestResult = true
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        
        let meeting = devMeeting.meeting
        let meetingEndDate = Calendar.current.date(byAdding: .day, value: meeting.numberOfDays - 1, to: meeting.startDate) ?? meeting.startDate
        
        let lines = [
            "🔍 Debug: Dev Meeting Dates",
            "Meeting Name: \(meeting.name)",
            "Start Date: \(formatter.string(from: meeting.startDate))",
            "Meeting End: \(formatter.string(from: meetingEndDate))",
            "Number of Days: \(meeting.numberOfDays)",
            "Actual Start: \(formatter.string(from: meeting.actualStartDate))",
            "Actual End: \(formatter.string(from: meeting.actualEndDate))",
            "Has Search Results: \(devMeeting.hasSearchResults)",
            "Search Results Count: \(devMeeting.searchResults.count)",
            "",
            meeting.startDate.timeIntervalSince1970 > Date().addingTimeInterval(86400 * 100).timeIntervalSince1970 ? "✅ Date looks correct (May 13)" : "❌ Date looks wrong (May 5)"
        ]
        
        testResult = lines.joined(separator: "\n")
        showTestResult = true
    }
    
    private func debugPrintStatus() {
        dataManager.debugPrintDataStatus()
        testResult = "Check Xcode console for detailed debug output. Look for lines starting with 📊, 💾, or ❌"
        showTestResult = true
    }
    
    private func createTestMeeting() {
        let timestamp = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 1000)
        let testName = "Debug Test \(timestamp)"
        
        let testMeeting = Meeting(
            name: testName,
            startDate: Date().addingTimeInterval(86400),
            numberOfDays: 2,
            potentialLocations: [
                Location(cityName: "Test City", airportCode: "TST", countryCode: "US")
            ],
            attendees: [
                Attendee(name: "Debug User", homeAirport: "SFO")
            ]
        )
        
        dataManager.saveMeeting(testMeeting)
        
        let result = "✅ Test meeting created and saved!\nName: \(testName)\nTotal meetings: \(dataManager.savedMeetings.count)\n\nCheck console for save confirmation."
        testResult = result
        showTestResult = true
    }
    
    private func updateTestMeeting() {
        guard var firstMeeting = dataManager.savedMeetings.first else {
            testResult = "❌ No meetings found to update. Create a test meeting first."
            showTestResult = true
            return
        }
        
        let originalName = firstMeeting.meeting.name
        let timestamp = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 1000)
        let newUserName = "Updated User \(timestamp)"
        
        let newAttendee = Attendee(name: newUserName, homeAirport: "LAX")
        firstMeeting.meeting.attendees.append(newAttendee)
        firstMeeting.meeting.name = "\(originalName) - UPDATED"
        
        dataManager.updateMeeting(firstMeeting)
        
        let result = "✅ Updated first meeting:\nOriginal: \(originalName)\nNew: \(firstMeeting.meeting.name)\nAttendees: \(firstMeeting.meeting.attendees.count)\n\nCheck console for update confirmation."
        testResult = result
        showTestResult = true
    }
    
    private func performReloadTest() {
        let originalCount = dataManager.savedMeetings.count
        let userDefaults = UserDefaults.standard
        
        guard let data = userDefaults.data(forKey: "SavedMeetings") else {
            let result = "❌ Reload Test Results:\nIn-memory: \(originalCount) meetings\nUserDefaults: NO DATA FOUND\n\nThis indicates a persistence problem!"
            testResult = result
            showTestResult = true
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let meetings = try decoder.decode([SavedMeeting].self, from: data)
            
            let isDataConsistent = originalCount == meetings.count
            let status = isDataConsistent ? "✅ DATA IS PERSISTING CORRECTLY" : "❌ DATA MISMATCH - PERSISTENCE ISSUE"
            
            let result = "🔄 Reload Test Results:\nIn-memory count: \(originalCount)\nUserDefaults count: \(meetings.count)\nData size: \(data.count) bytes\n\n\(status)"
            testResult = result
            showTestResult = true
        } catch {
            let result = "❌ Reload Test Failed:\nIn-memory: \(originalCount) meetings\nUserDefaults: Data exists but can't decode\nError: \(error.localizedDescription)"
            testResult = result
            showTestResult = true
        }
    }
    
    private func addSampleData() {
        let originalCount = dataManager.savedMeetings.count
        dataManager.createSampleMeeting()
        let newCount = dataManager.savedMeetings.count
        let addedCount = newCount - originalCount
        
        let result = "✅ Sample data added!\nBefore: \(originalCount) meetings\nAfter: \(newCount) meetings\nAdded: \(addedCount) meeting(s)"
        testResult = result
        showTestResult = true
    }
    
    private func clearAllSearchResults() {
        let meetingCount = dataManager.savedMeetings.count
        var clearedResultsCount = 0
        
        for meeting in dataManager.savedMeetings {
            if meeting.hasSearchResults {
                dataManager.clearSearchResults(for: meeting.id)
                clearedResultsCount += 1
            }
        }
        
        let lines = [
            "🔄 Search results cleared!",
            "Meetings processed: \(meetingCount)",
            "Search results cleared: \(clearedResultsCount)",
            "",
            "All meetings now ready for fresh search."
        ]
        
        testResult = lines.joined(separator: "\n")
        showTestResult = true
    }
    
    private func clearAllData() {
        let clearedCount = dataManager.savedMeetings.count
        dataManager.clearAllData()
        
        let result = "🧹 All data cleared!\nRemoved: \(clearedCount) meetings\nCurrent count: \(dataManager.savedMeetings.count)\n\nUserDefaults cleared and synchronized."
        testResult = result
        showTestResult = true
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    DataDebugView()
        .environment(AppServices())
}