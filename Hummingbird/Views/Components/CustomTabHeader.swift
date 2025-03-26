import SwiftUI

struct CustomTabHeader: View {
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
            
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    CustomTabHeader(title: "Securities")
} 