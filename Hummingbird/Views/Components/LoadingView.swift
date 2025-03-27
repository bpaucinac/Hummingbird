import SwiftUI

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .scaleEffect(1.5)
                .tint(.accentColor)
                .frame(minWidth: 44, minHeight: 44)
            
            Text(message)
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.1)
                .ignoresSafeArea()
            
            VStack {
                LoadingView(message: message)
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
                    .padding(40)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading \(message)")
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
                LoadingOverlay(message: message)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
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
    VStack {
        Text("Content behind loading overlay")
            .font(.title)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .loading(true, message: "Please wait...")
} 
