import SwiftUI

struct BucketTile: View {
    var title: String
    var isCreateNew: Bool = false
    
    var body: some View {
        VStack {
            if isCreateNew {
                Image(systemName: "plus")
                    .font(.largeTitle)
                    .foregroundStyle(.gray)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            } else {
                Text(title)
                    .font(.headline)
            }
        }
        .frame(minWidth: 100, minHeight: 100)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.98)) // Light gray background
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isCreateNew ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(Color.clear), lineWidth: 1)
        )
        // Dashed border for "Create New"? User asked for simple.
        // Let's stick to simple cleanest look.
    }
}

#Preview {
    HStack {
        BucketTile(title: "Criar novo balde", isCreateNew: true)
        BucketTile(title: "Fitness")
    }
    .padding()
}
