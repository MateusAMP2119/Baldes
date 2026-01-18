import SwiftUI

struct DashboardView: View {
    @State private var searchText = ""
    
    // Sample data for tiles
    let buckets = ["Fitness", "Leitura", "Projectos", "Cozinha"]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text("Actividade")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // Heatmap Section
                    VStack(spacing: 12) {
                        // Date Navigation Header
                        HStack {
                            Button(action: {
                                // Previous month action
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundStyle(.gray)
                            }
                            
                            Spacer()
                            
                            Text("18 Jan 2026") // Dynamic date placeholder
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                // Next month action
                            }) {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.gray)
                                    .opacity(0) // Hidden for today
                            }
                            .disabled(true)
                        }
                        .padding(.horizontal)
                        
                        HeatmapView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                            .background(Color.white) // Inner heatmap background
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search", text: $searchText)
                    }
                    .padding(12)
                    .background(Color(red: 0.98, green: 0.97, blue: 0.95)) // Warmer whitish
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Tiles Grid
                    LazyVGrid(columns: columns, spacing: 15) {
                        // "Create New" Tile
                        BucketTile(title: "Criar novo balde", isCreateNew: true)
                            .onTapGesture {
                                // Action to create new bucket
                            }
                        
                        // Existing Buckets
                        ForEach(buckets, id: \.self) { bucket in
                            BucketTile(title: bucket)
                        }
                    }
                    .padding()
                }
                .padding(.top)
            }
            .background(Color(red: 0.99, green: 0.98, blue: 0.97).ignoresSafeArea()) // Overall warmer background

        }
    }
}

#Preview {
    DashboardView()
}
