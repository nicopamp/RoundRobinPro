//
//  RoundRobinProTests.swift
//  RoundRobinProTests
//
//  Created by Nico Pampaloni on 3/10/25.
//

import Testing
@testable import RoundRobinPro

struct RoundRobinProTests {

    // MARK: - Tournament Initialization Tests
    
    @Test func testTournamentInitialization() async throws {
        let title = "Test Tournament"
        let teams = ["Team 1", "Team 2", "Team 3", "Team 4"]
        let tournament = Tournament(title: title, teams: teams, courts: 2)
        
        #expect(tournament.title == title)
        #expect(tournament.teams.count == teams.count)
        #expect(tournament.availableCourts == 2)
        #expect(tournament.state == .setup)
        #expect(tournament.schedule.isEmpty)
    }
    
    @Test func testTournamentWithOddNumberOfTeams() async throws {
        let teams = ["Team 1", "Team 2", "Team 3"]
        var tournament = Tournament(title: "Odd Teams", teams: teams, courts: 1)
        
        // Verify initial state
        #expect(!tournament.teams.map { $0.name }.contains("Bye"))
        #expect(tournament.teams.count == teams.count)
        
        // Generate schedule
        tournament.updateSchedule()
        
        // Verify bye team was added
        #expect(tournament.teams.map { $0.name }.contains("Bye"))
        #expect(tournament.activeTeams.count == teams.count)
        #expect(tournament.teams.count == teams.count + 1)
    }
    
    // MARK: - Schedule Generation Tests
    
    @Test func testScheduleGeneration() async throws {
        let teams = ["Team 1", "Team 2", "Team 3", "Team 4"]
        var tournament = Tournament(title: "Schedule Test", teams: teams, courts: 2)
        tournament.updateSchedule()
        
        let expectedMatches = (teams.count * (teams.count - 1)) / 2 // n(n-1)/2 for complete round robin
        #expect(!tournament.schedule.isEmpty)
        #expect(tournament.schedule.filter { !$0.isByeMatch }.count == expectedMatches)
    }
    
    @Test func testCourtAssignment() async throws {
        let teams = ["Team 1", "Team 2", "Team 3", "Team 4"]
        var tournament = Tournament(title: "Courts Test", teams: teams, courts: 2)
        tournament.updateSchedule()
        
        // Check that no match is assigned to a court number higher than available courts
        #expect(tournament.schedule.allSatisfy { $0.courtNumber <= tournament.availableCourts })
    }
    
    // MARK: - Match Management Tests
    
    @Test func testMatchCompletion() async throws {
        let teams = ["Team 1", "Team 2", "Team 3"]
        var tournament = Tournament(title: "Match Test", teams: teams, courts: 1)
        tournament.updateSchedule()
        
        // Verify initial state
        #expect(tournament.state == .inProgress(completedMatches: 0, totalMatches: 3))
        
        // Complete first non-bye match
        guard let firstMatch = tournament.schedule.first(where: { !$0.isByeMatch }) else {
            throw TestError("Expected to find a non-bye match")
        }
        
        var updatedMatch = firstMatch
        updatedMatch.team1Score = 21
        updatedMatch.team2Score = 15
        updatedMatch.isCompleted = true
        
        // Update match and verify state
        if let matchIndex = tournament.schedule.firstIndex(where: { $0.id == firstMatch.id }) {
            tournament.schedule[matchIndex] = updatedMatch
            tournament.updateState()
            
            let nonByeMatches = tournament.schedule.filter { !$0.isByeMatch }
            let completedMatches = nonByeMatches.filter(\.isCompleted)
            let totalExpectedMatches = (teams.count * (teams.count - 1)) / 2
            
            #expect(nonByeMatches.count == totalExpectedMatches)
            #expect(completedMatches.count == 1)
            
            if case .inProgress(let completed, let total) = tournament.state {
                #expect(completed == 1)
                #expect(total == totalExpectedMatches)
            } else {
                throw TestError("Tournament should be in progress")
            }
        } else {
            throw TestError("Could not find match to update")
        }
    }
    
    // MARK: - Tournament State Tests
    
    @Test func testTournamentCompletion() async throws {
        let teams = ["Team 1", "Team 2"]
        var tournament = Tournament(title: "Completion Test", teams: teams, courts: 1)
        tournament.updateSchedule()
        
        // Complete all non-bye matches
        for i in 0..<tournament.schedule.count {
            if !tournament.schedule[i].isByeMatch {
                var match = tournament.schedule[i]
                match.team1Score = 21
                match.team2Score = 15
                match.isCompleted = true
                tournament.schedule[i] = match
            }
        }
        tournament.updateState()
        
        #expect(tournament.isCompleted)
        if case .completed(let winner, let standings) = tournament.state {
            #expect(winner != nil)
            #expect(standings.count == 2)
            #expect(standings[0].wins == 1)
            #expect(standings[1].losses == 1)
        } else {
            throw TestError("Expected tournament to be completed")
        }
    }
    
    // MARK: - Team Management Tests
    
    @Test func testTeamStandings() async throws {
        let teams = ["Team 1", "Team 2", "Team 3", "Team 4"]
        var tournament = Tournament(title: "Standings Test", teams: teams, courts: 2)
        tournament.updateSchedule()
        
        // Complete all non-bye matches
        for i in 0..<tournament.schedule.count {
            var match = tournament.schedule[i]
            if !match.isByeMatch {
                match.team1Score = 21
                match.team2Score = 15
                match.isCompleted = true
                tournament.schedule[i] = match
            }
        }
        tournament.updateState()
        
        if case .completed(let winner, let standings) = tournament.state {
            #expect(winner != nil)
            #expect(standings.count == teams.count)
            #expect(standings[0].wins > standings[standings.count - 1].wins)
        } else {
            throw TestError("Expected tournament to be completed")
        }
    }
    
    // MARK: - Edge Cases
    
    @Test func testMinimumCourts() async throws {
        let store = await TournamentStore()
        let tournament = Tournament(title: "Min Courts", teams: ["Team 1", "Team 2"], courts: 0)
        
        do {
            try await store.add(tournament)
            throw TestError("Expected validation error for zero courts")
        } catch let error as TournamentStore.StoreError {
            if case .invalidTournament(let reason) = error {
                #expect(reason.contains("must have at least 1 court"))
            } else {
                throw TestError("Expected invalidTournament error")
            }
        }
    }
    
    @Test func testEmptyTournament() async throws {
        let tournament = Tournament.emptyTournament
        #expect(tournament.teams.isEmpty)
        #expect(tournament.schedule.isEmpty)
        #expect(tournament.state == .setup)
    }
    
    // MARK: - Match Score Tests
    
    @Test func testMatchScoreUpdates() async throws {
        let teams = ["Team 1", "Team 2"]
        var tournament = Tournament(title: "Score Test", teams: teams, courts: 1)
        tournament.updateSchedule()
        
        guard var match = tournament.schedule.first else {
            throw TestError("Expected at least one match")
        }
        
        match.team1Score = 21
        match.team2Score = 15
        match.isCompleted = true
        
        tournament.schedule[0] = match
        tournament.updateState()
        
        let updatedMatch = tournament.schedule[0]
        #expect(updatedMatch.team1Score == 21)
        #expect(updatedMatch.team2Score == 15)
        #expect(updatedMatch.isCompleted)
    }
    
    @Test func testTieScores() async throws {
        let teams = ["Team 1", "Team 2"]
        var tournament = Tournament(title: "Tie Test", teams: teams, courts: 1)
        tournament.updateSchedule()
        
        guard var match = tournament.schedule.first else {
            throw TestError("Expected at least one match")
        }
        
        match.team1Score = 21
        match.team2Score = 21
        match.isCompleted = true
        
        tournament.schedule[0] = match
        tournament.updateState()
        
        if case .completed(_, let standings) = tournament.state {
            #expect(standings[0].wins == 0)
            #expect(standings[1].wins == 0)
            #expect(standings[0].losses == 0)
            #expect(standings[1].losses == 0)
        }
    }
    
    // MARK: - Round Management Tests
    
    @Test func testMultipleRounds() async throws {
        let teams = ["Team 1", "Team 2", "Team 3", "Team 4"]
        var tournament = Tournament(title: "Rounds Test", teams: teams, courts: 1)
        tournament.updateSchedule()
        
        // Get unique rounds
        let rounds = Set(tournament.schedule.map(\.round))
        let expectedMatches = (teams.count * (teams.count - 1)) / 2 // n(n-1)/2 for complete round robin
        let expectedRounds = expectedMatches // With 1 court, each round has 1 match
        
        #expect(rounds.count == expectedRounds, "Expected \(expectedRounds) rounds, got \(rounds.count)")
        
        // Verify each team plays once per round (except when they have a bye)
        for round in rounds {
            let roundMatches = tournament.schedule.filter { $0.round == round && !$0.isByeMatch }
            let teamsInRound = Set(roundMatches.flatMap { [$0.team1.name, $0.team2.name] })
            #expect(teamsInRound.count == 2, "Expected 2 teams playing in round \(round)")
        }
    }
    
    @Test func testCourtUtilization() async throws {
        let teams = ["Team 1", "Team 2", "Team 3", "Team 4"]
        var tournament = Tournament(title: "Courts Test", teams: teams, courts: 2)
        tournament.updateSchedule()
        
        // Group matches by round
        let matchesByRound = Dictionary(grouping: tournament.schedule.filter { !$0.isByeMatch }) { $0.round }
        
        // Check court utilization in each round
        for (round, matches) in matchesByRound {
            let courtsUsed = Set(matches.map(\.courtNumber))
            #expect(courtsUsed.count <= tournament.availableCourts, "Too many courts used in round \(round)")
            #expect(courtsUsed.allSatisfy { $0 > 0 && $0 <= tournament.availableCourts }, "Invalid court number in round \(round)")
        }
    }
    
    // MARK: - Schedule Generation Tests
    
    @Test func testByeMatchHandling() async throws {
        let teams = ["Team 1", "Team 2", "Team 3"] // Odd number of teams
        var tournament = Tournament(title: "Bye Test", teams: teams, courts: 1)
        tournament.updateSchedule()
        
        // Verify bye matches
        let byeMatches = tournament.schedule.filter(\.isByeMatch)
        #expect(!byeMatches.isEmpty, "Expected bye matches with odd number of teams")
        
        // Each team should have equal number of byes
        let byeCountByTeam = Dictionary(grouping: byeMatches) { match in
            match.team1.name == "Bye" ? match.team2.name : match.team1.name
        }.mapValues(\.count)
        
        let firstByeCount = byeCountByTeam.first?.value ?? 0
        #expect(byeCountByTeam.values.allSatisfy { $0 == firstByeCount }, "All teams should have equal number of byes")
    }
    
    @Test func testCompleteRoundRobin() async throws {
        let teams = ["Team 1", "Team 2", "Team 3", "Team 4"]
        var tournament = Tournament(title: "Complete RR Test", teams: teams, courts: 2)
        tournament.updateSchedule()
        
        // Each team should play against every other team exactly once
        for team1 in teams {
            for team2 in teams where team1 != team2 {
                let matchExists = tournament.schedule.contains { match in
                    (!match.isByeMatch) &&
                    ((match.team1.name == team1 && match.team2.name == team2) ||
                     (match.team1.name == team2 && match.team2.name == team1))
                }
                #expect(matchExists, "Expected match between \(team1) and \(team2)")
            }
        }
    }
    
    // MARK: - State Transition Tests
    
    @Test func testStateTransitions() async throws {
        let teams = ["Team 1", "Team 2", "Team 3"]
        var tournament = Tournament(title: "State Test", teams: teams, courts: 1)
        
        // Initial state
        #expect(tournament.state == .setup)
        
        // Generate schedule - should move to inProgress
        tournament.updateSchedule()
        
        // Print initial schedule and state for debugging
        print("Initial schedule and state:")
        tournament.schedule.forEach { print($0) }
        print("State after schedule generation: \(tournament.state)")
        
        if case .inProgress(let completed, let total) = tournament.state {
            #expect(completed == 0)
            #expect(total == (teams.count * (teams.count - 1)) / 2)
        } else {
            throw TestError("Expected inProgress state after schedule generation")
        }
        
        // Get all non-bye matches first
        let nonByeMatches = tournament.schedule.enumerated()
            .filter { !$0.element.isByeMatch }
            .map { (index: $0.offset, match: $0.element) }
        
        // Complete matches one by one
        for (i, matchInfo) in nonByeMatches.enumerated() {
            print("\nCompleting match \(i + 1) of \(nonByeMatches.count): \(matchInfo.match)")
            
            // Update the match
            var updatedMatch = matchInfo.match
            updatedMatch.team1Score = 21
            updatedMatch.team2Score = 15
            updatedMatch.isCompleted = true
            tournament.schedule[matchInfo.index] = updatedMatch
            tournament.updateState()
            
            print("State after completing match: \(tournament.state)")
            
            // Verify state after each match completion
            if i == nonByeMatches.count - 1 {
                // After last match, should be completed
                #expect(tournament.isCompleted, "Tournament should be completed after final match")
                if case .completed(let winner, let standings) = tournament.state {
                    #expect(winner != nil, "Should have a winner")
                    #expect(standings.count == teams.count, "Should have standings for all teams")
                } else {
                    throw TestError("Expected completed state after final match")
                }
            } else {
                // During tournament, should be in progress
                if case .inProgress(let completed, let total) = tournament.state {
                    let expectedCompleted = i + 1 // We've completed this many matches
                    #expect(completed == expectedCompleted, "Expected \(expectedCompleted) completed matches, got \(completed)")
                    #expect(total == nonByeMatches.count, "Expected \(nonByeMatches.count) total matches")
                } else {
                    throw TestError("Expected inProgress state during tournament")
                }
            }
        }
        
        // Final verification
        print("\nFinal tournament state: \(tournament.state)")
        let completedMatches = tournament.schedule.filter { !$0.isByeMatch && $0.isCompleted }
        print("Total completed non-bye matches: \(completedMatches.count)")
        
        #expect(tournament.isCompleted, "Tournament should be completed after all matches")
        if case .completed(let winner, let standings) = tournament.state {
            #expect(winner != nil, "Should have a winner")
            #expect(standings.count == teams.count, "Should have standings for all teams")
        } else {
            throw TestError("Expected completed state with winner and standings")
        }
    }
    
    // MARK: - Tournament Store Tests
    
    @Test func testTournamentStoreSaveAndLoad() async throws {
        let store = await TournamentStore()
        let tournament = Tournament(title: "Store Test", teams: ["Team 1", "Team 2"], courts: 1)
        
        // Add tournament to store
        try await store.add(tournament)
        
        // Wait for store to update
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let tournaments = await store.tournaments
        #expect(tournaments.count == 1)
        #expect(tournaments[0].id == tournament.id)
        
        // Test load
        let loaded = tournaments.first
        #expect(loaded?.title == tournament.title)
        #expect(loaded?.teams.count == tournament.teams.count)
    }
    
    @Test func testTournamentStoreUpdate() async throws {
        let store = await TournamentStore()
        var tournament = Tournament(title: "Update Test", teams: ["Team 1", "Team 2"], courts: 1)
        
        // Add tournament to store first
        try await store.add(tournament)
        
        // Update tournament
        tournament.title = "Updated Title"
        try await store.update(tournament)
        
        // Verify update
        let updated = await store.tournaments.first
        #expect(updated?.title == "Updated Title")
    }
    
    // MARK: - Invalid Score Tests
    
    @Test func testInvalidScores() async throws {
        var tournament = Tournament(title: "Invalid Scores", teams: ["Team 1", "Team 2"], courts: 1)
        tournament.updateSchedule()
        
        guard var match = tournament.schedule.first else {
            throw TestError("Expected at least one match")
        }
        
        // Test negative scores
        match.team1Score = -5
        match.team2Score = 21
        match.isCompleted = true
        
        tournament.schedule[0] = match
        tournament.updateState()
        
        // Verify negative scores are not counted in standings
        if case .completed(_, let standings) = tournament.state {
            #expect(standings[0].wins == 0)
            #expect(standings[0].losses == 0)
        }
    }
    
    // MARK: - Schedule Validation Tests
    
    @Test func testScheduleValidation() async throws {
        let teams = ["Team 1", "Team 2", "Team 3"]
        var tournament = Tournament(title: "Schedule Validation", teams: teams, courts: 1)
        tournament.updateSchedule()
        
        // Verify each team plays against every other team
        for i in 0..<teams.count {
            for j in (i + 1)..<teams.count {
                let matchExists = tournament.schedule.contains { match in
                    (!match.isByeMatch) &&
                    ((match.team1.name == teams[i] && match.team2.name == teams[j]) ||
                     (match.team1.name == teams[j] && match.team2.name == teams[i]))
                }
                #expect(matchExists, "Expected match between \(teams[i]) and \(teams[j])")
            }
        }
    }
    
    // MARK: - Team Tests
    
    @Test func testTeamEquality() async throws {
        let team1a = Tournament.Team(name: "Team 1")
        let team1b = Tournament.Team(name: "Team 1")
        let team2 = Tournament.Team(name: "Team 2")
        
        #expect(team1a == team1b)
        #expect(team1a != team2)
    }
    
    @Test func testTeamStandingsSorting() async throws {
        var teams = [
            Tournament.Team(name: "Team 1", wins: 2, losses: 1),
            Tournament.Team(name: "Team 2", wins: 3, losses: 0),
            Tournament.Team(name: "Team 3", wins: 1, losses: 2)
        ]
        
        teams.sort { $0.wins > $1.wins }
        
        #expect(teams[0].name == "Team 2")
        #expect(teams[1].name == "Team 1")
        #expect(teams[2].name == "Team 3")
    }
    
    @Test func testTournamentStoreValidation() async throws {
        let store = await TournamentStore()
        
        // Test empty title
        let emptyTitleTournament = Tournament(title: "", teams: ["Team 1", "Team 2"], courts: 1)
        do {
            try await store.add(emptyTitleTournament)
            throw TestError("Expected validation error for empty title")
        } catch let error as TournamentStore.StoreError {
            if case .invalidTournament(let reason) = error {
                #expect(reason.contains("Title cannot be empty"))
            } else {
                throw TestError("Expected invalidTournament error")
            }
        }
        
        // Test insufficient teams
        let insufficientTeamsTournament = Tournament(title: "Test", teams: ["Team 1"], courts: 1)
        do {
            try await store.add(insufficientTeamsTournament)
            throw TestError("Expected validation error for insufficient teams")
        } catch let error as TournamentStore.StoreError {
            if case .invalidTournament(let reason) = error {
                #expect(reason.contains("must have at least 2 teams"))
            } else {
                throw TestError("Expected invalidTournament error")
            }
        }
        
        // Test invalid courts
        let invalidCourtsTournament = Tournament(title: "Test", teams: ["Team 1", "Team 2"], courts: -1)
        do {
            try await store.add(invalidCourtsTournament)
            throw TestError("Expected validation error for invalid courts")
        } catch let error as TournamentStore.StoreError {
            if case .invalidTournament(let reason) = error {
                #expect(reason.contains("must have at least 1 court"))
            } else {
                throw TestError("Expected invalidTournament error")
            }
        }
    }
    
    @Test func testTournamentStoreNotFound() async throws {
        let store = await TournamentStore()
        let tournament = Tournament(title: "Test", teams: ["Team 1", "Team 2"], courts: 1)
        
        // Try to update non-existent tournament
        do {
            try await store.update(tournament)
            throw TestError("Expected tournament not found error")
        } catch let error as TournamentStore.StoreError {
            if case .tournamentNotFound = error {
                // Expected error
            } else {
                throw TestError("Expected tournamentNotFound error")
            }
        }
        
        // Try to remove non-existent tournament
        do {
            try await store.remove(tournament.id)
            throw TestError("Expected tournament not found error")
        } catch let error as TournamentStore.StoreError {
            if case .tournamentNotFound = error {
                // Expected error
            } else {
                throw TestError("Expected tournamentNotFound error")
            }
        }
    }
    
    @Test func testTournamentStoreRemove() async throws {
        let store = await TournamentStore()
        let tournament = Tournament(title: "Test", teams: ["Team 1", "Team 2"], courts: 1)
        
        // Add and then remove tournament
        try await store.add(tournament)
        try await store.remove(tournament.id)
        
        let tournaments = await store.tournaments
        #expect(tournaments.isEmpty)
        
        // Try to remove again (should fail)
        do {
            try await store.remove(tournament.id)
            throw TestError("Expected tournament not found error")
        } catch let error as TournamentStore.StoreError {
            if case .tournamentNotFound = error {
                // Expected error
            } else {
                throw TestError("Expected tournamentNotFound error")
            }
        }
    }
    
    @Test func testTournamentStoreRemoveAll() async throws {
        let store = await TournamentStore()
        
        // Add multiple tournaments
        let tournament1 = Tournament(title: "Test 1", teams: ["Team 1", "Team 2"], courts: 1)
        let tournament2 = Tournament(title: "Test 2", teams: ["Team 3", "Team 4"], courts: 1)
        try await store.add(tournament1)
        try await store.add(tournament2)
        
        var tournaments = await store.tournaments
        #expect(tournaments.count == 2)
        
        // Remove all tournaments
        try await store.removeAll()
        
        tournaments = await store.tournaments
        #expect(tournaments.isEmpty)
    }
}

struct TestError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}
