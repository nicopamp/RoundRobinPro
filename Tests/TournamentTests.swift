//
//  TournamentTests.swift
//  RoundRobinProTests
//
//  Created by Nico Pampaloni on 2/8/25.
//

import XCTest
@testable import RoundRobinPro

final class TournamentTests: XCTestCase {
    // MARK: - Setup
    
    private var tournament: Tournament?
    
    override func setUp() {
        super.setUp()
        tournament = Tournament(
            title: "Test Tournament",
            teams: ["Team A", "Team B", "Team C"],
            courts: 1
        )
    }
    
    override func tearDown() {
        tournament = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        guard let tournament = tournament else {
            XCTFail("Tournament should not be nil")
            return
        }
        
        XCTAssertEqual(tournament.title, "Test Tournament")
        XCTAssertEqual(tournament.teams.count, 3)
        XCTAssertEqual(tournament.availableCourts, 1)
        XCTAssertEqual(tournament.state, .setup)
        XCTAssertTrue(tournament.schedule.isEmpty)
    }
    
    func testEmptyTournament() {
        let empty = Tournament.emptyTournament
        XCTAssertTrue(empty.title.isEmpty)
        XCTAssertTrue(empty.teams.isEmpty)
        XCTAssertEqual(empty.availableCourts, 1)
        XCTAssertEqual(empty.state, .setup)
        XCTAssertTrue(empty.schedule.isEmpty)
    }
    
    // MARK: - Computed Properties Tests
    
    func testCourtsAsDouble() {
        guard var tournament = tournament else {
            XCTFail("Tournament should not be nil")
            return
        }
        
        tournament.courtsAsDouble = 2.5
        XCTAssertEqual(tournament.availableCourts, 2)
        
        tournament.courtsAsDouble = 0.5
        XCTAssertEqual(tournament.availableCourts, 1) // Should enforce minimum of 1
    }
    
    func testActiveTeams() {
        let teams = ["Team A", "Team B", "Team C", "Bye"]
        let tournament = Tournament(title: "Test", teams: teams, courts: 1)
        XCTAssertEqual(tournament.activeTeams.count, 3)
        XCTAssertFalse(tournament.activeTeams.contains { $0.name == "Bye" })
    }
    
    // MARK: - State Management Tests
    
    func testUpdateStateSetup() {
        guard var tournament = tournament else {
            XCTFail("Tournament should not be nil")
            return
        }
        
        tournament.updateState()
        XCTAssertEqual(tournament.state, .setup)
    }
    
    func testUpdateStateInProgress() {
        guard var tournament = tournament else {
            XCTFail("Tournament should not be nil")
            return
        }
        
        let match = Tournament.Match(
            team1: tournament.teams[0],
            team2: tournament.teams[1],
            courtNumber: 1,
            round: 1
        )
        tournament.schedule = [match]
        tournament.updateState()
        
        if case .inProgress(let completed, let total) = tournament.state {
            XCTAssertEqual(completed, 0)
            XCTAssertEqual(total, 1)
        } else {
            XCTFail("Expected .inProgress state")
        }
    }
    
    func testUpdateStateCompleted() {
        guard var tournament = tournament else {
            XCTFail("Tournament should not be nil")
            return
        }
        
        // Create a complete schedule with bye matches
        let teamA = tournament.teams[0]
        let teamB = tournament.teams[1]
        let teamC = tournament.teams[2]
        
        let match1 = Tournament.Match(
            team1: teamA,
            team2: teamB,
            courtNumber: 1,
            round: 1,
            isCompleted: true,
            team1Score: 21,
            team2Score: 19
        )
        
        let match2 = Tournament.Match(
            team1: teamB,
            team2: teamC,
            courtNumber: 1,
            round: 2,
            isCompleted: true,
            team1Score: 21,
            team2Score: 19
        )
        
        let match3 = Tournament.Match(
            team1: teamC,
            team2: teamA,
            courtNumber: 1,
            round: 3,
            isCompleted: true,
            team1Score: 21,
            team2Score: 19
        )
        
        tournament.schedule = [match1, match2, match3]
        tournament.updateState()
        
        if case .completed(let winner, let standings) = tournament.state {
            XCTAssertNotNil(winner)
            XCTAssertEqual(standings.count, 3)
            XCTAssertEqual(standings[0].wins, 1)
            XCTAssertEqual(standings[1].wins, 1)
            XCTAssertEqual(standings[2].wins, 1)
        } else {
            XCTFail("Expected .completed state")
        }
    }
    
    // MARK: - Schedule Generation Tests
    
    func testGenerateBalancedSchedule() {
        guard var tournament = tournament else {
            XCTFail("Tournament should not be nil")
            return
        }
        
        tournament.updateSchedule()
        XCTAssertFalse(tournament.schedule.isEmpty)
        
        // Verify each team plays against every other team
        let teamA = tournament.teams[0]
        let teamB = tournament.teams[1]
        let teamC = tournament.teams[2]
        
        let matchesWithTeamA = tournament.schedule.filter { $0.team1 == teamA || $0.team2 == teamA }
        XCTAssertEqual(matchesWithTeamA.count, 3) // 2 regular matches + 1 bye match
        
        let matchesWithTeamB = tournament.schedule.filter { $0.team1 == teamB || $0.team2 == teamB }
        XCTAssertEqual(matchesWithTeamB.count, 3) // 2 regular matches + 1 bye match
        
        let matchesWithTeamC = tournament.schedule.filter { $0.team1 == teamC || $0.team2 == teamC }
        XCTAssertEqual(matchesWithTeamC.count, 3) // 2 regular matches + 1 bye match
    }
    
    func testGenerateBalancedScheduleWithOddTeams() {
        var tournament = Tournament(
            title: "Test",
            teams: ["Team A", "Team B", "Team C", "Team D", "Team E"],
            courts: 1
        )
        tournament.updateSchedule()
        
        // Verify bye matches are created
        let byeMatches = tournament.schedule.filter { $0.isByeMatch }
        XCTAssertFalse(byeMatches.isEmpty)
        
        // Verify each team gets exactly one bye match
        let teams = tournament.teams.filter { $0.name != "Bye" }
        for team in teams {
            let byeMatchesForTeam = byeMatches.filter { $0.team1 == team || $0.team2 == team }
            XCTAssertEqual(byeMatchesForTeam.count, 1, "Team \(team.name) should have exactly one bye match")
        }
        
        // Verify bye matches are properly formatted
        for match in byeMatches {
            XCTAssertTrue(match.team1.name == "Bye" || match.team2.name == "Bye", "Bye match should have 'Bye' as one of the teams")
            XCTAssertEqual(match.courtNumber, 0, "Bye matches should have court number 0")
        }
    }
} 
