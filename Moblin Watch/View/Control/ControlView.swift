import SwiftUI

struct PadelScoreboardScore: Identifiable {
    let id: UUID = .init()
    var home: Int
    var away: Int
}

struct PadelScoreboardPlayer: Identifiable {
    let id: UUID = .init()
    var name: String
}

struct PadelScoreboardTeam {
    var players: [PadelScoreboardPlayer]
}

struct PadelScoreboard {
    var home: PadelScoreboardTeam
    var away: PadelScoreboardTeam
    var scores: [PadelScoreboardScore]
}

private struct ScoreboardView: View {
    @Binding var scoreBoard: PadelScoreboard

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    ForEach(scoreBoard.home.players) { player in
                        Text(player.name.prefix(5))
                    }
                }
                VStack(alignment: .leading) {
                    ForEach(scoreBoard.away.players) { player in
                        Text(player.name.prefix(5))
                    }
                }
            }
            .font(.system(size: 15))
            ForEach(scoreBoard.scores) { score in
                VStack {
                    VStack {
                        Spacer(minLength: 0)
                        Text(String(score.home))
                        Spacer(minLength: 0)
                    }
                    VStack {
                        Spacer(minLength: 0)
                        Text(String(score.away))
                        Spacer(minLength: 0)
                    }
                }
                .frame(width: 17)
                .font(.system(size: 30))
            }
            Spacer()
        }
        .padding([.leading, .trailing], 2)
        .padding([.top], 2)
        .background(.blue)
        .foregroundColor(.white)
    }
}

private struct PadelScoreboardView: View {
    @EnvironmentObject var model: Model
    @State var isPresentingResetConfirimation = false

    var body: some View {
        Divider()
        ScoreboardView(scoreBoard: $model.padelScoreBoard)
        HStack {
            Button {
                model.padelScoreboardUndoScore()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            Button {
                model.padelScoreboardIncrementHomeScore()
            } label: {
                Image(systemName: "plus")
            }
            .tint(model.padelScoreboardIncrementTintColor)
        }
        HStack {
            Button {
                isPresentingResetConfirimation = true
            } label: {
                Image(systemName: "trash")
            }
            .confirmationDialog("", isPresented: $isPresentingResetConfirimation) {
                Button("Reset scores") {
                    model.resetPadelScoreBoard()
                }
                Button("Cancel") {}
            }
            .tint(.red)
            Button {
                model.padelScoreboardIncrementAwayScore()
            } label: {
                Image(systemName: "plus")
            }
            .tint(model.padelScoreboardIncrementTintColor)
        }
    }
}

struct ControlView: View {
    @EnvironmentObject var model: Model
    @State private var isPresentingIsLiveConfirm: Bool = false
    @State private var pendingLiveValue = false
    @State private var isPresentingIsRecordingConfirm: Bool = false
    @State private var pendingRecordingValue = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Toggle(isOn: Binding(get: {
                    model.isLive
                }, set: { value in
                    pendingLiveValue = value
                    isPresentingIsLiveConfirm = true
                })) {
                    Text("Live")
                }
                .confirmationDialog("", isPresented: $isPresentingIsLiveConfirm) {
                    Button(pendingLiveValue ? String(localized: "Go Live") : String(localized: "End")) {
                        model.setIsLive(value: pendingLiveValue)
                    }
                    Button("Cancel") {}
                }
                Toggle(isOn: Binding(get: {
                    model.isRecording
                }, set: { value in
                    pendingRecordingValue = value
                    isPresentingIsRecordingConfirm = true
                })) {
                    Text("Recording")
                }
                .confirmationDialog("", isPresented: $isPresentingIsRecordingConfirm) {
                    Button(pendingRecordingValue ? String(localized: "Start") : String(localized: "Stop")) {
                        model.setIsRecording(value: pendingRecordingValue)
                    }
                    Button("Cancel") {}
                }
                Toggle(isOn: Binding(get: {
                    model.isMuted
                }, set: { value in
                    model.setIsMuted(value: value)
                })) {
                    Text("Muted")
                }
                Button {
                    model.skipCurrentChatTextToSpeechMessage()
                } label: {
                    Text("Skip current TTS")
                }
                if model.showPadelScoreBoard {
                    PadelScoreboardView()
                }
                Spacer()
            }
            .padding()
        }
    }
}
