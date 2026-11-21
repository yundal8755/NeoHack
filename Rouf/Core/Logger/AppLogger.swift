import Foundation
import SwiftyBeaver

enum AppLogger {
    private static let log = SwiftyBeaver.self
    private static var isConfigured = false

    static func configure() {
        guard !isConfigured else { return }

        let console = ConsoleDestination()
        console.asynchronously = false
        console.useNSLog = true
        console.levelString.verbose = "🔎 VERBOSE"
        console.levelString.debug = "🐛 DEBUG"
        console.levelString.info = "ℹ️ INFO"
        console.levelString.warning = "⚠️ WARNING"
        console.levelString.error = "🔥 ERROR"
        console.levelString.critical = "🚨 CRITICAL"
        console.levelString.fault = "💥 FAULT"
        console.format = "$DHH:mm:ss.SSS$d $L $N.$F:$l - $M"

        #if DEBUG
        console.minLevel = .debug
        #else
        console.minLevel = .warning
        #endif

        log.addDestination(console)
        isConfigured = true
        info("Logger configured")
    }

    static func verbose(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log.verbose(message(), file: file, function: function, line: line)
    }

    static func debug(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log.debug(message(), file: file, function: function, line: line)
    }

    static func info(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log.info(message(), file: file, function: function, line: line)
    }

    static func warning(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log.warning(message(), file: file, function: function, line: line)
    }

    static func error(
        _ message: @autoclosure () -> Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log.error(message(), file: file, function: function, line: line)
    }
}
