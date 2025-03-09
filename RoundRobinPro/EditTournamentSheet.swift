//
//  EditTournamentSheet.swift
//
//  Created by Nico Pampaloni on 2/10/25.
//

import SwiftUI

struct EditTournamentSheet: View {
    @Binding var tournament: Tournament
    @Binding var isPresentingEditView: Bool
    let onSave: (Tournament) -> Void
    
    @State private var editingTitle: String
    @State private var editingTeams: [String]
    @State private var editingCourts: Double
    
    init(tournament: Binding<Tournament>, isPresentingEditView: Binding<Bool>, onSave: @escaping (Tournament) -> Void) {
        self._tournament = tournament
        self._isPresentingEditView = isPresentingEditView
        self.onSave = onSave
        
        // Initialize state with current tournament values
        _editingTitle = State(initialValue: tournament.wrappedValue.title)
        _editingTeams = State(initialValue: tournament.wrappedValue.teams.map { $0.name })
        _editingCourts = State(initialValue: Double(tournament.wrappedValue.availableCourts))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Tournament Info")) {
                    TextField("Title", text: $editingTitle)
                    
                    Stepper("Available Courts: \(Int(editingCourts))", 
                           value: $editingCourts, in: 1...10, step: 1)
                }
                
                Section(header: Text("Teams")) {
                    ForEach(editingTeams.indices, id: \.self) { index in
                        TextField("Team Name", text: $editingTeams[index])
                    }
                    .onDelete { indices in
                        editingTeams.remove(atOffsets: indices)
                    }
                    
                    Button(action: {
                        editingTeams.append("")
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Team")
                        }
                    }
                    .disabled(editingTeams.count >= 10)
                }
            }
            .navigationTitle("Edit Tournament")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresentingEditView = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        var updatedTournament = tournament
                        updatedTournament.title = editingTitle
                        updatedTournament.teams = editingTeams.filter { !$0.isEmpty }.map { Tournament.Team(name: $0) }
                        updatedTournament.availableCourts = Int(editingCourts)
                        updatedTournament.updateSchedule() // Regenerate schedule with new teams/courts
                        tournament = updatedTournament
                        onSave(updatedTournament)
                        isPresentingEditView = false
                    }
                    .disabled(editingTitle.isEmpty || editingTeams.filter { !$0.isEmpty }.count < 2)
                }
            }
        }
    }
}

#Preview {
    EditTournamentSheet(
        tournament: .constant(Tournament.sampleData[0]),
        isPresentingEditView: .constant(true),
        onSave: { _ in }
    )
}
