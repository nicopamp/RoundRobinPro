//
//  CardView.swift
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
                .accessibilityAddTraits(.isHeader)
            Spacer()
            HStack {
                Label("\(tournament.teams.count)", systemImage: "person.3")
                    .accessibilityLabel("\(tournament.teams.count) teams")
                Spacer()
                Label("\(tournament.availableCourts)", systemImage: "sportscourt")
                    .labelStyle(.trailingIcon)
                    .accessibilityLabel("\(tournament.availableCourts) courts")
            }
            .font(.caption)
        }
        .padding()
        .foregroundColor(tournament.theme.accentColor)
    }
}

@available(iOS 17.0, *)
#Preview(traits: .fixedLayout(width: 400, height: 60)) {
    let tournament = Tournament.sampleData[0]
    TournamentCardView(tournament: tournament)
        .background(tournament.theme.mainColor)
}
