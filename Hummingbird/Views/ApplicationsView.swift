import SwiftUI

struct ApplicationsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var securityViewModel: SecurityViewModel
    
    private let columns = [
        GridItem(.adaptive(minimum: 170), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Application Folder")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                LazyVGrid(columns: columns, spacing: 16) {
                    NavigationLink(destination: SecuritiesView()
                        .environmentObject(securityViewModel)
                        .navigationTitle("Securities")
                    ) {
                        ApplicationCard(
                            title: "Securities",
                            description: "Market data and securities",
                            iconName: "chart.bar.fill",
                            color: .blue
                        )
                    }
                    
                    // Placeholder for future apps
                    ApplicationCard(
                        title: "Portfolio",
                        description: "Track your holdings",
                        iconName: "briefcase.fill",
                        color: .green
                    )
                    .opacity(0.6)
                    
                    ApplicationCard(
                        title: "News",
                        description: "Financial news",
                        iconName: "newspaper.fill",
                        color: .orange
                    )
                    .opacity(0.6)
                    
                    ApplicationCard(
                        title: "Research",
                        description: "Analyst reports",
                        iconName: "doc.text.magnifyingglass",
                        color: .purple
                    )
                    .opacity(0.6)
                }
                .padding()
            }
        }
    }
}

struct ApplicationCard: View {
    var title: String
    var description: String
    var iconName: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: iconName)
                    .font(.largeTitle)
                    .foregroundColor(color)
                Spacer()
            }
            
            Spacer()
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .frame(height: 150)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SecuritiesView: View {
    @EnvironmentObject var securityViewModel: SecurityViewModel
    
    var body: some View {
        ScrollView {
            if securityViewModel.securities.isEmpty && !securityViewModel.isLoading {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)
                        .padding()
                    
                    Text("No securities found")
                        .font(.headline)
                    
                    Text("Please try again later")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
                .padding()
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(securityViewModel.securities) { security in
                        SecurityCard(security: security, viewModel: securityViewModel)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .refreshable {
            Task {
                await securityViewModel.loadSecurities(token: UserDefaults.standard.string(forKey: "userToken") ?? "")
            }
        }
        .loading(securityViewModel.isLoading, message: "Loading securities...")
        .alert(isPresented: $securityViewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(securityViewModel.error ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                CustomTabHeader(title: "Securities")
            }
        }
    }
}

struct SecurityCard: View {
    let security: Security
    let viewModel: SecurityViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                AsyncImage(url: security.logoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                } placeholder: {
                    Image(systemName: "building.2.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(security.shortName)
                        .font(.headline)
                    
                    Text(security.ticker)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.formatPrice(security.latestPrice?.closeFullAdj))
                        .font(.headline)
                    
                    HStack(spacing: 2) {
                        Text(viewModel.formatReturn(security.latestPrice?.totalReturn))
                            .font(.caption)
                            .foregroundColor(security.latestPrice?.totalReturn ?? 0 >= 0 ? .green : .red)
                    }
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sector")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(security.sectorName)
                        .font(.caption2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Market Cap")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.formatMarketCap(security.latestMktCap?.localCurrencyConsolidatedMarketValue))
                        .font(.caption2)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ApplicationsView()
        .environmentObject(UserViewModel())
        .environmentObject(SecurityViewModel())
} 