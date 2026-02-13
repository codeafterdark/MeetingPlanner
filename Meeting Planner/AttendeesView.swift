import SwiftUI

struct AttendeesView: View {
    @Binding var meeting: Meeting
    @State private var showingAddAttendee = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Meeting Attendees")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add everyone who needs flights to the meeting")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top)
            
            if meeting.attendees.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No attendees added yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button("Add First Attendee") {
                        showingAddAttendee = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(meeting.attendees) { attendee in
                            AttendeeCard(attendee: attendee) {
                                meeting.attendees.removeAll { $0.id == attendee.id }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            
            Button(action: {
                showingAddAttendee = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Attendee")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .sheet(isPresented: $showingAddAttendee) {
            AddAttendeeView(attendees: $meeting.attendees)
        }
    }
}

struct AttendeeCard: View {
    let attendee: Attendee
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(attendee.name)
                    .font(.headline)
                
                Text("From: \(attendee.homeAirport)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct AddAttendeeView: View {
    @Binding var attendees: [Attendee]
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var homeAirport = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Attendee Details")) {
                    TextField("Full Name", text: $name)
                    TextField("Home Airport Code (e.g., SFO)", text: $homeAirport)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: homeAirport) { newValue in
                            homeAirport = String(newValue.prefix(3)).uppercased()
                        }
                }
                
                if !name.isEmpty && !homeAirport.isEmpty {
                    Section {
                        Text("Preview: \(name) - \(homeAirport)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(footer: Text("Common airports: SFO (San Francisco), JFK (New York), LAX (Los Angeles), ORD (Chicago), DFW (Dallas)")) {
                    EmptyView()
                }
            }
            .navigationTitle("Add Attendee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newAttendee = Attendee(
                            name: name,
                            homeAirport: homeAirport
                        )
                        attendees.append(newAttendee)
                        dismiss()
                    }
                    .disabled(name.isEmpty || homeAirport.count != 3)
                }
            }
        }
    }
}

struct AttendeesView_Previews: PreviewProvider {
    static var previews: some View {
        AttendeesView(meeting: .constant(Meeting()))
    }
}