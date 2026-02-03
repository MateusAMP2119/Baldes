import SwiftUI

struct ZeroStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image("Write") // Using existing asset
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .opacity(0.8)
            
            VStack(spacing: 12) {
                Text("Encha o balde!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary"))
                
                Text("Complete sua primeira atividade para desbloquear insights sobre sua jornada.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .padding(.vertical, 40)
    }
}

#Preview {
    ZeroStateView()
}
