//
//  MatchDetailView.swift
//  RoundRobinPro
//
//  Created by Nico Pampaloni on 2/11/25.
//

import SwiftUI

struct MatchDetailView: View {
    let match: Tournament.Match
    var onScoreUpdate: ((Int, Int) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var team1Score: Int
    @State private var team2Score: Int
    @State private var showingAlert = false
    
    init(match: Tournament.Match, onScoreUpdate: ((Int, Int) -> Void)? = nil) {
        self.match = match
        self.onScoreUpdate = onScoreUpdate
        _team1Score = State(initialValue: match.team1Score)
        _team2Score = State(initialValue: match.team2Score)
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Round \(match.round)")
                        .font(.headline)
                        .accessibilityLabel("Round number \(match.round)")
                    
                    if match.team1.name != "Bye" && match.team2.name != "Bye" {
                        Text("Court \(match.courtNumber)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Court number \(match.courtNumber)")
                    }
                }
            }
            
            if match.team1.name != "Bye" && match.team2.name != "Bye" {
                Section("Scores") {
                    ScoreRow(teamName: match.team1.name,
                            score: $team1Score,
                            accessibilityLabel: "\(match.team1.name) score")
                    
                    ScoreRow(teamName: match.team2.name,
                            score: $team2Score,
                            accessibilityLabel: "\(match.team2.name) score")
                }
                
                Section {
                    Button(action: saveScores) {
                        Text("Save Scores")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Section {
                    Text("Bye Round")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Match Details")
        .alert("Invalid Scores", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {
                // No action needed - .cancel role automatically dismisses the alert
            }
        } message: {
            Text("Please enter valid scores for both teams")
        }
    }
    
    private func saveScores() {
        guard team1Score >= 0 && team2Score >= 0 else {
            showingAlert = true
            return
        }
        
        onScoreUpdate?(team1Score, team2Score)
        dismiss()
    }
}

struct ScoreRow: View {
    let teamName: String
    @Binding var score: Int
    let accessibilityLabel: String
    
    var body: some View {
        HStack {
            Text(teamName)
                .font(.headline)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button {
                    score = max(0, score - 1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                        .font(.title2)
                        .padding(1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Decrease \(teamName) score")
                
                Text("\(score)")
                    .frame(minWidth: 32)
                    .font(.title3.bold())
                    .accessibilityLabel(accessibilityLabel)
                
                Button {
                    score += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title2)
                        .padding(1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Increase \(teamName) score")
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    NavigationStack {
        MatchDetailView(
            match: Tournament.Match(
                team1: Tournament.Team(name: "Team A"),
                team2: Tournament.Team(name: "Team B"),
                courtNumber: 1,
                round: 1
            )
        )
    }
}
