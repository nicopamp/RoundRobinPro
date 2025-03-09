//
//  MatchCardView.swift
//  RoundRobinPro
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

struct MatchCardView: View {
    let match: Tournament.Match
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if match.team1.name != "Bye" && match.team2.name != "Bye" {
                Label("Court \(match.courtNumber)", systemImage: "sportscourt.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.gradient)
                    .clipShape(Capsule())
                    .accessibilityLabel("Court \(match.courtNumber)")
                    .accessibilityHint("Displays the court number for this match")
            }
            
            if match.team1.name == "Bye" {
                byeView(teamName: match.team2.name)
            } else if match.team2.name == "Bye" {
                byeView(teamName: match.team1.name)
            } else {
                matchupView
            }
        }
        .padding(12)
        .background(matchBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
    
    private var matchupView: some View {
        HStack {
            Text(match.team1.name)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(teamColor(for: .team1))
            
            if match.isCompleted {
                Text("\(match.team1Score) - \(match.team2Score)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.gradient)
                    .clipShape(Capsule())
            } else {
                Text("vs")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
            }
            
            Text(match.team2.name)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(teamColor(for: .team2))
        }
    }
    
    private func byeView(teamName: String) -> some View {
        HStack {
            Image(systemName: "moon.zzz.fill")
                .foregroundStyle(.purple)
            Text("\(teamName) has a bye")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var matchBackground: some View {
        Group {
            if match.isCompleted {
                Color(.systemBackground)
                    .overlay(
                        Color.green.opacity(0.1)
                    )
            } else {
                Color(.systemBackground)
            }
        }
    }
    
    private enum Team {
        case team1
        case team2
    }
    
    private func teamColor(for team: Team) -> Color {
        guard match.isCompleted else { return .primary }
        
        let isWinner = switch team {
        case .team1: match.team1Score > match.team2Score
        case .team2: match.team2Score > match.team1Score
        }
        
        return isWinner ? .green : .secondary
    }
    
    private var accessibilityLabel: String {
        if match.team1.name == "Bye" {
            return "\(match.team2.name) has a bye in round \(match.round)"
        } else if match.team2.name == "Bye" {
            return "\(match.team1.name) has a bye in round \(match.round)"
        } else if match.isCompleted {
            return "Match completed: \(match.team1.name) \(match.team1Score) versus \(match.team2.name) \(match.team2Score)"
        } else {
            return "Match scheduled: \(match.team1.name) versus \(match.team2.name)"
        }
    }
    
    private var accessibilityHint: String {
        if match.team1.name == "Bye" || match.team2.name == "Bye" {
            return "This is a bye round"
        } else if match.isCompleted {
            let winner = match.team1Score > match.team2Score ? match.team1.name : match.team2.name
            return "\(winner) won this match"
        } else {
            return "Match to be played on court \(match.courtNumber)"
        }
    }
}

#Preview {
    List {
        VStack(spacing: 20) {
            // Regular match preview
            MatchCardView(match: Tournament.sampleData[0].schedule[0])
            
            // Completed match preview
            MatchCardView(match: Tournament.Match(
                team1: Tournament.Team(name: "Team Alpha"),
                team2: Tournament.Team(name: "Team Bravo"),
                courtNumber: 1,
                round: 1,
                isCompleted: true,
                team1Score: 21,
                team2Score: 15
            ))
            
            // Bye match preview
            MatchCardView(match: Tournament.Match(
                team1: Tournament.Team(name: "Bye"),
                team2: Tournament.Team(name: "Team Echo"),
                courtNumber: 0,
                round: 1
            ))
        }
        .padding(.vertical)
    }
    .listStyle(.insetGrouped)
}
