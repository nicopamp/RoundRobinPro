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
        set { availableCourts = Int(newValue) }
    }
    
    var isCompleted: Bool { state.isCompleted }
    
    var activeTeams: [Team] { teams.filter { $0.name != "Bye" } }
    
    // MARK: - Types
    
    enum TournamentState: Codable, Equatable {
        case setup
        case inProgress(completedMatches: Int, totalMatches: Int)
        case completed(winner: Team?, finalStandings: [Team])
        
        static func == (lhs: TournamentState, rhs: TournamentState) -> Bool {
            switch (lhs, rhs) {
            case (.setup, .setup):
                return true
            case (.inProgress(let lhsCompleted, let lhsTotal),
                  .inProgress(let rhsCompleted, let rhsTotal)):
                return lhsCompleted == rhsCompleted && lhsTotal == rhsTotal
            case (.completed(let lhsWinner, let lhsStandings),
                  .completed(let rhsWinner, let rhsStandings)):
                return lhsWinner == rhsWinner && lhsStandings == rhsStandings
            default:
                return false
            }
        }
        
        var isCompleted: Bool {
            if case .completed(_, _) = self {
                return true
            }
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
        self.availableCourts = courts
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
        let expectedMatches = (activeTeams.count * (activeTeams.count - 1)) / 2
        
        if totalMatches == 0 {
            state = .setup
        } else if completedMatches == totalMatches && completedMatches == expectedMatches {
            // Only complete if we've played all possible matches
            let standings = calculateStandings(from: actualMatches)
            state = .completed(winner: standings.first, finalStandings: standings)
        } else {
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
            if match.team1Score >= 0 && match.team2Score >= 0 {
                if match.team1Score > match.team2Score {
                    standingsDict[match.team1.id]?.wins += 1
                    standingsDict[match.team2.id]?.losses += 1
                } else if match.team2Score > match.team1Score {
                    standingsDict[match.team2.id]?.wins += 1
                    standingsDict[match.team1.id]?.losses += 1
                }
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
            lhs.name == rhs.name
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
        // Create schedule config which may add a bye team
        let config = ScheduleConfig(teams: self.teams, availableCourts: self.availableCourts)
        
        // Update teams array to include bye team if needed
        self.teams = config.workingTeams
        
        // Generate schedule
        self.schedule = generateBalancedSchedule(teams: config.workingTeams, availableCourts: self.availableCourts)
        
        // Update state after schedule generation
        updateState()
    }
}

private struct ScheduleConfig {
    let workingTeams: [Tournament.Team]
    let totalTeams: Int
    let idealRounds: Int
    let matchesPerRound: Int
    let availableCourts: Int
    
    init(teams: [Tournament.Team], availableCourts: Int) {
        var adjustedTeams = teams
        // Add a "Bye" if the number of teams is odd
        if teams.count % 2 != 0 {
            adjustedTeams.append(Tournament.Team(name: "Bye"))
        }
        
        self.workingTeams = adjustedTeams
        self.totalTeams = adjustedTeams.count
        self.idealRounds = adjustedTeams.count - 1
        self.matchesPerRound = adjustedTeams.count / 2
        self.availableCourts = availableCourts
    }
}

private struct RoundPairings {
    let realPairings: [(Int, Int)]
    let byePairings: [(Int, Int)]
}

// Generates pairings for a round using the circle method
private func generateRoundPairings(indices: [Int], matchesPerRound: Int, idealRound: Int) -> [(Int, Int)] {
    var pairings: [(Int, Int)] = []
    let n = indices.count
    
    // First pairing is always between first and last indices
    pairings.append(idealRound % 2 == 0 ? (indices[0], indices[n - 1]) : (indices[n - 1], indices[0]))
    
    // Generate remaining pairings
    for i in 1..<matchesPerRound {
        pairings.append(idealRound % 2 == 0 ? (indices[i], indices[n - 1 - i]) : (indices[n - 1 - i], indices[i]))
    }
    
    return pairings
}

// Separates pairings into real matches and bye matches
private func separatePairings(_ pairings: [(Int, Int)], teams: [Tournament.Team]) -> RoundPairings {
    var realPairings: [(Int, Int)] = []
    var byePairings: [(Int, Int)] = []
    
    for pairing in pairings {
        let teamA = teams[pairing.0]
        let teamB = teams[pairing.1]
        
        if teamA.name != "Bye" && teamB.name != "Bye" {
            realPairings.append(pairing)
        } else {
            byePairings.append(pairing)
        }
    }
    
    return RoundPairings(realPairings: realPairings, byePairings: byePairings)
}

// Creates matches for a session of games
private func createSessionMatches(
    sessionPairings: [(Int, Int)],
    teams: [Tournament.Team],
    round: Int,
    availableCourts: Int
) -> [Tournament.Match] {
    var matches: [Tournament.Match] = []
    var courtIndexForRealMatches = 0
    
    for pairing in sessionPairings {
        var teamA = teams[pairing.0]
        var teamB = teams[pairing.1]
        
        // Ensure bye team is always team1 for consistency
        if teamA.name == "Bye" && teamB.name != "Bye" {
            swap(&teamA, &teamB)
        }
        
        let isByeMatch = (teamA.name == "Bye" || teamB.name == "Bye")
        let courtNumber = isByeMatch ? 0 : (courtIndexForRealMatches % availableCourts) + 1
        
        if !isByeMatch {
            courtIndexForRealMatches += 1
        }
        
        matches.append(Tournament.Match(
            team1: teamA,
            team2: teamB,
            courtNumber: courtNumber,
            round: round
        ))
    }
    
    return matches
}

// Processes a round of matches and creates sessions based on available courts
private func processRound(
    pairings: [(Int, Int)],
    config: ScheduleConfig,
    roundCounter: Int
) -> (matches: [Tournament.Match], nextRound: Int) {
    let roundPairings = separatePairings(pairings, teams: config.workingTeams)
    var matches: [Tournament.Match] = []
    var currentRound = roundCounter
    
    // Calculate number of sessions needed
    let sessionCount = roundPairings.realPairings.isEmpty ? 0 : Int(ceil(Double(roundPairings.realPairings.count) / Double(config.availableCourts)))
    let actualSessions = max(sessionCount, roundPairings.byePairings.isEmpty ? 0 : 1)
    
    // Process each session
    for session in 0..<actualSessions {
        let startIndex = session * config.availableCourts
        let endIndex = min(startIndex + config.availableCourts, roundPairings.realPairings.count)
        let sessionRealPairings = Array(roundPairings.realPairings[startIndex..<endIndex])
        
        var sessionPairings = session == 0 ? roundPairings.byePairings : []
        sessionPairings.append(contentsOf: sessionRealPairings)
        
        let sessionMatches = createSessionMatches(
            sessionPairings: sessionPairings,
            teams: config.workingTeams,
            round: currentRound,
            availableCourts: config.availableCourts
        )
        
        matches.append(contentsOf: sessionMatches)
        
        if !sessionRealPairings.isEmpty {
            currentRound += 1
        }
    }
    
    return (matches: matches, nextRound: currentRound)
}

// Rotates pairings based on the round number if needed
private func rotatePairingsIfNeeded(_ pairings: [(Int, Int)], idealRound: Int, matchesPerRound: Int) -> [(Int, Int)] {
    guard idealRound % matchesPerRound != 0 else { return pairings }
    
    let shift = idealRound % matchesPerRound
    return Array(pairings[shift...] + pairings[..<shift])
}

func generateBalancedSchedule(teams: [Tournament.Team], availableCourts: Int) -> [Tournament.Match] {
    guard !teams.isEmpty else { return [] }
    
    let config = ScheduleConfig(teams: teams, availableCourts: availableCourts)
    var schedule: [Tournament.Match] = []
    var indices = Array(0..<config.totalTeams)
    var currentRound = 1
    
    for idealRound in 0..<config.idealRounds {
        // Generate and rotate pairings
        let basePairings = generateRoundPairings(
            indices: indices,
            matchesPerRound: config.matchesPerRound,
            idealRound: idealRound
        )
        let pairings = rotatePairingsIfNeeded(basePairings, idealRound: idealRound, matchesPerRound: config.matchesPerRound)
        
        // Process the round and get matches
        let (roundMatches, nextRound) = processRound(
            pairings: pairings,
            config: config,
            roundCounter: currentRound
        )
        
        schedule.append(contentsOf: roundMatches)
        currentRound = nextRound
        
        // Rotate indices for next round
        let last = indices.removeLast()
        indices.insert(last, at: 1)
    }
    
    return schedule
}
