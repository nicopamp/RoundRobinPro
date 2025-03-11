//
//  TournamentView.swift
//  RoundRobinPro
//
//  Created by Nico Pampaloni on 2/8/25.
//

import SwiftUI

// The TournamentsView displays a list of tournaments and provides navigation to details
// as well as the ability to create a new tournament.
struct TournamentsView: View {
    @ObservedObject var store: TournamentStore
    
    // Access the current scene phase (active, inactive, or background) from the environment.
    @Environment(\.scenePhase) private var scenePhase
    
    // State variable to control the presentation of the new tournament sheet.
    @State private var isPresentingNewTournamentView = false
    
    // A closure that is executed to trigger saving of the tournaments.
    // This is passed in from the parent view.
    let saveAction: () -> Void

    var body: some View {
        NavigationStack {
            // List iterates over the tournaments binding array. Each element is passed as a binding.
            List(store.tournaments) { tournament in
                // NavigationLink allows users to tap and navigate to a detail view for each tournament.
                NavigationLink(destination: DetailView(tournament: tournament, store: store)) {
                    // TournamentCardView visually represents the tournament.
                    TournamentCardView(tournament: tournament)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text("Tournaments"))
            // Add a toolbar with a button to create a new tournament.
            .toolbar {
                Button(action: {
                    // When tapped, set the flag to present the new tournament sheet.
                    isPresentingNewTournamentView = true
                }) {
                    // Display a plus icon for adding a new tournament.
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                }
                .accessibilityLabel("New Tournament")
            }
        }
        .sheet(isPresented: $isPresentingNewTournamentView) {
            // NewTournamentSheet is a custom view that handles creation of a new tournament.
            // It is provided with bindings to the tournaments array and the presentation state.
            NewTournamentSheet(
                store: store,
                isPresentingNewTournamentView: $isPresentingNewTournamentView
            )
        }
        // When the scene becomes inactive (e.g., when the app is transitioning to the background),
        // trigger the save action to persist the tournaments data.
        .onChange(of: scenePhase) {
            if scenePhase == .inactive || scenePhase == .background {
                saveAction()
            }
        }
    }
}

#Preview {
    NavigationStack {
        TournamentsView(
            store: {
                let store = TournamentStore()
                // Create a Task to handle async operations
                Task { @MainActor in
                    for tournament in Tournament.sampleData {
                        try? await store.add(tournament)
                    }
                }
                return store
            }(),
            saveAction: {
                // Preview only: Print a message when save is triggered
                print("Preview: Save action triggered")
            }
        )
    }
}
