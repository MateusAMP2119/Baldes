import SwiftUI

struct MainTabView: View {
    @State private var selection = 0
    @State private var previousSelection = 0
    @State private var showSheet = false

    var body: some View {
        TabView(selection: $selection) {
            Tab(value: 0) {
                NavigationStack {
                    DashboardView()
                        .mainToolbar()
                }
            } label: {
                Label("Agenda", systemImage: selection == 0 ? "text.book.closed.fill" : "text.book.closed")
                    .environment(\.symbolVariants, .none)
            }

            Tab(value: 1) {
                NavigationStack {
                    StreamLogView()
                        .mainToolbar()
                }
            } label: {
                Label("Atividade", systemImage: selection == 1 ? "list.bullet.rectangle.fill" : "list.bullet.rectangle")
                    .environment(\.symbolVariants, .none)
            }

            Tab(value: 2, role: .search) {
            }
            label: {
                Label("Ações", systemImage: selection == 2 ? "plus.circle.fill" : "plus")
                    .environment(\.symbolVariants, .none)
            }
        }
        .tint(Color(red: 0.906, green: 0.365, blue: 0.227))  // #e75d3a
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

extension View {
    func mainToolbar() -> some View {
        self.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
            }

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
}

#Preview {
    MainTabView()
}
