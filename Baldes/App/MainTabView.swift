import SwiftUI

struct MainTabView: View {
    @State private var selection = 0
    @State private var previousSelection = 0
    @State private var showSheet = false

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                Tab(value: 0) {
                    DashboardView()
                } label: {
                    Label("Actividades", systemImage: "text.rectangle.page")
                }

                Tab(value: 1) {
                    StreamLogView()
                } label: {
                    Label("Histórico", systemImage: "bookmark")
                }

                Tab(value: 2, role: .search) {
                } label: {
                    Label("Ações", systemImage: "plus")
                }
            }
            .tint(Color(red: 0.906, green: 0.365, blue: 0.227))  // #e75d3a
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                }.sharedBackgroundVisibility(.hidden)

                ToolbarItem(placement: .principal) {
                    EmptyView()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(Color("TextPrimary"))
                    }
                }
            }
        }
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
            NewActivityView()
        }
    }

    private var todayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d"
        formatter.locale = Locale(identifier: "pt_PT")
        return formatter.string(from: Date()).capitalized.replacingOccurrences(of: ".", with: "")
    }
}

#Preview {
    MainTabView()
}
