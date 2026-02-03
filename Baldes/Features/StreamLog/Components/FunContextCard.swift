import SwiftUI

struct FunContextCard: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("💡")
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color("TextPrimary"))
            }
            
            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    FunContextCard(
        title: "Contexto",
        description: "Você já praticou 'Leitura' por 48 horas. Isso equivale a assistir a trilogia O Senhor dos Anéis 4 vezes!"
    )
}
