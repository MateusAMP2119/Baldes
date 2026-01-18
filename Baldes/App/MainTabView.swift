import SwiftUI

struct MainTabView: View {
    @State private var selection = 0
    @State private var previousSelection = 0
    @State private var showSheet = false
    
    var body: some View {
        TabView(selection: $selection) {
            Tab(value: 0) {
                DashboardView()
            } label : {
                Label("Início", systemImage: "text.rectangle.page")
            }
            
            Tab(value: 1) {
                StreamLogView()
            } label : {
                Label("Histórico", systemImage: "bookmark")
            }
            
            Tab(value: 2, role: .search) {
            } label: {
                Label("Ações", systemImage: "plus")
            }
        }
        .tint(.red)
        .onChange(of: selection) { oldValue, newValue in
            if newValue == 2 {
                showSheet = true
                // Revert to the previous valid tab
                selection = previousSelection
            } else {
                previousSelection = newValue
            }
        }
        .sheet(isPresented: $showSheet) {
            Text("TBD: New Entry Sheet")
                .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    MainTabView()
}
