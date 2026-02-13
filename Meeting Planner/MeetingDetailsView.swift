import SwiftUI

struct MeetingDetailsView: View {
    @Binding var meeting: Meeting
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Meeting Details")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Meeting Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meeting Name")
                            .font(.headline)
                        TextField("Enter meeting name", text: $meeting.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Start Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Date")
                            .font(.headline)
                        DatePicker("Start Date", selection: $meeting.startDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    
                    // Number of Days
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meeting Duration")
                            .font(.headline)
                        HStack {
                            Text("Number of days:")
                            Spacer()
                            Stepper(value: $meeting.numberOfDays, in: 1...30) {
                                Text("\(meeting.numberOfDays) day\(meeting.numberOfDays == 1 ? "" : "s")")
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    
                    // Travel Buffers
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Travel Buffer Days")
                            .font(.headline)
                        
                        HStack {
                            Text("Before meeting:")
                            Spacer()
                            Stepper(value: $meeting.travelBufferBefore, in: 0...7) {
                                Text("\(meeting.travelBufferBefore) day\(meeting.travelBufferBefore == 1 ? "" : "s")")
                                    .fontWeight(.medium)
                            }
                        }
                        
                        HStack {
                            Text("After meeting:")
                            Spacer()
                            Stepper(value: $meeting.travelBufferAfter, in: 0...7) {
                                Text("\(meeting.travelBufferAfter) day\(meeting.travelBufferAfter == 1 ? "" : "s")")
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    
                    // Computed Travel Dates
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calculated Travel Dates")
                            .font(.headline)
                            .padding(.top)
                        
                        VStack(spacing: 4) {
                            HStack {
                                Text("Outbound travel:")
                                Spacer()
                                Text(meeting.actualStartDate, format: .dateTime.weekday().month().day())
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Meeting dates:")
                                Spacer()
                                Text("\(meeting.startDate, format: .dateTime.month().day()) - \(Calendar.current.date(byAdding: .day, value: meeting.numberOfDays - 1, to: meeting.startDate) ?? meeting.startDate, format: .dateTime.month().day())")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Return travel:")
                                Spacer()
                                Text(meeting.actualEndDate, format: .dateTime.weekday().month().day())
                                    .fontWeight(.medium)
                            }
                        }
                        .foregroundColor(.secondary)
                        .font(.caption)
                    }
                }
            }
            .padding()
        }
    }
}

struct MeetingDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        MeetingDetailsView(meeting: .constant(Meeting(name: "Q1 Planning")))
    }
}