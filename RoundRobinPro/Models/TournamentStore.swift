//
//  TournamentStore.swift
//  RoundRobinPro
//
//  Created by Nico Pampaloni on 2/10/25.
//

import SwiftUI

@MainActor
final class TournamentStore: ObservableObject {
    @Published private(set) var tournaments: [Tournament] = []
    private let queue = DispatchQueue(label: "com.roundrobinpro.store", qos: .userInitiated)
    
    // MARK: - File Management
    
    private static nonisolated func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                  in: .userDomainMask,
                                  appropriateFor: nil,
                                  create: false)
        .appendingPathComponent("tournaments.data")
    }
    
    // MARK: - Error Handling
    
    enum StoreError: LocalizedError {
        case failedToLoad
        case failedToSave
        case invalidTournament(String)
        case tournamentNotFound(UUID)
        
        var errorDescription: String? {
            switch self {
            case .failedToLoad:
                return "Failed to load tournaments data"
            case .failedToSave:
                return "Failed to save tournaments data"
            case .invalidTournament(let reason):
                return "Invalid tournament: \(reason)"
            case .tournamentNotFound(let id):
                return "Tournament with ID \(id) not found"
            }
        }
    }
    
    // MARK: - Data Validation
    
    private func validate(_ tournament: Tournament) throws {
        guard !tournament.title.isEmpty else {
            throw StoreError.invalidTournament("Title cannot be empty")
        }
        guard tournament.teams.count >= 2 else {
            throw StoreError.invalidTournament("Tournament must have at least 2 teams")
        }
        guard tournament.availableCourts > 0 else {
            throw StoreError.invalidTournament("Tournament must have at least 1 court")
        }
    }
    
    // MARK: - CRUD Operations
    
    func load() async throws {
        let task = Task<[Tournament], Error> {
            let fileURL = try Self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return []
            }
            return try JSONDecoder().decode([Tournament].self, from: data)
        }
        self.tournaments = try await task.value
    }
    
    func save() async throws {
        let tournaments = self.tournaments // Capture tournaments array before async work
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let data = try JSONEncoder().encode(tournaments)
                    let outfile = try Self.fileURL()
                    try data.write(to: outfile, options: .atomic)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func add(_ tournament: Tournament) async throws {
        try validate(tournament)
        tournaments.append(tournament)
        try await save()
    }
    
    func update(_ tournament: Tournament) async throws {
        try validate(tournament)
        guard let index = tournaments.firstIndex(where: { $0.id == tournament.id }) else {
            throw StoreError.tournamentNotFound(tournament.id)
        }
        tournaments[index] = tournament
        try await save()
    }
    
    func remove(_ id: UUID) async throws {
        guard tournaments.contains(where: { $0.id == id }) else {
            throw StoreError.tournamentNotFound(id)
        }
        tournaments.removeAll { $0.id == id }
        try await save()
    }
    
    // MARK: - Convenience Methods
    
    func tournament(withId id: UUID) -> Tournament? {
        tournaments.first { $0.id == id }
    }
    
    func removeAll() async throws {
        tournaments.removeAll()
        try await save()
    }
}
