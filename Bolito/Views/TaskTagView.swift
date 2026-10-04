import SwiftUI

struct TaskTagChip: View {
    let tag: TaskTag

    private var color: Color {
        Color(hex: tag.colorHex)
    }

    var body: some View {
        Text(tag.name)
            .font(.caption)
            .fontWeight(.medium)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(color)
            .background(color.opacity(0.18), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(color.opacity(0.45), lineWidth: 1)
            }
    }
}

struct TaskTagEditor: View {
    @Binding var tags: [TaskTag]
    let localizer: AppLocalizer

    @State private var tagName = ""
    @State private var tagColor: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: localizer.string("tasks.tags"))
                .font(.headline)

            HStack {
                TextField(localizer.string("tasks.tags.placeholder"), text: $tagName)

                ColorPicker("", selection: $tagColor)
                    .labelsHidden()

                Button {
                    addTag()
                } label: {
                    Label(localizer.string("tasks.tags.add"), systemImage: "plus")
                }
                .disabled(trimmedName.isEmpty || containsTag(named: trimmedName))
            }

            if !tags.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(tags) { tag in
                            HStack(spacing: 4) {
                                TaskTagChip(tag: tag)

                                Button {
                                    tags.removeAll { $0.id == tag.id }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .accessibilityLabel(localizer.string("tasks.tags.remove"))
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var trimmedName: String {
        tagName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func containsTag(named name: String) -> Bool {
        tags.contains { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }

    private func addTag() {
        guard !trimmedName.isEmpty, !containsTag(named: trimmedName) else { return }

        tags.append(
            TaskTag(
                name: trimmedName,
                colorHex: tagColor.toHex() ?? "#5E5CE6"
            )
        )
        tagName = ""
    }
}
