// 保存并查询用户词典与候选学习记录
import Foundation
import SQLite3

// 保存候选所在页与页内位置
public struct CandidatePosition: Equatable, Sendable {
    public let page: Int
    public let index: Int

    // 创建明确的页内位置
    public init(page: Int, index: Int) {
        self.page = page
        self.index = index
    }

    // 将全局候选位置转换为页内位置
    public init?(globalIndex: Int, pageSize: Int) {
        guard globalIndex >= 0, pageSize > 0 else { return nil }
        page = globalIndex / pageSize
        index = globalIndex % pageSize
    }
}

// 表示一个用户词条
public struct PersonalTerm: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let text: String
    public let code: String
    public let weight: Int
    public let scheme: ChineseScheme

    // 创建用户词条
    public init(id: UUID = UUID(), text: String, code: String, weight: Int, scheme: ChineseScheme) {
        self.id = id
        self.text = text
        self.code = code
        self.weight = weight
        self.scheme = scheme
    }
}

// 表示个人词典错误
public enum PersonalDictionaryError: Error, Equatable {
    case unavailable
    case invalidUTF8
    case invalidLine(Int)
    case invalidTerm
    case database(String)
}

// 提供个人词典错误说明
extension PersonalDictionaryError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unavailable: "共享词典不可用"
        case .invalidUTF8: "词典必须使用 UTF-8 编码"
        case let .invalidLine(line): "第 \(line) 行格式不正确"
        case .invalidTerm: "词条、编码或权重不正确"
        case let .database(message): "词典数据库错误：\(message)"
        }
    }
}

// 保存解析后的导入行
private struct ParsedTerm {
    let text: String
    let code: String
    let weight: Int
}

// 指示 SQLite 复制绑定文本
private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

// 管理 App Group 内的个人词典数据库
public final class PersonalDictionary {
    private let database: OpaquePointer
    private static let learnedLimit = 4096

    // 打开指定词典数据库
    public init(url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        let result = sqlite3_open_v2(url.path, &handle, flags, nil)
        guard result == SQLITE_OK, let handle else {
            let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "无法打开数据库"
            if let handle { sqlite3_close(handle) }
            throw PersonalDictionaryError.database(message)
        }
        database = handle
        sqlite3_busy_timeout(database, 1_500)
        do {
            try execute("PRAGMA journal_mode=WAL")
            try execute("""
                CREATE TABLE IF NOT EXISTS terms (
                    id TEXT PRIMARY KEY,
                    scheme TEXT NOT NULL,
                    code TEXT NOT NULL,
                    term TEXT NOT NULL,
                    weight INTEGER NOT NULL DEFAULT 0,
                    UNIQUE(scheme, code, term)
                );
                CREATE INDEX IF NOT EXISTS terms_lookup ON terms(scheme, code);
                CREATE TABLE IF NOT EXISTS learning (
                    scheme TEXT NOT NULL,
                    code TEXT NOT NULL,
                    term TEXT NOT NULL,
                    count INTEGER NOT NULL DEFAULT 0,
                    PRIMARY KEY(scheme, code, term)
                );
                """)
        } catch {
            sqlite3_close(database)
            throw error
        }
    }

    // 打开 App Group 共享词典
    public convenience init() throws {
        guard let base = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SharedConfig.groupID
        ) else { throw PersonalDictionaryError.unavailable }
        try self.init(url: base.appendingPathComponent("PersonalDictionary.sqlite3"))
    }

    // 关闭词典数据库
    deinit {
        sqlite3_close(database)
    }

    // 添加或更新一个用户词条
    public func add(
        text: String,
        code: String,
        weight: Int = 0,
        scheme: ChineseScheme
    ) throws {
        let term = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = Self.normalize(code)
        guard !term.isEmpty, !normalized.isEmpty, weight >= 0 else {
            throw PersonalDictionaryError.invalidTerm
        }
        try upsert(ParsedTerm(text: term, code: normalized, weight: weight), scheme: scheme)
    }

    // 导入 Rime YAML 或制表符文本
    @discardableResult
    public func importData(_ data: Data, scheme: ChineseScheme) throws -> Int {
        let parsed = try Self.parse(data)
        try execute("BEGIN IMMEDIATE")
        do {
            for term in parsed { try upsert(term, scheme: scheme) }
            try execute("COMMIT")
            return parsed.count
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    // 查询已保存词条
    public func terms(query: String = "", limit: Int = 500) throws -> [PersonalTerm] {
        let statement = try prepare("""
            SELECT id, term, code, weight, scheme FROM terms
            WHERE ? = '' OR term LIKE '%' || ? || '%' OR code LIKE '%' || ? || '%'
            ORDER BY rowid DESC LIMIT ?
            """)
        defer { sqlite3_finalize(statement) }
        bind(query, at: 1, to: statement)
        bind(query, at: 2, to: statement)
        bind(Self.normalize(query), at: 3, to: statement)
        sqlite3_bind_int(statement, 4, Int32(max(1, limit)))
        var result: [PersonalTerm] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let id = UUID(uuidString: column(statement, 0)),
                let scheme = ChineseScheme(rawValue: column(statement, 4))
            else { continue }
            result.append(PersonalTerm(
                id: id,
                text: column(statement, 1),
                code: column(statement, 2),
                weight: Int(sqlite3_column_int64(statement, 3)),
                scheme: scheme
            ))
        }
        try check(statement)
        return result
    }

    // 查询匹配当前编码前缀的词条
    public func candidates(
        input: String,
        scheme: ChineseScheme,
        limit: Int = 40
    ) throws -> [PersonalTerm] {
        let code = Self.normalize(input)
        guard !code.isEmpty else { return [] }
        let statement = try prepare("""
            SELECT id, term, code, weight FROM terms
            WHERE scheme = ? AND code LIKE ? || '%'
            ORDER BY CASE WHEN code = ? THEN 0 ELSE 1 END, weight DESC, length(code), rowid DESC
            LIMIT ?
            """)
        defer { sqlite3_finalize(statement) }
        bind(scheme.rawValue, at: 1, to: statement)
        bind(code, at: 2, to: statement)
        bind(code, at: 3, to: statement)
        sqlite3_bind_int(statement, 4, Int32(max(1, limit)))
        var result: [PersonalTerm] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let id = UUID(uuidString: column(statement, 0)) else { continue }
            result.append(PersonalTerm(
                id: id,
                text: column(statement, 1),
                code: column(statement, 2),
                weight: Int(sqlite3_column_int64(statement, 3)),
                scheme: scheme
            ))
        }
        try check(statement)
        return result
    }

    // 删除一个用户词条
    public func delete(_ id: UUID) throws {
        let statement = try prepare("DELETE FROM terms WHERE id = ?")
        defer { sqlite3_finalize(statement) }
        bind(id.uuidString, at: 1, to: statement)
        try finish(statement)
    }

    // 记录一次候选选择
    public func learn(input: String, text: String, scheme: ChineseScheme) throws {
        let code = Self.normalize(input)
        guard !code.isEmpty, !text.isEmpty else { return }
        let statement = try prepare("""
            INSERT INTO learning(scheme, code, term, count) VALUES(?, ?, ?, 1)
            ON CONFLICT(scheme, code, term) DO UPDATE SET count = count + 1
            """)
        bind(scheme.rawValue, at: 1, to: statement)
        bind(code, at: 2, to: statement)
        bind(text, at: 3, to: statement)
        defer { sqlite3_finalize(statement) }
        try finish(statement)
        try execute("""
            DELETE FROM learning WHERE rowid NOT IN (
                SELECT rowid FROM learning ORDER BY count DESC, rowid DESC LIMIT \(Self.learnedLimit)
            )
            """)
    }

    // 读取当前编码的候选学习次数
    public func scores(input: String, scheme: ChineseScheme) throws -> [String: Int] {
        let code = Self.normalize(input)
        guard !code.isEmpty else { return [:] }
        let statement = try prepare("SELECT term, count FROM learning WHERE scheme = ? AND code = ?")
        defer { sqlite3_finalize(statement) }
        bind(scheme.rawValue, at: 1, to: statement)
        bind(code, at: 2, to: statement)
        var result: [String: Int] = [:]
        while sqlite3_step(statement) == SQLITE_ROW {
            result[column(statement, 0)] = Int(sqlite3_column_int64(statement, 1))
        }
        try check(statement)
        return result
    }

    // 清除全部候选学习记录
    public func clearLearning() throws {
        try execute("DELETE FROM learning")
    }

    // 合并一个解析后的词条
    private func upsert(_ term: ParsedTerm, scheme: ChineseScheme) throws {
        let statement = try prepare("""
            INSERT INTO terms(id, scheme, code, term, weight) VALUES(?, ?, ?, ?, ?)
            ON CONFLICT(scheme, code, term) DO UPDATE SET weight = excluded.weight
            """)
        defer { sqlite3_finalize(statement) }
        bind(UUID().uuidString, at: 1, to: statement)
        bind(scheme.rawValue, at: 2, to: statement)
        bind(term.code, at: 3, to: statement)
        bind(term.text, at: 4, to: statement)
        sqlite3_bind_int64(statement, 5, sqlite3_int64(term.weight))
        try finish(statement)
    }

    // 解析标准词典文本
    private static func parse(_ data: Data) throws -> [ParsedTerm] {
        guard var source = String(data: data, encoding: .utf8) else {
            throw PersonalDictionaryError.invalidUTF8
        }
        if source.first == "\u{feff}" { source.removeFirst() }
        var header = false
        var result: [ParsedTerm] = []
        for (offset, rawLine) in source.components(separatedBy: .newlines).enumerated() {
            let lineNumber = offset + 1
            let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            if trimmed == "---" {
                header = true
                continue
            }
            if header {
                if trimmed == "..." { header = false }
                continue
            }
            let fields = rawLine.components(separatedBy: "\t")
            guard fields.count >= 2 else { throw PersonalDictionaryError.invalidLine(lineNumber) }
            let text = fields[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let code = normalize(fields[1])
            var weight = 0
            if fields.count >= 3, !fields[2].isEmpty {
                let rawWeight = fields[2].trimmingCharacters(in: .whitespacesAndNewlines)
                let number = rawWeight.hasSuffix("%") ? String(rawWeight.dropLast()) : rawWeight
                guard let parsed = Int(number), parsed >= 0 else {
                    throw PersonalDictionaryError.invalidLine(lineNumber)
                }
                weight = parsed
            }
            guard !text.isEmpty, !code.isEmpty else {
                throw PersonalDictionaryError.invalidLine(lineNumber)
            }
            result.append(ParsedTerm(text: text, code: code, weight: weight))
        }
        return result
    }

    // 归一化用户输入编码
    private static func normalize(_ value: String) -> String {
        value.lowercased().filter { character in
            character.isASCII && (character.isLetter || character.isNumber || character == ";")
        }
    }

    // 执行不返回数据的 SQL
    private func execute(_ sql: String) throws {
        var error: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(database, sql, nil, nil, &error) == SQLITE_OK else {
            let message = error.map { String(cString: $0) } ?? String(cString: sqlite3_errmsg(database))
            sqlite3_free(error)
            throw PersonalDictionaryError.database(message)
        }
    }

    // 创建预编译 SQL
    private func prepare(_ sql: String) throws -> OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw PersonalDictionaryError.database(String(cString: sqlite3_errmsg(database)))
        }
        return statement
    }

    // 绑定 UTF-8 文本参数
    private func bind(_ value: String, at index: Int32, to statement: OpaquePointer) {
        sqlite3_bind_text(statement, index, value, -1, sqliteTransient)
    }

    // 读取 UTF-8 文本列
    private func column(_ statement: OpaquePointer, _ index: Int32) -> String {
        guard let value = sqlite3_column_text(statement, index) else { return "" }
        return String(cString: value)
    }

    // 确认查询结束且无错误
    private func check(_ statement: OpaquePointer) throws {
        let result = sqlite3_errcode(database)
        guard result == SQLITE_OK || result == SQLITE_DONE else {
            throw PersonalDictionaryError.database(String(cString: sqlite3_errmsg(database)))
        }
    }

    // 执行一条写入语句
    private func finish(_ statement: OpaquePointer) throws {
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw PersonalDictionaryError.database(String(cString: sqlite3_errmsg(database)))
        }
    }
}
