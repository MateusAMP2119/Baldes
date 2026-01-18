import SwiftUI

struct DashboardView: View {
    @State private var showingNewActivitySheet = false
    
    var body: some View {
        ZStack {
            // Background color
            Color.white.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                headerView
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // Content
                activitiesEmptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar(.hidden, for: .navigationBar) // Hide default nav bar
        .sheet(isPresented: $showingNewActivitySheet) {
            NewActivityView()
        }
    }
    
    // MARK: - Views
    
    private var headerView: some View {
        HStack {
            Text("Activities")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.black)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
            }
        }
    }
    
    private var activitiesEmptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // Empty State Image
            Image("Empty")
                .resizable()
                .scaledToFill()
                .frame(width: 220, height: 220)
                .clipped()
                .cornerRadius(20)
            
            VStack(spacing: 8) {
                Text("Sem Baldes criados!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                
                Text("Vamos criar um novo Balde para começar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 16)
            
            // 3D Button "Add Activity"
            Button(action: { showingNewActivitySheet = true }) {
                Text("Novo Balde")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        ZStack {
                            // Shadow/Depth layer
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.906, green: 0.365, blue: 0.227)) // #e75d3a
                                .offset(y: 4)
                            
                            // Top layer
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .stroke(Color.black, lineWidth: 1)
                        }
                    )
            }
            .buttonStyle(PlainButtonStyle()) // Prevent default opacity effect on press if desired
            
            // Demo Link
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("Ver exemplos")
                }
                .font(.subheadline)
                .foregroundStyle(.gray)
                .padding(.top, 8)
            }
            
            Spacer()
        }
    }
}

#Preview {
    DashboardView()
}
