//
//  RoundRobinProApp.swift
//  RoundRobinPro
//
//  Created by Nico Pampaloni on 2/8/25.
//

import SwiftUI

// The main entry point for the application using SwiftUI's App protocol.
@main
struct RoundRobinProApp: App {
    // A stateful object that manages tournament data.
    @StateObject private var store = TournamentStore()
    // State variable to hold any error message from asynchronous operations.
    @State private var errorMessage: String?
    
    var body: some Scene {
        WindowGroup {
            // TournamentsView is the main view of the app.
            TournamentsView(store: store) {
                // Creates an asynchronous Task to perform the save operation.
                Task {
                    do {
                        // Update to use the parameterless save method
                        try await store.save()
                    } catch {
                        // If an error occurs during saving, update the error message state.
                        errorMessage = error.localizedDescription
                    }
                }
            }
            // Attach an asynchronous task that will be executed when the view appears.
            .task {
                do {
                    // Attempt to load tournaments using the store's asynchronous load method.
                    try await store.load()
                } catch {
                    // On error, update the error message state.
                    errorMessage = error.localizedDescription
                }
            }
            // Attach an alert that is presented whenever errorMessage is non-nil.
            .alert("Error", isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { newValue in if !newValue { errorMessage = nil } }
            )) {
                // A single "OK" button to dismiss the alert.
                Button("OK", role: .cancel) {
                    // No action needed - .cancel role automatically dismisses the alert and errorMessage binding handles state
                }
            } message: {
                // Display the error message or a fallback string.
                Text(errorMessage ?? "An unknown error occurred.")
            }
        }
    }
}
