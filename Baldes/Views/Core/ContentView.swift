//
//  ContentView.swift
//  Baldes
//
//  Created by Mateus Costa on 18/02/2026.
//

import SwiftUI

enum AppTab: Hashable {
    case agenda
    case add
    case stats
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .agenda
    @State private var showAddScreen = false
    @State private var showProfileScreen = false

    /// Intercepts the "Add" tab so `selectedTab` never actually changes to `.add`.
    /// This prevents the NavigationStack from tearing down and losing pushed views.
    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == .add {
                    showAddScreen = true
                } else {
                    selectedTab = newValue
                }
            }
        )
    }

    var body: some View {
        TabView(selection: tabSelection) {
            Tab("Agenda", systemImage: "text.book.closed", value: AppTab.agenda) {
                NavigationStack {
                    HomeView()
                        .baldesToolbar(onProfileTap: { showProfileScreen = true })
                }
            }

            Tab("Add", systemImage: "plus", value: AppTab.add, role: .search) {
                Color.clear
            }

            Tab("Stats", systemImage: "chart.bar", value: AppTab.stats) {
                NavigationStack {
                    StatsView()
                        .baldesToolbar(onProfileTap: { showProfileScreen = true })
                }
            }
        }
        .environment(\.symbolVariants, .none)
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
