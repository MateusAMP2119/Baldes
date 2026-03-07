//
//  BaldesApp.swift
//  Baldes
//
//  Created by Mateus Costa on 18/02/2026.
//

import SwiftData
import SwiftUI

@main
struct BaldesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appRouter = AppRouter()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appRouter)
                .preferredColorScheme(.light)
        }
        .modelContainer(for: HabitEntry.self)
    }
}
