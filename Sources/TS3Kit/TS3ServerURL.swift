import Foundation

/// A parsed `ts3server://` invitation or connection URL.
public struct TS3ServerURL: Equatable {
    public let host: String
    public let port: Int?
    public let nickname: String?
    public let serverPassword: String?
    public let defaultChannel: String?
    public let defaultChannelPassword: String?
    public let privilegeKey: String?
    public let bookmarkName: String?

    /// Creates a parsed TeamSpeak server URL value.
    public init(
        host: String,
        port: Int?,
        nickname: String?,
        serverPassword: String?,
        defaultChannel: String?,
        defaultChannelPassword: String?,
        privilegeKey: String?,
        bookmarkName: String?
    ) {
        self.host = host
        self.port = port
        self.nickname = nickname
        self.serverPassword = serverPassword
        self.defaultChannel = defaultChannel
        self.defaultChannelPassword = defaultChannelPassword
        self.privilegeKey = privilegeKey
        self.bookmarkName = bookmarkName
    }

    /// Parses a TeamSpeak `ts3server://` URL.
    public init(url: URL) throws {
        guard url.scheme?.lowercased() == "ts3server" else {
            throw TS3Error.invalidCommand
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw TS3Error.invalidCommand
        }

        let host = Self.nonEmpty(url.host) ?? Self.hostFromOpaqueURL(url)
        guard let host, !host.isEmpty else {
            throw TS3Error.invalidCommand
        }

        var query: [String: String] = [:]
        for item in components.queryItems ?? [] {
            if let (key, value) = Self.normalizedQueryItem(item) {
                query[key] = value
            }
        }

        self.init(
            host: host,
            port: url.port ?? Self.intValue(query["port"]),
            nickname: query["nickname"],
            serverPassword: query["password"],
            defaultChannel: query["channel"],
            defaultChannelPassword: query["channelpassword"],
            privilegeKey: query["token"],
            bookmarkName: query["addbookmark"]
        )
    }

    /// Builds a TeamSpeak `ts3server://` URL from this value.
    public func url(includingSecrets: Bool = true) -> URL? {
        var components = URLComponents()
        components.scheme = "ts3server"
        components.host = host
        components.port = port

        var queryItems: [URLQueryItem] = []
        appendQueryItem(name: "nickname", value: nickname, to: &queryItems)
        if includingSecrets {
            appendQueryItem(name: "password", value: serverPassword, to: &queryItems)
        }
        appendQueryItem(name: "channel", value: defaultChannel, to: &queryItems)
        if includingSecrets {
            appendQueryItem(name: "channelpassword", value: defaultChannelPassword, to: &queryItems)
            appendQueryItem(name: "token", value: privilegeKey, to: &queryItems)
        }
        appendQueryItem(name: "addbookmark", value: bookmarkName, to: &queryItems)
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url
    }

    private static func normalizedQueryItem(_ item: URLQueryItem) -> (String, String)? {
        let key = item.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return nil }
        guard let value = nonEmpty(item.value) else { return nil }
        return (key, value)
    }

    private static func nonEmpty(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func intValue(_ value: String?) -> Int? {
        guard let value else { return nil }
        return Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func appendQueryItem(name: String, value: String?, to queryItems: inout [URLQueryItem]) {
        guard let value = Self.nonEmpty(value) else { return }
        queryItems.append(URLQueryItem(name: name, value: value))
    }

    private static func hostFromOpaqueURL(_ url: URL) -> String? {
        let prefix = "ts3server:"
        let raw = url.absoluteString
        guard raw.lowercased().hasPrefix(prefix) else { return nil }
        let rest = String(raw.dropFirst(prefix.count))
        let withoutSlashes = rest.hasPrefix("//") ? String(rest.dropFirst(2)) : rest
        let hostPart = withoutSlashes.split(separator: "?", maxSplits: 1).first.map(String.init)
        return nonEmpty(hostPart)
    }
}
