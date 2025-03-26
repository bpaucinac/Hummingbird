import SwiftUI

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        LoadingView(message: message)
            .background(.ultraThinMaterial)
            .ignoresSafeArea()
    }
}

struct LoadingViewModifier: ViewModifier {
    let isLoading: Bool
    let message: String
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 2 : 0)
            
            if isLoading {
                LoadingView(message: message)
            }
        }
    }
}

extension View {
    func loading(_ isLoading: Bool, message: String = "Loading...") -> some View {
        modifier(LoadingViewModifier(isLoading: isLoading, message: message))
    }
}

#Preview {
    LoadingView(message: "Loading...")
} 
