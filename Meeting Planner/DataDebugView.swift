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
                Section("Current Data Status") {
                    HStack {
                        Text("Meetings in memory:")
                        Spacer()
                        Text("\(dataManager.savedMeetings.count)")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    Button("Debug Print Status") {
                        dataManager.debugPrintDataStatus()
                        testResult = "Check Xcode console for detailed debug output. Look for lines starting with 📊, 💾, or ❌"
                        showTestResult = true
                    }
                    .foregroundColor(.blue)
                }
                
                Section("Test Operations") {
                    Button("Create Test Meeting") {
                        let testMeeting = Meeting(
                            name: "Debug Test \(Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 1000))",
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
                        testResult = """
                        ✅ Test meeting created and saved!
                        Name: \(testMeeting.name)
                        Total meetings: \(dataManager.savedMeetings.count)
                        
                        Check console for save confirmation.
                        """
                        showTestResult = true
                    }
                    .foregroundColor(.green)
                    
                    Button("Test Update Meeting") {
                        if var firstMeeting = dataManager.savedMeetings.first {
                            let originalName = firstMeeting.meeting.name
                            let newAttendee = Attendee(
                                name: "Updated User \(Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 1000))",
                                homeAirport: "LAX"
                            )
                            
                            firstMeeting.meeting.attendees.append(newAttendee)
                            firstMeeting.meeting.name = "\(originalName) - UPDATED"
                            dataManager.updateMeeting(firstMeeting)
                            
                            testResult = """
                            ✅ Updated first meeting:
                            Original: \(originalName)
                            New: \(firstMeeting.meeting.name)
                            Attendees: \(firstMeeting.meeting.attendees.count)
                            
                            Check console for update confirmation.
                            """
                            showTestResult = true
                        } else {
                            testResult = "❌ No meetings found to update. Create a test meeting first."
                            showTestResult = true
                        }
                    }
                    .foregroundColor(.orange)
                    
                    Button("Force Reload Test") {
                        // This simulates app restart by creating new manager
                        let originalCount = dataManager.savedMeetings.count
                        
                        // Access UserDefaults directly to verify data
                        let userDefaults = UserDefaults.standard
                        if let data = userDefaults.data(forKey: "SavedMeetings") {
                            do {
                                let decoder = JSONDecoder()
                                decoder.dateDecodingStrategy = .iso8601
                                let meetings = try decoder.decode([SavedMeeting].self, from: data)
                                
                                testResult = """
                                🔄 Reload Test Results:
                                In-memory count: \(originalCount)
                                UserDefaults count: \(meetings.count)
                                Data size: \(data.count) bytes
                                
                                \(originalCount == meetings.count ? "✅ DATA IS PERSISTING CORRECTLY" : "❌ DATA MISMATCH - PERSISTENCE ISSUE")
                                """
                            } catch {
                                testResult = """
                                ❌ Reload Test Failed:
                                In-memory: \(originalCount) meetings
                                UserDefaults: Data exists but can't decode
                                Error: \(error.localizedDescription)
                                """
                            }
                        } else {
                            testResult = """
                            ❌ Reload Test Results:
                            In-memory: \(originalCount) meetings
                            UserDefaults: NO DATA FOUND
                            
                            This indicates a persistence problem!
                            """
                        }
                        showTestResult = true
                    }
                    .foregroundColor(.blue)
                }
                
                Section("Data Management") {
                    Button("Add Sample Data") {
                        let originalCount = dataManager.savedMeetings.count
                        dataManager.createSampleMeeting()
                        let newCount = dataManager.savedMeetings.count
                        
                        testResult = """
                        ✅ Sample data added!
                        Before: \(originalCount) meetings
                        After: \(newCount) meetings
                        Added: \(newCount - originalCount) meeting(s)
                        """
                        showTestResult = true
                    }
                    .foregroundColor(.blue)
                    
                    Button("Clear All Data", role: .destructive) {
                        let clearedCount = dataManager.savedMeetings.count
                        dataManager.clearAllData()
                        
                        testResult = """
                        🧹 All data cleared!
                        Removed: \(clearedCount) meetings
                        Current count: \(dataManager.savedMeetings.count)
                        
                        UserDefaults cleared and synchronized.
                        """
                        showTestResult = true
                    }
                    .foregroundColor(.red)
                }
                
                if !dataManager.savedMeetings.isEmpty {
                    Section("Current Meetings") {
                        ForEach(dataManager.savedMeetings.prefix(5)) { meeting in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(meeting.meeting.name)
                                    .font(.headline)
                                
                                HStack {
                                    Label("\(meeting.meeting.attendees.count)", systemImage: "person.2")
                                    Spacer()
                                    Label("\(meeting.meeting.potentialLocations.count)", systemImage: "location")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                                Text("Saved: \(meeting.savedAt, formatter: dateFormatter)")
                                    .font(.caption2)
                                    .foregroundColor(.tertiary)
                                
                                if meeting.hasSearchResults {
                                    Text("Has \(meeting.searchResults.count) search results")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        if dataManager.savedMeetings.count > 5 {
                            Text("... and \(dataManager.savedMeetings.count - 5) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
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