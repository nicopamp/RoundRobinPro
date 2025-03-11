//
//  DetailView.swift
//  RoundRobinPro
//
//  Created by Nico Pampaloni on 2/8/25.
//

import SwiftUI

struct DetailView: View {
    let tournament: Tournament
    @ObservedObject var store: TournamentStore
    @State private var isPresentingEditView = false
    @State private var editingTournament: Tournament
    
    init(tournament: Tournament, store: TournamentStore) {
        self.tournament = tournament
        self.store = store
        _editingTournament = State(initialValue: tournament)
    }
    
    var body: some View {
        List {
            tournamentInfoSection
            scheduleSection
        }
        .navigationTitle(tournament.title)
        .toolbar {
            Button("Edit") {
                isPresentingEditView = true
                editingTournament = tournament
            }
        }
        .sheet(isPresented: $isPresentingEditView) {
            editTournamentSheet
        }
    }
    
    private var tournamentInfoSection: some View {
        Section(header: Text("Tournament Info")) {
            HStack {
                Label("Teams", systemImage: "person.3")
                Spacer()
                Text("\(tournament.activeTeams.count)")
            }
            
            HStack {
                Label("Courts", systemImage: "square.grid.2x2")
                Spacer()
                Text("\(tournament.availableCourts)")
            }
        }
    }
    
    private var scheduleSection: some View {
        let matchesByRound = Dictionary(grouping: tournament.schedule) { $0.round }
        let sortedRounds = matchesByRound.keys.sorted()
        
        return ForEach(sortedRounds, id: \.self) { round in
            Section(header: Text("Round \(round)")) {
                if let matches = matchesByRound[round] {
                    ForEach(matches) { match in
                        if match.team1.name == "Bye" || match.team2.name == "Bye" {
                            MatchCardView(match: match)
                        } else {
                            NavigationLink(destination: matchDetailView(for: match)) {
                                MatchCardView(match: match)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func matchDetailView(for match: Tournament.Match) -> some View {
        MatchDetailView(match: match) { team1Score, team2Score in
            var updatedTournament = tournament
            if let matchIndex = updatedTournament.schedule.firstIndex(where: { $0.id == match.id }) {
                updatedTournament.schedule[matchIndex].team1Score = team1Score
                updatedTournament.schedule[matchIndex].team2Score = team2Score
                updatedTournament.schedule[matchIndex].isCompleted = true
                Task {
                    do {
                        try await store.update(updatedTournament)
                    } catch {
                        print("Error updating tournament: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private var editTournamentSheet: some View {
        NavigationStack {
            EditTournamentSheet(
                tournament: $editingTournament,
                isPresentingEditView: $isPresentingEditView,
                onSave: { updatedTournament in
                    Task {
                        do {
                            try await store.update(updatedTournament)
                        } catch {
                            print("Error updating tournament: \(error.localizedDescription)")
                        }
                    }
                }
            )
            .navigationTitle(tournament.title)
        }
    }
}

#Preview {
    NavigationStack {
        DetailView(
            tournament: Tournament.sampleData[0],
            store: TournamentStore()
        )
    }
}
