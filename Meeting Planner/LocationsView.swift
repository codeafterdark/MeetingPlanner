import SwiftUI

struct LocationsView: View {
    @Binding var meeting: Meeting
    @State private var showingAddLocation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Potential Meeting Locations")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add at least 2 cities to compare costs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top)
            
            if meeting.potentialLocations.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "map")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No locations added yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button("Add First Location") {
                        showingAddLocation = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(meeting.potentialLocations) { location in
                            LocationCard(location: location) {
                                meeting.potentialLocations.removeAll { $0.id == location.id }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            
            Button(action: {
                showingAddLocation = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Location")
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
        .sheet(isPresented: $showingAddLocation) {
            AddLocationView(locations: $meeting.potentialLocations)
        }
    }
}

struct LocationCard: View {
    let location: Location
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(location.cityName)
                    .font(.headline)
                
                Text(location.airportCode)
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

struct AddLocationView: View {
    @Binding var locations: [Location]
    @Environment(\.dismiss) private var dismiss
    
    @State private var cityName = ""
    @State private var airportCode = ""
    @State private var countryCode = "US"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Location Details")) {
                    TextField("City Name", text: $cityName)
                    TextField("Airport Code (e.g., JFK)", text: $airportCode)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: airportCode) { newValue in
                            airportCode = String(newValue.prefix(3)).uppercased()
                        }
                    
                    Picker("Country", selection: $countryCode) {
                        Text("United States").tag("US")
                        Text("Canada").tag("CA")
                        Text("United Kingdom").tag("GB")
                        Text("Germany").tag("DE")
                        Text("France").tag("FR")
                        Text("Other").tag("XX")
                    }
                }
                
                if !cityName.isEmpty && !airportCode.isEmpty {
                    Section {
                        Text("Preview: \(cityName) (\(airportCode))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newLocation = Location(
                            cityName: cityName,
                            airportCode: airportCode,
                            countryCode: countryCode
                        )
                        locations.append(newLocation)
                        dismiss()
                    }
                    .disabled(cityName.isEmpty || airportCode.count != 3)
                }
            }
        }
    }
}

struct LocationsView_Previews: PreviewProvider {
    static var previews: some View {
        LocationsView(meeting: .constant(Meeting()))
    }
}