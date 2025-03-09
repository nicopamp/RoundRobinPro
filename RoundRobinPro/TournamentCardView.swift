//
//  TournamentCardView.swift
//  RoundRobinPro
//
//  Created by Nico Pampaloni on 2/8/25.
//

import SwiftUI

struct TournamentCardView: View {
    let tournament: Tournament
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(tournament.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
            
            Spacer()
            
            HStack {
                Label {
                    Text("\(tournament.teams.count) teams")
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "person.3.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(tournament.teams.count) teams participating")
                .accessibilityHint("Shows the total number of teams in the tournament")
                
                Spacer()
                
                Label {
                    Text("\(tournament.availableCourts) courts")
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "square.grid.2x2.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(tournament.availableCourts) courts available")
                .accessibilityHint("Shows the number of courts available for matches")
            }
            .font(.caption)
            
            ProgressView(value: tournament.state.progress)
                .tint(progressTint)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(progressLabel)
                .accessibilityValue(progressValueDescription)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemFill), radius: 3, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(tournament.title) Tournament")
    }
    
    private var progressTint: Color {
        if tournament.isCompleted {
            return .green
        } else if tournament.state.progress > 0 {
            return .blue
        } else {
            return .orange
        }
    }
    
    private var progressLabel: String {
        switch tournament.state {
        case .setup:
            return "Tournament not started"
        case .inProgress(let completed, let total):
            return "Tournament Progress: \(completed) of \(total) matches completed"
        case .completed:
            return "Tournament completed"
        }
    }
    
    private var progressValueDescription: String {
        let percentage = Int(tournament.state.progress * 100)
        return "\(percentage)% complete"
    }
}

#Preview {
    List {
        TournamentCardView(tournament: Tournament.sampleData[0])
        TournamentCardView(tournament: Tournament.sampleData[1])
        TournamentCardView(tournament: Tournament.sampleData[2])
    }
    .listStyle(.insetGrouped)
}
