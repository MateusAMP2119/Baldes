//
//  ContentView.swift
//  Baldes
//
//  Created by Mateus Costa on 18/02/2026.
//

import SwiftUI

enum Tab: String, CaseIterable {
    case home, stats, add

    var label: String {
        switch self {
        case .home: return "Home"
        case .stats: return "Stats"
        case .add: return "Add"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .stats: return "chart.bar.fill"
        case .add: return "plus.circle.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: Tab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .stats:
                    Text("Stats")
                case .add:
                    Text("Add")
                }
            }

            // Custom Tab Bar
            HStack {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Spacer()
                    tabButton(tab)
                    Spacer()
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 34)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(Color.black.opacity(0.08)),
                        alignment: .top
                    )
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    private func tabButton(_ tab: Tab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22))
                Text(tab.label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(selectedTab == tab ? Color.accentOrange : Color.tabInactive)
        }
    }
}

#Preview {
    ContentView()
}
