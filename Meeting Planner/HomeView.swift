import SwiftUI

struct HomeView: View {
    @Environment(AppServices.self) var appServices
    @State private var showingMeetingCreation = false
    @State private var showingSavedMeetings = false
    @State private var selectedMeeting: Meeting?
    @State private var selectedResults: [LocationAnalysis] = []
    @State private var selectedMeetingViewModel: MeetingViewModel?
    
    var dataManager: MeetingDataManager {
        appServices.meetingDataManager
    }
    
    private var showingSelectedMeeting: Binding<Bool> {
        Binding(
            get: { selectedMeeting != nil },
            set: { newValue in
                if !newValue {
                    selectedMeeting = nil
                    selectedResults = []
                    selectedMeetingViewModel = nil
                }
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Meeting Location Planner")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Find the most cost-effective meeting location for your team")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                Button("Create New Meeting") {
                    showingMeetingCreation = true
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal, 32)
                
                Button("ADD TEST DATA (TAP THIS!)") {
                    dataManager.createSampleMeeting()
                    print("✅ Sample meeting created! Count: \(dataManager.savedMeetings.count)")
                }
                .font(.headline)
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal, 32)
                
                // Always show the button, but disable if empty
                Button("VIEW SAVED MEETINGS (\(dataManager.savedMeetings.count))") {
                    if !dataManager.savedMeetings.isEmpty {
                        showingSavedMeetings = true
                    }
                }
                .font(.headline)
                .foregroundColor(dataManager.savedMeetings.isEmpty ? .secondary : .green)
                .frame(maxWidth: .infinity)
                .padding()
                .background((dataManager.savedMeetings.isEmpty ? Color.gray : Color.green).opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal, 32)
                .disabled(dataManager.savedMeetings.isEmpty)
                
                Spacer()
            }
            .navigationTitle("Meeting Planner")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingMeetingCreation) {
            MeetingCreationFlow()
                .environment(appServices)
        }
        .sheet(isPresented: $showingSavedMeetings) {
            SavedMeetingsView(dataManager: dataManager, onMeetingSelected: { meeting, results in
                selectedMeeting = meeting
                selectedResults = results
                selectedMeetingViewModel = MeetingViewModel()
                selectedMeetingViewModel?.meeting = meeting
                selectedMeetingViewModel?.results = results
            })
            .environment(appServices)
        }
        .fullScreenCover(isPresented: showingSelectedMeeting) {
            NavigationView {
                if let meeting = selectedMeeting,
                   let viewModel = selectedMeetingViewModel {
                    ReviewAndSearchView(meeting: .constant(meeting), viewModel: viewModel)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Done") {
                                    selectedMeeting = nil
                                    selectedResults = []
                                    selectedMeetingViewModel = nil
                                }
                            }
                        }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(AppServices())
}
