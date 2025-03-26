import SwiftUI

struct ApplicationsFolderView: View {
    @EnvironmentObject var securityViewModel: SecurityViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        List {
            // Securities Section
            Section {
                NavigationLink(destination: SecuritiesView()
                    .environmentObject(securityViewModel)
                    .environmentObject(userViewModel)
                    .navigationTitle("Securities")) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "chart.xyaxis.line")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Securities")
                                    .font(.headline)
                                Text("Stocks, bonds, and other assets")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                }
            }
            
            // Portfolios Section
            Section {
                NavigationLink(destination: PortfoliosView()) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.purple.opacity(0.1))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "folder.fill")
                                .font(.title2)
                                .foregroundColor(.purple)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Portfolios")
                                .font(.headline)
                            Text("Track and manage your investments")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // Research Section
            Section {
                NavigationLink(destination: ResearchView()) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Research")
                                .font(.headline)
                            Text("Market analysis and reports")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Portfolios View
struct PortfoliosView: View {
    @State private var searchText = ""
    
    var body: some View {
        List {
            Section {
                TextField("Search portfolios...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.vertical, 8)
            }
            
            Section(header: Text("Your Portfolios")) {
                ForEach(["Retirement", "Growth", "Income"], id: \.self) { portfolio in
                    NavigationLink(destination: Text("\(portfolio) Portfolio Details")) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.accentColor)
                                .frame(width: 30, height: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(portfolio)
                                    .font(.headline)
                                
                                Text("12 assets")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("$124,500")
                                    .font(.headline)
                                
                                Text("+2.3%")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            
            Section {
                Button(action: {
                    // Create new portfolio
                }) {
                    Label("Create New Portfolio", systemImage: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Portfolios")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Edit portfolios
                }) {
                    Text("Edit")
                }
            }
        }
    }
}

// MARK: - Research View
struct ResearchView: View {
    @State private var selectedSegment = 0
    private let segments = ["Reports", "News", "Analysis"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom segmented control
            HStack {
                ForEach(0..<segments.count, id: \.self) { index in
                    Button(action: {
                        withAnimation {
                            selectedSegment = index
                        }
                    }) {
                        Text(segments[index])
                            .fontWeight(selectedSegment == index ? .semibold : .regular)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundColor(selectedSegment == index ? .accentColor : .primary)
                    .background(
                        ZStack {
                            if selectedSegment == index {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.accentColor.opacity(0.1))
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Divider()
                .padding(.top, 8)
            
            // Content based on selected segment
            TabView(selection: $selectedSegment) {
                // Reports
                List {
                    ForEach(1...5, id: \.self) { index in
                        NavigationLink(destination: Text("Research Report \(index)")) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Quarterly Market Report \(index)")
                                        .font(.headline)
                                    
                                    Text("Q\(index) 2023")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.down.circle")
                                    .foregroundColor(.accentColor)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .tag(0)
                
                // News
                List {
                    ForEach(1...5, id: \.self) { index in
                        NavigationLink(destination: Text("News \(index)")) {
                            HStack {
                                Image(systemName: "newspaper.fill")
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Market Update \(index)")
                                        .font(.headline)
                                    
                                    Text("\(index)h ago")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .tag(1)
                
                // Analysis
                List {
                    ForEach(1...5, id: \.self) { index in
                        NavigationLink(destination: Text("Analysis \(index)")) {
                            HStack {
                                Image(systemName: "chart.pie.fill")
                                    .foregroundColor(.purple)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Sector Analysis \(index)")
                                        .font(.headline)
                                    
                                    Text("Technology")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Research")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Filter
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ApplicationsFolderView()
            .environmentObject(SecurityViewModel())
            .environmentObject(UserViewModel())
    }
} 