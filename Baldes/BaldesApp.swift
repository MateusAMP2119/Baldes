//
//  BaldesApp.swift
//  Baldes
//
//  Created by Mateus Costa on 18/02/2026.
//

import SwiftUI
import SwiftData

@main
struct BaldesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: HabitEntry.self)
    }
}
