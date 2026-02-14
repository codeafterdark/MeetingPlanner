import SwiftUI

struct SavedMeetingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMeeting: SavedMeeting?
    @State private var showingMeetingCreation = false
    
    let dataManager: MeetingDataManager
    let onMeetingSelected: (Meeting, [LocationAnalysis]) -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    private var meetingDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if dataManager.savedMeetings.isEmpty {
                    ContentUnavailableView(
                        "No Saved Meetings",
                        systemImage: "calendar.badge.plus",
                        description: Text("Create your first meeting to get started")
                    )
                } else {
                    List {
                        ForEach(dataManager.savedMeetings) { savedMeeting in
                            SavedMeetingCard(
                                savedMeeting: savedMeeting,
                                onTap: { selectMeeting(savedMeeting) },
                                onDelete: { dataManager.deleteMeeting(withId: savedMeeting.id) }
                            )
                        }
                        .onDelete(perform: dataManager.deleteMeetings)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Saved Meetings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Meeting") {
                        showingMeetingCreation = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingMeetingCreation) {
            MeetingCreationFlow()
                .environment(AppServices())
        }
        .sheet(item: $selectedMeeting) { savedMeeting in
            SavedMeetingDetailView(savedMeeting: savedMeeting) { meeting, results in
                onMeetingSelected(meeting, results)
                dismiss()
            }
        }
    }
    
    private func selectMeeting(_ savedMeeting: SavedMeeting) {
        selectedMeeting = savedMeeting
    }
}

struct SavedMeetingCard: View {
    let savedMeeting: SavedMeeting
    let onTap: () -> Void
    let onDelete: () -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(savedMeeting.meeting.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(dateFormatter.string(from: savedMeeting.meeting.startDate)) • \(savedMeeting.meeting.numberOfDays) day\(savedMeeting.meeting.numberOfDays == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                HStack(spacing: 16) {
                    Label("\(savedMeeting.meeting.potentialLocations.count)", systemImage: "location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(savedMeeting.meeting.attendees.count)", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if savedMeeting.hasSearchResults {
                        Label("Results", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label("No Results", systemImage: "minus.circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                if let bestLocation = savedMeeting.bestLocation {
                    HStack {
                        Text("Best option:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(bestLocation.location.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Text("$\(bestLocation.totalCost as NSDecimalNumber, formatter: NumberFormatter.currency)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                
                Text("Saved \(timeFormatter.string(from: savedMeeting.savedAt))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
}

struct SavedMeetingDetailView: View {
    @State var savedMeeting: SavedMeeting
    let onSelect: (Meeting, [LocationAnalysis]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditView = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Meeting Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Meeting Details")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            DetailRow(label: "Meeting Name", value: savedMeeting.meeting.name)
                            DetailRow(label: "Start Date", value: dateFormatter.string(from: savedMeeting.meeting.startDate))
                            DetailRow(label: "Duration", value: "\(savedMeeting.meeting.numberOfDays) day\(savedMeeting.meeting.numberOfDays == 1 ? "" : "s")")
                            DetailRow(label: "Travel Dates", value: "\(dateFormatter.string(from: savedMeeting.meeting.actualStartDate)) - \(dateFormatter.string(from: savedMeeting.meeting.actualEndDate))")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Locations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Potential Locations")
                            .font(.headline)
                        
                        ForEach(savedMeeting.meeting.potentialLocations) { location in
                            HStack {
                                Image(systemName: "location")
                                    .foregroundColor(.blue)
                                Text(location.displayName)
                            }
                        }
                    }
                    
                    // Attendees
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Attendees")
                            .font(.headline)
                        
                        ForEach(savedMeeting.meeting.attendees) { attendee in
                            HStack {
                                Image(systemName: "person")
                                    .foregroundColor(.blue)
                                Text(attendee.displayName)
                            }
                        }
                    }
                    
                    // Search Results (if available)
                    if savedMeeting.hasSearchResults {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Search Results")
                                .font(.headline)
                            
                            ForEach(savedMeeting.searchResults) { result in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.location.displayName)
                                            .fontWeight(.medium)
                                        Text("\(result.attendeeCount) attendees")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("$\(result.totalCost as NSDecimalNumber, formatter: NumberFormatter.currency)")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Meeting Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingEditView = true
                        } label: {
                            Label("Edit Meeting", systemImage: "pencil")
                        }
                        
                        Button {
                            onSelect(savedMeeting.meeting, savedMeeting.searchResults)
                        } label: {
                            Label("Use This Meeting", systemImage: "checkmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditMeetingView(savedMeeting: $savedMeeting)
                .environment(AppServices())
        }
    }
}





struct SavedMeetingsView_Previews: PreviewProvider {
    static var previews: some View {
        SavedMeetingsView(dataManager: MeetingDataManager()) { meeting, results in
            print("Selected meeting: \(meeting.name)")
        }
    }
}