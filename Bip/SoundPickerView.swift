import SwiftUI

struct SoundPickerView: View {
    @Binding var selectedSound: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            ForEach(AudioHapticManager.availableSounds, id: \.id) { sound in
                Button {
                    selectedSound = sound.id
                    AudioHapticManager.shared.playSound(sound.id)
                } label: {
                    HStack {
                        Text(sound.name)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedSound == sound.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Sound")
        .navigationBarTitleDisplayMode(.inline)
    }
}
