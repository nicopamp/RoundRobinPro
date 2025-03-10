//
//  TournamentSampleData.swift
//  RoundRobinPro
//
//  Created by Nico Pampaloni on 2/8/25.
//

import Foundation

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