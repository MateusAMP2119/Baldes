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
            Tab(value: AppTab.agenda) {
                NavigationStack {
                    HomeView()
                        .baldesToolbar(onProfileTap: { showProfileScreen = true })
                }
            } label: {
                Label("Agenda", systemImage: selectedTab == .agenda ? "text.book.closed.fill" : "text.book.closed")
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
                Label("Stats", systemImage: selectedTab == .stats ? "chart.bar.fill" : "chart.bar")
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
