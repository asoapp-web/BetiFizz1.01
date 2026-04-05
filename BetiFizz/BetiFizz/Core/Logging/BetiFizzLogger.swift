//
//  BetiFizzLogger.swift
//  BetiFizz
//
//  Logs every API request and response.
//

import Foundation

enum BetiFizzLogger {

    static func logRequest(url: URL, headers: [String: String]) {
        var lines = ["╔══════ [BetiFizz] REQUEST ══════"]
        lines.append("║  → \(url.absoluteString)")
        for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
            let display = key == "X-Auth-Token"
                ? String(value.prefix(6)) + "···"
                : value
            lines.append("║    \(key): \(display)")
        }
        lines.append("╚═══════════════════════════════")
        lines.forEach { print($0) }
    }

    static func logResponse(url: URL, statusCode: Int, data: Data) {
        var lines = ["╔══════ [BetiFizz] RESPONSE ══════"]
        lines.append("║  ← \(url.absoluteString)")
        lines.append("║  HTTP \(statusCode)")

        if let raw = String(data: data, encoding: .utf8) {
            let preview = raw.count > 800
                ? String(raw.prefix(800)) + "\n║  … (truncated, \(raw.count) chars total)"
                : raw
            for line in preview.components(separatedBy: "\n").prefix(30) {
                lines.append("║  \(line)")
            }
        } else {
            lines.append("║  <binary data: \(data.count) bytes>")
        }

        lines.append("╚══════════════════════════════")
        lines.forEach { print($0) }
    }

    static func logError(_ error: Error, url: URL? = nil) {
        var lines = ["╔══════ [BetiFizz] ERROR ══════"]
        if let url { lines.append("║  URL: \(url.absoluteString)") }
        lines.append("║  \(error.localizedDescription)")
        if let nsErr = error as NSError? {
            lines.append("║  domain=\(nsErr.domain) code=\(nsErr.code)")
        }
        lines.append("╚════════════════════════════════")
        lines.forEach { print($0) }
    }

    static func info(_ message: String) {
        print("║  [BetiFizz] ℹ️  \(message)")
    }
}
