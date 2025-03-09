//
//  DetailEditView.swift
//  RoundRobinPro
//
//  Created by Nico Pampaloni on 2/8/25.
//

import SwiftUI

struct DetailEditView: View {
    @Binding var tournament: Tournament
    @State private var newTeamName = ""
    
    var body: some View {
        Form {
            Section(header: Text("Tournament Info")) {
                // Title Field
                TextField("Title", text: $tournament.title)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                // Inline validation for Title
                if tournament.title.isEmpty {
                    Text("A title is required.")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                // Courts slider
                HStack {
                    Slider(value: $tournament.courtsAsDouble, in: 1...10, step: 1) {
                        Text("Courts")
                    }
                    .accessibilityValue("\(tournament.availableCourts) courts")
                    Spacer()
                    Text("\(tournament.availableCourts) courts")
                        .accessibilityHidden(true)
                }
            }
            Section (header: Text("Teams")) {
                // List of teams
                ForEach(tournament.teams) { team in
                    Text(team.name)
                }
                .onDelete { indices in
                    tournament.teams.remove(atOffsets: indices)
                }
                HStack {
                    TextField("New Team", text: $newTeamName)
                    Button(action: {
                        withAnimation {
                            let team = Tournament.Team(name: newTeamName)
                            tournament.teams.append(team)
                            newTeamName = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newTeamName.isEmpty)
                }
                
                // Inline validation for Teams count
                if tournament.teams.count < 2 {
                    Text("At least two teams are required.")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
    }
}

#Preview {
    DetailEditView(tournament: .constant(Tournament.sampleData[0]))
}
