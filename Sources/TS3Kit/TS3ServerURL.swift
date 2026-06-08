import Foundation

/// A parsed TeamSpeak invitation or connection URL.
public struct TS3ServerURL: Equatable {
    public let host: String
    public let port: Int?
    public let nickname: String?
    public let serverPassword: String?
    public let defaultChannel: String?
    public let defaultChannelPassword: String?
    public let privilegeKey: String?
    public let phoneticNickname: String?
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
        phoneticNickname: String? = nil,
        bookmarkName: String?
    ) {
        self.host = host
        self.port = port
        self.nickname = nickname
        self.serverPassword = serverPassword
        self.defaultChannel = defaultChannel
        self.defaultChannelPassword = defaultChannelPassword
        self.privilegeKey = privilegeKey
        self.phoneticNickname = phoneticNickname
        self.bookmarkName = bookmarkName
    }

    /// Parses a TeamSpeak `ts3server://` or `teamspeak://` URL.
    public init(url: URL) throws {
        guard let scheme = url.scheme?.lowercased(),
              Self.supportedSchemes.contains(scheme) else {
            throw TS3Error.invalidCommand
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw TS3Error.invalidCommand
        }

        let parsedOpaqueHost = Self.hostAndPortFromOpaqueURL(url, scheme: scheme)
        let host = Self.nonEmpty(url.host) ?? parsedOpaqueHost?.host
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
            port: url.port ?? parsedOpaqueHost?.port ?? Self.intValue(query["port"]),
            nickname: query["nickname"],
            serverPassword: Self.firstValue(in: query, keys: ["password", "serverpassword", "server_password"]),
            defaultChannel: Self.firstValue(in: query, keys: ["channel", "defaultchannel", "default_channel"]),
            defaultChannelPassword: Self.firstValue(in: query, keys: ["channelpassword", "channel_password"]),
            privilegeKey: Self.firstValue(in: query, keys: ["token", "privilegekey", "privilege_key"]),
            phoneticNickname: query["phoneticnickname"] ?? query["nickname_phonetic"],
            bookmarkName: query["addbookmark"] ?? query["bookmark"]
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
        appendQueryItem(name: "phoneticnickname", value: phoneticNickname, to: &queryItems)
        appendQueryItem(name: "addbookmark", value: bookmarkName, to: &queryItems)
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url
    }

    private static let supportedSchemes = ["ts3server", "teamspeak"]

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

    private static func firstValue(in query: [String: String], keys: [String]) -> String? {
        keys.lazy.compactMap { query[$0] }.first
    }

    private func appendQueryItem(name: String, value: String?, to queryItems: inout [URLQueryItem]) {
        guard let value = Self.nonEmpty(value) else { return }
        queryItems.append(URLQueryItem(name: name, value: value))
    }

    private static func hostAndPortFromOpaqueURL(_ url: URL, scheme: String) -> (host: String, port: Int?)? {
        let prefix = "\(scheme):"
        let raw = url.absoluteString
        guard raw.lowercased().hasPrefix(prefix) else { return nil }
        let rest = String(raw.dropFirst(prefix.count))
        let withoutSlashes = rest.hasPrefix("//") ? String(rest.dropFirst(2)) : rest
        let hostPart = withoutSlashes.split(separator: "?", maxSplits: 1).first.map(String.init)
        guard let hostPart = nonEmpty(hostPart) else { return nil }
        return splitHostAndPort(hostPart)
    }

    private static func splitHostAndPort(_ value: String) -> (host: String, port: Int?)? {
        guard let components = URLComponents(string: "//\(value)"),
              let host = nonEmpty(components.host) else {
            return nonEmpty(value).map { ($0, nil) }
        }
        return (host, components.port)
    }
}
