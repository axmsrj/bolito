import Foundation

struct TaskTag: Codable, Hashable, Identifiable {
    var id: String { "\(name.lowercased())|\(colorHex.uppercased())" }

    let name: String
    let colorHex: String
}

enum TaskTagStorage {
    private static let prefix = "bolito-tag:"
    private static let legacyColor = "#5E5CE6"

    static func decode(_ values: [String?]) -> [TaskTag] {
        values.compactMap { value in
            guard let value, !value.isEmpty else { return nil }

            guard value.hasPrefix(prefix) else {
                return TaskTag(name: value, colorHex: legacyColor)
            }

            let encoded = String(value.dropFirst(prefix.count))
            guard let data = Data(base64Encoded: encoded),
                  let tag = try? JSONDecoder().decode(TaskTag.self, from: data) else {
                return nil
            }

            return tag
        }
    }

    static func encode(_ tags: [TaskTag]) -> [String?] {
        tags.compactMap { tag in
            guard let data = try? JSONEncoder().encode(tag) else { return nil }
            return prefix + data.base64EncodedString()
        }
    }
}

extension Task {
    var taskTags: [TaskTag] {
        get { TaskTagStorage.decode(tags) }
        set { tags = TaskTagStorage.encode(newValue) }
    }
}
