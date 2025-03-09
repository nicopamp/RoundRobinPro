//
//  NewTournamentSheet.swift
//
//  Created by Nico Pampaloni on 2/10/25.
//

import SwiftUI

struct NewTournamentSheet: View {
    @ObservedObject var store: TournamentStore
    @Binding var isPresentingNewTournamentView: Bool
    
    @State private var title = ""
    @State private var teams = ["", ""]
    @State private var availableCourts = 1.0
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Tournament Info")) {
                    TextField("Title", text: $title)
                    
                    Stepper("Available Courts: \(Int(availableCourts))", 
                           value: $availableCourts, in: 1...10, step: 1)
                }
                
                Section(header: Text("Teams")) {
                    ForEach(teams.indices, id: \.self) { index in
                        TextField("Team Name", text: $teams[index])
                    }
                    .onDelete { indices in
                        teams.remove(atOffsets: indices)
                    }
                    
                    Button(action: {
                        teams.append("")
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Team")
                        }
                    }
                    .disabled(teams.count >= 10)
                }
            }
            .navigationTitle("New Tournament")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") {
                        isPresentingNewTournamentView = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        do {
                            var newTournament = Tournament(
                                title: title,
                                teams: teams.filter { !$0.isEmpty },
                                courts: Int(availableCourts),
                                state: .setup
                            )
                            newTournament.updateSchedule() // Generate initial schedule
                            try store.add(newTournament)
                            isPresentingNewTournamentView = false
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                    .disabled(title.isEmpty || teams.filter { !$0.isEmpty }.count < 2)
                }
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
}

#Preview {
    NewTournamentSheet(store: TournamentStore(), isPresentingNewTournamentView: .constant(true))
}
