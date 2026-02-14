import SwiftUI

struct EditMeetingView: View {
    @Binding var savedMeeting: SavedMeeting
    @Environment(AppServices.self) var appServices
    @Environment(\.dismiss) private var dismiss
    @State private var editedMeeting: Meeting
    @State private var currentStep = 0
    @State private var showingUnsavedChangesAlert = false
    
    private let steps = ["Details", "Locations", "Attendees", "Review"]
    
    init(savedMeeting: Binding<SavedMeeting>) {
        self._savedMeeting = savedMeeting
        self._editedMeeting = State(initialValue: savedMeeting.wrappedValue.meeting)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress indicator
                ProgressView(value: Double(currentStep), total: Double(steps.count - 1))
                    .padding(.horizontal)
                
                HStack {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Text(steps[index])
                            .font(.caption)
                            .foregroundColor(index <= currentStep ? .primary : .secondary)
                        
                        if index < steps.count - 1 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                // Step content
                Group {
                    switch currentStep {
                    case 0:
                        MeetingDetailsView(meeting: $editedMeeting)
                    case 1:
                        LocationsView(meeting: $editedMeeting)
                    case 2:
                        AttendeesView(meeting: $editedMeeting)
                    case 3:
                        EditReviewView(
                            originalMeeting: savedMeeting.meeting,
                            editedMeeting: editedMeeting,
                            onSave: saveChanges
                        )
                    default:
                        Text("Unknown step")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Navigation buttons (only show for first 3 steps)
                if currentStep < steps.count - 1 {
                    HStack {
                        if currentStep > 0 {
                            Button("Previous") {
                                currentStep -= 1
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Button("Next") {
                            currentStep += 1
                        }
                        .disabled(!canProceedToNextStep)
                        .foregroundColor(canProceedToNextStep ? .blue : .gray)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Meeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            showingUnsavedChangesAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
        }
        .alert("Unsaved Changes", isPresented: $showingUnsavedChangesAlert) {
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
    }
    
    private var canProceedToNextStep: Bool {
        switch currentStep {
        case 0: // Meeting details
            return !editedMeeting.name.isEmpty
        case 1: // Locations
            return editedMeeting.potentialLocations.count >= 2
        case 2: // Attendees
            return editedMeeting.attendees.count >= 1
        default:
            return true
        }
    }
    
    private var hasUnsavedChanges: Bool {
        editedMeeting.name != savedMeeting.meeting.name ||
        editedMeeting.startDate != savedMeeting.meeting.startDate ||
        editedMeeting.numberOfDays != savedMeeting.meeting.numberOfDays ||
        editedMeeting.travelBufferBefore != savedMeeting.meeting.travelBufferBefore ||
        editedMeeting.travelBufferAfter != savedMeeting.meeting.travelBufferAfter ||
        editedMeeting.potentialLocations.count != savedMeeting.meeting.potentialLocations.count ||
        editedMeeting.attendees.count != savedMeeting.meeting.attendees.count
    }
    
    private func saveChanges() {
        // Create updated SavedMeeting with new data
        var updatedSavedMeeting = savedMeeting
        updatedSavedMeeting.meeting = editedMeeting
        
        // Use the smart update method that automatically handles search result invalidation
        appServices.meetingDataManager.updateMeeting(updatedSavedMeeting)
        
        // Update the binding
        savedMeeting = updatedSavedMeeting
        
        dismiss()
    }
}

struct EditReviewView: View {
    let originalMeeting: Meeting
    let editedMeeting: Meeting
    let onSave: () -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Review Changes")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                
                // Changes Summary
                if hasSignificantChanges {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Search Results Will Be Cleared")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        
                        Text("You've made significant changes that will require new flight searches. Your existing search results will be automatically cleared.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        changesList
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Updated Meeting Summary
                VStack(alignment: .leading, spacing: 16) {
                    Text("Updated Meeting Details")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        SummaryRow(label: "Meeting Name", value: editedMeeting.name)
                        SummaryRow(label: "Start Date", value: dateFormatter.string(from: editedMeeting.startDate))
                        SummaryRow(label: "Duration", value: "\(editedMeeting.numberOfDays) day\(editedMeeting.numberOfDays == 1 ? "" : "s")")
                        SummaryRow(label: "Travel Dates", value: "\(dateFormatter.string(from: editedMeeting.actualStartDate)) - \(dateFormatter.string(from: editedMeeting.actualEndDate))")
                        SummaryRow(label: "Locations", value: "\(editedMeeting.potentialLocations.count) cities")
                        SummaryRow(label: "Attendees", value: "\(editedMeeting.attendees.count) people")
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer(minLength: 80)
            }
        }
        .overlay(
            // Save button at bottom
            VStack {
                Spacer()
                
                Button(action: onSave) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Save Changes")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
                .background(Color(.systemBackground))
            }
        )
    }
    
    private var hasSignificantChanges: Bool {
        originalMeeting.startDate != editedMeeting.startDate ||
        originalMeeting.numberOfDays != editedMeeting.numberOfDays ||
        originalMeeting.travelBufferBefore != editedMeeting.travelBufferBefore ||
        originalMeeting.travelBufferAfter != editedMeeting.travelBufferAfter ||
        originalMeeting.potentialLocations.count != editedMeeting.potentialLocations.count ||
        originalMeeting.attendees.count != editedMeeting.attendees.count
    }
    
    @ViewBuilder
    private var changesList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's changing:")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if originalMeeting.startDate != editedMeeting.startDate {
                ChangeRow(
                    title: "Start Date",
                    before: dateFormatter.string(from: originalMeeting.startDate),
                    after: dateFormatter.string(from: editedMeeting.startDate)
                )
            }
            
            if originalMeeting.numberOfDays != editedMeeting.numberOfDays {
                ChangeRow(
                    title: "Duration",
                    before: "\(originalMeeting.numberOfDays) days",
                    after: "\(editedMeeting.numberOfDays) days"
                )
            }
            
            if originalMeeting.potentialLocations.count != editedMeeting.potentialLocations.count {
                ChangeRow(
                    title: "Locations",
                    before: "\(originalMeeting.potentialLocations.count) cities",
                    after: "\(editedMeeting.potentialLocations.count) cities"
                )
            }
            
            if originalMeeting.attendees.count != editedMeeting.attendees.count {
                ChangeRow(
                    title: "Attendees",
                    before: "\(originalMeeting.attendees.count) people",
                    after: "\(editedMeeting.attendees.count) people"
                )
            }
        }
    }
}

struct ChangeRow: View {
    let title: String
    let before: String
    let after: String
    
    var body: some View {
        HStack {
            Text(title + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(before)
                .font(.caption)
                .strikethrough()
                .foregroundColor(.red)
            
            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(after)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
            
            Spacer()
        }
    }
}

#Preview {
    EditMeetingView(savedMeeting: .constant(
        SavedMeeting(
            meeting: Meeting(name: "Test Meeting"),
            searchResults: [],
            savedAt: Date()
        )
    ))
    .environment(AppServices())
}