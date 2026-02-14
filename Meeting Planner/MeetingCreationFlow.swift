import SwiftUI
import Foundation

struct MeetingCreationFlow: View {
    @Environment(AppServices.self) var appServices
    @State private var viewModel = MeetingViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    
    private let steps = ["Details", "Locations", "Attendees", "Review"]
    
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
                        MeetingDetailsView(meeting: $viewModel.meeting)
                    case 1:
                        LocationsView(meeting: $viewModel.meeting)
                    case 2:
                        AttendeesView(meeting: $viewModel.meeting)
                    case 3:
                        ReviewAndSearchView(meeting: $viewModel.meeting, viewModel: viewModel)
                    default:
                        Text("Unknown step")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Previous") {
                            currentStep -= 1
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    if currentStep < steps.count - 1 {
                        Button("Next") {
                            currentStep += 1
                        }
                        .disabled(!canProceedToNextStep)
                        .foregroundColor(canProceedToNextStep ? .blue : .gray)
                    }
                }
                .padding()
            }
            .navigationTitle("New Meeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }
    
    private var canProceedToNextStep: Bool {
        switch currentStep {
        case 0: // Meeting details
            return !viewModel.meeting.name.isEmpty
        case 1: // Locations
            return viewModel.meeting.potentialLocations.count >= 2
        case 2: // Attendees
            return viewModel.meeting.attendees.count >= 1
        default:
            return true
        }
    }
}

struct MeetingCreationFlow_Previews: PreviewProvider {
    static var previews: some View {
        MeetingCreationFlow()
            .environment(AppServices())
    }
}