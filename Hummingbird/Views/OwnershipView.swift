import SwiftUI

struct OwnershipView: View {
    @StateObject private var viewModel = OwnershipViewModel()
    @State private var selectedFiler: Filer? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header styled like Stocks app
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Ownership")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.leading)
                    
                    Spacer()
                }
                .padding(.bottom, 4)
                
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(.systemGray4))
            }
            
            // Always show the tab view since we have a hardcoded token
            OwnershipTabView(viewModel: viewModel, selectedFiler: $selectedFiler)
        }
        .sheet(item: $selectedFiler) { filer in
            FilerDetailView(filer: filer)
        }
        .task {
            // Load filers when view appears
            await viewModel.loadFilers()
        }
    }
}

// MARK: - Ownership Tab View
struct OwnershipTabView: View {
    @ObservedObject var viewModel: OwnershipViewModel
    @Binding var selectedFiler: Filer?
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack(spacing: 0) {
                tabButton(title: "Filers", index: 0)
                tabButton(title: "Holdings", index: 1)
                tabButton(title: "Activity", index: 2)
            }
            .padding(.top, 8)
            
            Divider()
            
            // Tab content
            TabView(selection: $selectedTab) {
                // Filers tab
                FilerListView(viewModel: viewModel)
                    .tag(0)
                
                // Holdings tab (placeholder)
                VStack {
                    Spacer()
                    Text("Holdings View")
                        .font(.headline)
                    Text("Coming soon")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .tag(1)
                
                // Activity tab (placeholder)
                VStack {
                    Spacer()
                    Text("Activity View")
                        .font(.headline)
                    Text("Coming soon")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
    
    // MARK: - Tab Button
    private func tabButton(title: String, index: Int) -> some View {
        Button {
            withAnimation {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(selectedTab == index ? .primary : .secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                
                // Indicator bar
                Rectangle()
                    .frame(height: 3)
                    .foregroundColor(selectedTab == index ? .accentColor : .clear)
                    .animation(.easeInOut, value: selectedTab)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Filer Detail View
struct FilerDetailView: View {
    let filer: Filer
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header with filer name and AUM
                    VStack(alignment: .leading, spacing: 8) {
                        Text(filer.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack {
                            Text("Assets Under Management:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(filer.formattedAUM)
                                .font(.headline)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Divider
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(.systemGray5))
                    
                    // Filer Information
                    VStack(alignment: .leading, spacing: 16) {
                        // Identification
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Identification")
                                .font(.headline)
                            
                            DetailRow(label: "ID", value: filer.externalId1 ?? "N/A")
                            DetailRow(label: "Secondary ID", value: filer.externalId2 ?? "N/A")
                            DetailRow(label: "Type", value: filer.type ?? "N/A")
                        }
                        
                        // Contact Information
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contact Information")
                                .font(.headline)
                            
                            if let address1 = filer.addressLine1 {
                                DetailRow(label: "Address", value: address1)
                            }
                            
                            if let address2 = filer.addressLine2 {
                                DetailRow(label: "Address Line 2", value: address2)
                            }
                            
                            if let city = filer.city, let country = filer.country {
                                DetailRow(label: "Location", value: "\(city.capitalized), \(country)")
                            }
                            
                            DetailRow(label: "Phone", value: filer.phone ?? "N/A")
                            DetailRow(label: "Website", value: filer.website ?? "N/A")
                        }
                        
                        // Filing Information
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Filing Information")
                                .font(.headline)
                            
                            DetailRow(label: "Latest Report", value: filer.formattedDate)
                            
                            if let priorDate = filer.dateOfPriorReport {
                                DetailRow(label: "Prior Report", value: priorDate)
                            }
                            
                            DetailRow(label: "Status", value: filer.isActive ? "Active" : "Inactive")
                        }
                        
                        // Holdings section (placeholder)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Top Holdings")
                                .font(.headline)
                            
                            Text("Holdings information coming soon")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
            
            Spacer()
        }
    }
} 