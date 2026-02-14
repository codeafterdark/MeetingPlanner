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
            EnhancedAddLocationView(locations: $meeting.potentialLocations)
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

struct EnhancedAddLocationView: View {
    @Binding var locations: [Location]
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedAirport: AirportData?
    @State private var showManualEntry = false
    @StateObject private var airportSearchService = AirportSearchService(
        apiKey: Config.amadeusAPIKey,
        apiSecret: Config.amadeusAPISecret
    )
    
    // Manual entry fields
    @State private var manualCityName = ""
    @State private var manualAirportCode = ""
    @State private var manualCountryCode = "US"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Search for airports")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter city name (e.g., \"New York\") or state code (e.g., \"CA\" for California)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField("Search city or state...", text: $searchText)
                                .textInputAutocapitalization(.words)
                                .onChange(of: searchText) { newValue in
                                    Task {
                                        await airportSearchService.searchAirports(for: newValue)
                                    }
                                }
                            
                            if airportSearchService.isSearching {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
                
                // Search Results
                if !airportSearchService.searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Airport Results")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(airportSearchService.searchResults) { airport in
                                    AirportResultCard(
                                        airport: airport,
                                        isSelected: selectedAirport?.id == airport.id
                                    ) {
                                        selectedAirport = airport
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else if !searchText.isEmpty && !airportSearchService.isSearching {
                    VStack(spacing: 12) {
                        if let error = airportSearchService.lastError {
                            Label(error, systemImage: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                                .padding()
                        } else {
                            Text("No airports found")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                        
                        Button("Add location manually instead") {
                            showManualEntry = true
                        }
                        .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "airplane.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            Text("Find airports near you")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Search by city name or state code")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Button("Or add location manually") {
                            showManualEntry = true
                        }
                        .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer()
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
                        if let airport = selectedAirport {
                            let newLocation = Location(
                                cityName: airport.address.cityName,
                                airportCode: airport.iataCode,
                                countryCode: airport.address.countryCode
                            )
                            locations.append(newLocation)
                            dismiss()
                        }
                    }
                    .disabled(selectedAirport == nil)
                }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualLocationEntryView(locations: $locations)
            }
        }
    }
}

struct AirportResultCard: View {
    let airport: AirportData
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(airport.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(airport.displayName)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Text(airport.cityAndCountry)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ManualLocationEntryView: View {
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
            .navigationTitle("Manual Entry")
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