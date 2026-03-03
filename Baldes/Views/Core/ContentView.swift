//
//  ContentView.swift
//  Baldes
//
//  Created by Mateus Costa on 18/02/2026.
//

import SwiftData
import SwiftUI

enum AppTab: Hashable {
    case agenda
    case add
    case stats
}

struct ContentView: View {
    @Environment(AppRouter.self) private var appRouter
    @Environment(\.modelContext) private var modelContext

    @State private var showAddScreen = false
    @State private var showProfileScreen = false

    /// Intercepts the "Add" tab so `appRouter.selectedTab` never actually changes to `.add`.
    /// This prevents the NavigationStack from tearing down and losing pushed views.
    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { appRouter.selectedTab },
            set: { newValue in
                if newValue == .add {
                    showAddScreen = true
                } else {
                    appRouter.selectedTab = newValue
                }
            }
        )
    }

    var body: some View {
        @Bindable var router = appRouter

        TabView(selection: tabSelection) {
            Tab(value: AppTab.agenda) {
                NavigationStack(path: $router.homeNavigationPath) {
                    HomeView()
                        .baldesToolbar(onProfileTap: { showProfileScreen = true })
                }
            } label: {
                Label(
                    "Agenda",
                    systemImage: appRouter.selectedTab == .agenda
                        ? "text.book.closed.fill" : "text.book.closed"
                )
                .environment(\.symbolVariants, .none)
            }

            Tab("Add", systemImage: "plus", value: AppTab.add, role: .search) {
                Color.clear
            }

            Tab(value: AppTab.stats) {
                NavigationStack {
                    StatsView()
                        .baldesToolbar(onProfileTap: { showProfileScreen = true })
                }
            } label: {
                Label(
                    "Stats",
                    systemImage: appRouter.selectedTab == .stats ? "chart.bar.fill" : "chart.bar"
                )
                .environment(\.symbolVariants, .none)
            }
        }
        .tint(.accentOrange)
        .sheet(isPresented: $showAddScreen) {
            NavigationStack {
                AddHabitView(dismissSheet: { showAddScreen = false })
            }
        }
        .sheet(isPresented: $showProfileScreen) {
            NavigationStack {
                ProfileView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didReceiveDeepLink)) { notification in
            if let userInfo = notification.userInfo,
                let habitID = userInfo["habitID"] as? UUID
            {

                // Fetch the habit to append to the navigation path
                let descriptor = FetchDescriptor<HabitEntry>(
                    predicate: #Predicate { $0.id == habitID })
                if let habit = try? modelContext.fetch(descriptor).first {

                    // Switch to Agenda tab and show details
                    appRouter.selectedTab = .agenda
                    appRouter.homeNavigationPath.append(habit)

                    // Dismiss any sheets that might be blocking the view
                    showAddScreen = false
                    showProfileScreen = false
                }
            }
        }
    }
}

// MARK: - Shared Toolbar

struct BaldesToolbarModifier: ViewModifier {
    let onProfileTap: () -> Void

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onProfileTap()
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .tint(.textPrimary)
                }
            }
            .toolbarBackground(.automatic, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
    }
}

extension View {
    func baldesToolbar(onProfileTap: @escaping () -> Void = {}) -> some View {
        modifier(BaldesToolbarModifier(onProfileTap: onProfileTap))
    }
}

#Preview {
    ContentView()
}
