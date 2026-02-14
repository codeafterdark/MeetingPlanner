/*
 * Nearby Airport Fallback System - How It Works
 * ============================================
 * 
 * The Meeting Planner app includes an intelligent nearby airport fallback system
 * that automatically searches alternative airports when no flights are available
 * from the preferred departure airport.
 * 
 * ## Key Features
 * 
 * ### 1. Automatic Fallback
 * - When no flights are found from the original airport
 * - System searches airports within 60 miles radius
 * - Uses closest airports first (sorted by distance)
 * 
 * ### 2. Comprehensive Airport Database
 * - 60+ major airports in US and internationally
 * - Includes coordinates for distance calculations
 * - Covers major hubs and regional airports
 * 
 * ### 3. Intelligent Distance Calculation
 * - Uses Haversine formula for accurate distances
 * - Calculates great-circle distance between airports
 * - Results in statute miles
 * 
 * ### 4. Transparent Results
 * - Shows original vs alternative airport used
 * - Displays distance from original airport
 * - Includes alternative airport name for clarity
 * 
 * ## Example Scenarios
 * 
 * ### Scenario 1: San Francisco Bay Area
 * Original Airport: SJC (San Jose)
 * Nearby Alternatives within 60 miles:
 * - SFO (San Francisco) - 35 miles
 * - OAK (Oakland) - 28 miles
 * 
 * If no flights from SJC → JFK, system tries:
 * 1. OAK → JFK (closest)
 * 2. SFO → JFK (next closest)
 * 
 * ### Scenario 2: New York Area
 * Original Airport: LGA (LaGuardia)
 * Nearby Alternatives within 60 miles:
 * - JFK (Kennedy) - 15 miles
 * - EWR (Newark) - 18 miles
 * 
 * ### Scenario 3: Washington D.C. Area
 * Original Airport: DCA (Reagan National)
 * Nearby Alternatives within 60 miles:
 * - IAD (Dulles) - 28 miles
 * - BWI (Baltimore) - 45 miles
 * 
 * ## Implementation Benefits
 * 
 * ### Cost Efficiency
 * - Reduces failed searches that waste API calls
 * - Finds alternatives automatically without user intervention
 * - Optimizes API usage through caching
 * 
 * ### User Experience
 * - No manual airport selection required
 * - Clear indication when alternative airports are used
 * - Shows driving distance to alternative airport
 * 
 * ### Business Logic
 * - Maximizes meeting location options
 * - Handles edge cases (remote locations, limited service)
 * - Provides fallback for seasonal route changes
 * 
 * ## Technical Implementation
 * 
 * ### Search Flow
 * 1. Group attendees by home airport (optimization)
 * 2. For each unique route:
 *    a. Try original airport first
 *    b. If no results, find airports within 60 miles
 *    c. Try each nearby airport in distance order
 *    d. Return first successful result
 * 3. Cache results for all attendees from same airport
 * 
 * ### Data Structures
 * - NearbyAirport: Contains code, name, distance, coordinates
 * - AlternativeFlightResult: Original vs alternative airport info
 * - AlternativeAirportInfo: Metadata for UI display
 * 
 * ### UI Integration
 * - SearchResultsView shows alternative airport badges
 * - Distance displayed in miles from original
 * - Orange color coding for alternative airports
 * 
 * ## Configuration
 * 
 * Current Settings:
 * - Search Radius: 60 miles
 * - Airports: 60+ major US and international
 * - Sort Order: Distance (closest first)
 * 
 * ## Example API Usage
 * 
 * ```swift
 * // This is handled automatically in searchAllCombinations
 * let result = try await flightService.searchFlightsWithNearbyFallback(
 *     from: "SJC",
 *     to: "JFK", 
 *     departureDate: meetingStart,
 *     returnDate: meetingEnd
 * )
 * 
 * if let result = result {
 *     if result.alternativeAirport != result.originalAirport {
 *         print("Used alternative: \(result.alternativeAirport)")
 *         print("Distance: \(result.distance) miles")
 *     }
 * }
 * ```
 * 
 * ## Testing
 * 
 * Use the "Test Nearby Airport Search" feature in DataDebugView to:
 * - Enter any airport code
 * - Adjust search radius
 * - See all nearby airports with distances
 * - Test the fallback logic manually
 * 
 * ## Future Enhancements
 * 
 * Potential improvements:
 * - Dynamic radius based on flight availability
 * - Airport preference weighting (hub vs regional)
 * - Drive time vs distance calculations
 * - Integration with ground transportation costs
 */