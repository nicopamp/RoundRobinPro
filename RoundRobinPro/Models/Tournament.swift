//
//  Tournament.swift
//  RoundRobinPro
//
//  Created by Nico Pampaloni on 2/8/25.
//

import Foundation

struct Tournament: Identifiable, Codable {
    let id: UUID
    var title: String
    var teams: [Team]
    var schedule: [Match]
    var availableCourts: Int
    private(set) var state: TournamentState
    
    // MARK: - Computed Properties
    
    var courtsAsDouble: Double {
        get { Double(availableCourts) }
        set { availableCourts = max(1, Int(newValue)) }  // Ensure minimum of 1 court
    }
    
    var isCompleted: Bool { state.isCompleted }
    
    var activeTeams: [Team] { teams.filter { $0.name != "Bye" } }
    
    // MARK: - Types
    
    enum TournamentState: Codable {
        case setup
        case inProgress(completedMatches: Int, totalMatches: Int)
        case completed(winner: Team?, finalStandings: [Team])
        
        var isCompleted: Bool {
            if case .completed(_, _) = self { return true }
            return false
        }
        
        var progress: Double {
            switch self {
            case .setup: return 0.0
            case .inProgress(let completed, let total):
                return total > 0 ? Double(completed) / Double(total) : 0.0
            case .completed: return 1.0
            }
        }
    }
    
    // MARK: - Initialization
    
    init(id: UUID = UUID(), title: String, teams: [String], matches: [Match] = [], courts: Int, state: TournamentState = .setup) {
        self.id = id
        self.title = title
        self.teams = teams.map { Team(name: $0) }
        self.schedule = matches
        self.availableCourts = max(1, courts)
        self.state = state
        
        if !matches.isEmpty {
            updateState()
        }
    }
    
    // MARK: - State Management
    
    mutating func updateState() {
        let actualMatches = schedule.filter { !$0.isByeMatch }
        let totalMatches = actualMatches.count
        let completedMatches = actualMatches.filter(\.isCompleted).count
        
        switch completedMatches {
        case 0:
            state = .setup
        case totalMatches:
            let standings = calculateStandings(from: actualMatches)
            state = .completed(winner: standings.first, finalStandings: standings)
        default:
            state = .inProgress(completedMatches: completedMatches, totalMatches: totalMatches)
        }
    }
    
    private func calculateStandings(from matches: [Match]) -> [Team] {
        var standingsDict = [UUID: Team]()
        
        // Initialize standings with active teams
        for team in activeTeams {
            standingsDict[team.id] = team
        }
        
        // Update wins and losses
        for match in matches where match.isCompleted {
            if match.team1Score > match.team2Score {
                standingsDict[match.team1.id]?.wins += 1
                standingsDict[match.team2.id]?.losses += 1
            } else if match.team2Score > match.team1Score {
                standingsDict[match.team2.id]?.wins += 1
                standingsDict[match.team1.id]?.losses += 1
            }
        }
        
        // Sort by wins (descending)
        return standingsDict.values.sorted { $0.wins > $1.wins }
    }
}

// MARK: - Team

extension Tournament {
    struct Team: Identifiable, Codable, Equatable {
        let id: UUID
        var name: String
        var wins: Int
        var losses: Int
        
        init(id: UUID = UUID(), name: String, wins: Int = 0, losses: Int = 0) {
            self.id = id
            self.name = name
            self.wins = wins
            self.losses = losses
        }
        
        static func == (lhs: Team, rhs: Team) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    static var emptyTournament: Tournament {
        Tournament(title: "", teams: [], courts: 1, state: .setup)
    }
}

// MARK: - Match

extension Tournament {
    struct Match: Identifiable, CustomStringConvertible, Codable {
        let id: UUID
        var team1: Team
        var team2: Team
        var team1Score: Int
        var team2Score: Int
        var courtNumber: Int
        var round: Int
        var isCompleted: Bool
        
        var isByeMatch: Bool {
            team1.name == "Bye" || team2.name == "Bye"
        }
        
        var description: String {
            if team1.name == "Bye" {
                return "Round \(round): \(team2.name) is on bye"
            } else if team2.name == "Bye" {
                return "Round \(round): \(team1.name) is on bye"
            }
            return "Round \(round), Court \(courtNumber): \(team1.name) vs. \(team2.name)"
        }
        
        init(id: UUID = UUID(), team1: Team, team2: Team, courtNumber: Int, round: Int, isCompleted: Bool = false, team1Score: Int = 0, team2Score: Int = 0) {
            self.id = id
            self.team1 = team1
            self.team2 = team2
            self.team1Score = team1Score
            self.team2Score = team2Score
            self.courtNumber = courtNumber
            self.round = round
            self.isCompleted = isCompleted
        }
    }
}

// MARK: - Schedule Generation

extension Tournament {
    mutating func updateSchedule() {
        self.schedule = generateBalancedSchedule(teams: self.teams, availableCourts: self.availableCourts)
    }
}

// Generates pairings for a round using the circle method.
private func generateRoundPairings(indices: [Int], matchesPerRound: Int, idealRound: Int) -> [(Int, Int)] {
    var pairings: [(Int, Int)] = []
    let n = indices.count
    for i in 0..<matchesPerRound {
        let first = (i == 0) ? indices[0] : indices[i]
        let second = (i == 0) ? indices[n - 1] : indices[n - 1 - i]
        pairings.append(idealRound % 2 == 0 ? (first, second) : (second, first))
    }
    return pairings
}

// Rotates the pairing array by a given shift.
private func rotatePairings(_ pairings: [(Int, Int)], shift: Int) -> [(Int, Int)] {
    return Array(pairings[shift...] + pairings[..<shift])
}

func generateBalancedSchedule(teams: [Tournament.Team], availableCourts: Int) -> [Tournament.Match] {
    // Return an empty schedule if no teams are provided.
    guard !teams.isEmpty else { return [] }
    
    var workingTeams = teams
    // Add a "Bye" if the number of teams is odd.
    if workingTeams.count % 2 != 0 {
        workingTeams.append(Tournament.Team(name: "Bye"))
    }
    
    let n = workingTeams.count
    let idealRounds = n - 1
    let matchesPerRound = n / 2
    var schedule: [Tournament.Match] = []
    var indices = Array(0..<n)
    var actualRoundCounter = 1
    
    for idealRound in 0..<idealRounds {
        let pairings = generateRoundPairings(indices: indices, matchesPerRound: matchesPerRound, idealRound: idealRound)
        let shift = idealRound % matchesPerRound
        let shiftedPairings = rotatePairings(pairings, shift: shift)
        
        // Separate real matches and bye matches.
        let realPairings = shiftedPairings.filter { pairing in
            let teamA = workingTeams[pairing.0]
            let teamB = workingTeams[pairing.1]
            return teamA.name != "Bye" && teamB.name != "Bye"
        }
        let byePairings = shiftedPairings.filter { pairing in
            let teamA = workingTeams[pairing.0]
            let teamB = workingTeams[pairing.1]
            return teamA.name == "Bye" || teamB.name == "Bye"
        }
        
        let sessionCount = realPairings.isEmpty ? 0 : Int(ceil(Double(realPairings.count) / Double(availableCourts)))
        let actualSessions = max(sessionCount, byePairings.isEmpty ? 0 : 1)
        
        for session in 0..<actualSessions {
            let startIndex = session * availableCourts
            let endIndex = min(startIndex + availableCourts, realPairings.count)
            let sessionRealPairings = Array(realPairings[startIndex..<endIndex])
            
            var sessionPairings: [(Int, Int)] = []
            if session == 0 {
                sessionPairings.append(contentsOf: byePairings)
            }
            sessionPairings.append(contentsOf: sessionRealPairings)
            
            var courtIndexForRealMatches = 0
            for pairing in sessionPairings {
                var teamA = workingTeams[pairing.0]
                var teamB = workingTeams[pairing.1]
                if teamA.name == "Bye" && teamB.name != "Bye" {
                    swap(&teamA, &teamB)
                }
                let isByeMatch = (teamA.name == "Bye" || teamB.name == "Bye")
                let courtNumber = isByeMatch ? 0 : (courtIndexForRealMatches % availableCourts) + 1
                if !isByeMatch { courtIndexForRealMatches += 1 }
                
                let match = Tournament.Match(team1: teamA, team2: teamB, courtNumber: courtNumber, round: actualRoundCounter)
                schedule.append(match)
            }
            if !sessionRealPairings.isEmpty {
                actualRoundCounter += 1
            }
        }
        
        // Rotate indices: move last element to position 1.
        let last = indices.removeLast()
        indices.insert(last, at: 1)
    }
    
    return schedule
}

extension Tournament {
    static let sampleData: [Tournament] = [
        Tournament(
            title: "Nationals 2025",
            teams: ["Team Alpha", "Team Bravo", "Team Charlie", "Team Delta"],
            matches: [
                Tournament.Match(
                    team1: Tournament.Team(name: "Team Alpha"),
                    team2: Tournament.Team(name: "Team Bravo"),
                    courtNumber: 1,
                    round: 1
                ),
                Tournament.Match(
                    team1: Tournament.Team(name: "Team Charlie"),
                    team2: Tournament.Team(name: "Team Delta"),
                    courtNumber: 1,
                    round: 2
                ),
                Tournament.Match(
                    team1: Tournament.Team(name: "Team Alpha"),
                    team2: Tournament.Team(name: "Team Charlie"),
                    courtNumber: 1,
                    round: 3
                ),
                Tournament.Match(
                    team1: Tournament.Team(name: "Team Bravo"),
                    team2: Tournament.Team(name: "Team Delta"),
                    courtNumber: 1,
                    round: 4
                )
            ],
            courts: 1,
            state: .setup
        ),
        Tournament(
            title: "Regionals 2025",
            teams: ["Team Echo", "Team Foxtrot", "Team Golf", "Team Hotel"],
            matches: [
                Tournament.Match(
                    team1: Tournament.Team(name: "Team Echo"),
                    team2: Tournament.Team(name: "Team Foxtrot"),
                    courtNumber: 1,
                    round: 1
                ),
                Tournament.Match(
                    team1: Tournament.Team(name: "Team Golf"),
                    team2: Tournament.Team(name: "Team Hotel"),
                    courtNumber: 2,
                    round: 1
                ),
                Tournament.Match(
                    team1: Tournament.Team(name: "Team Echo"),
                    team2: Tournament.Team(name: "Team Golf"),
                    courtNumber: 1,
                    round: 2
                ),
                Tournament.Match(
                    team1: Tournament.Team(name: "Team Foxtrot"),
                    team2: Tournament.Team(name: "Team Hotel"),
                    courtNumber: 2,
                    round: 2
                )
            ],
            courts: 2,
            state: .setup
        ),
        Tournament(
            title: "District 2025",
            teams: ["Team India", "Team Juliett", "Team Kilo"],
            matches: [
                Tournament.Match(
                    team1: Tournament.Team(name: "Team India"),
                    team2: Tournament.Team(name: "Team Juliett"),
                    courtNumber: 1,
                    round: 1
                ),
                Tournament.Match(
                    team1: Tournament.Team(name: "Team India"),
                    team2: Tournament.Team(name: "Team Kilo"),
                    courtNumber: 1,
                    round: 2
                ),
                Tournament.Match(
                    team1: Tournament.Team(name: "Team Juliett"),
                    team2: Tournament.Team(name: "Team Kilo"),
                    courtNumber: 1,
                    round: 3
                )
            ],
            courts: 1,
            state: .setup
        )
    ]
}
