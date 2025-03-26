    //
//  ContentView.swift
//  Hummingbird
//
//  Created by Boris Paucinac on 3/26/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var userViewModel = UserViewModel()
    @AppStorage("hasSeenWelcomeScreen") private var hasSeenWelcomeScreen = false
    
    var body: some View {
        NavigationStack {
            Group {
                if userViewModel.isAuthenticated {
                    // If user has seen the welcome screen before, go directly to main view
                    if hasSeenWelcomeScreen {
                        MainTabView()
                            .environmentObject(userViewModel)
                    } else {
                        WelcomeView()
                            .environmentObject(userViewModel)
                    }
                } else {
                    LoginView()
                        .environmentObject(userViewModel)
                }
            }
            .animation(.default, value: userViewModel.isAuthenticated)
            .transition(.opacity)
        }
    }
}

#Preview {
    ContentView()
}
