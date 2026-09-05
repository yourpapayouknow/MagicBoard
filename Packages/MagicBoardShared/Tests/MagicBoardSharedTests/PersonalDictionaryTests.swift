// 验证候选分页与个人词典行为
@testable import MagicBoardShared
import Foundation
import XCTest

// 测试个人词典
final class PersonalDictionaryTests: XCTestCase {
    // 创建隔离数据库
    private func mkdb() throws -> (PersonalDictionary, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("MagicBoardTests.\(UUID().uuidString).sqlite3")
        return (try PersonalDictionary(url: url), url)
    }

    // 删除隔离数据库
    private func rmdb(_ url: URL) {
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(atPath: url.path + suffix)
        }
    }

    // 验证全局候选下标转换为页码与页内下标
    func testcandpos() {
        XCTAssertEqual(CandidatePosition(globalIndex: 0, pageSize: 5), CandidatePosition(page: 0, index: 0))
        XCTAssertEqual(CandidatePosition(globalIndex: 4, pageSize: 5), CandidatePosition(page: 0, index: 4))
        XCTAssertEqual(CandidatePosition(globalIndex: 5, pageSize: 5), CandidatePosition(page: 1, index: 0))
        XCTAssertEqual(CandidatePosition(globalIndex: 19, pageSize: 5), CandidatePosition(page: 3, index: 4))
        XCTAssertNil(CandidatePosition(globalIndex: -1, pageSize: 5))
        XCTAssertNil(CandidatePosition(globalIndex: 0, pageSize: 0))
    }

    // 验证 Rime YAML 与 TSV 正文导入
    func testdicimport() throws {
        let (dictionary, url) = try mkdb()
        defer { rmdb(url) }
        let source = """
        # Rime dictionary
        ---
        name: personal
        version: "1"
        ...
        魔法键盘\tmo fa jian pan\t80
        常用词\tchangyongci\t120
        """

        let count = try dictionary.importData(Data(source.utf8), scheme: .fullPinyin)
        let terms = try dictionary.terms()

        XCTAssertEqual(count, 2)
        XCTAssertEqual(terms.count, 2)
        XCTAssertEqual(try dictionary.candidates(input: "mofa", scheme: .fullPinyin).first?.text, "魔法键盘")
        XCTAssertEqual(terms.first { $0.text == "魔法键盘" }?.code, "mofajianpan")
    }

    // 验证重复词条合并并以新权重覆盖
    func testdicmerge() throws {
        let (dictionary, url) = try mkdb()
        defer { rmdb(url) }

        try dictionary.add(text: "常用词", code: "chang yong ci", weight: 10, scheme: .fullPinyin)
        try dictionary.add(text: "常用词", code: "changyongci", weight: 90, scheme: .fullPinyin)

        let terms = try dictionary.terms()
        XCTAssertEqual(terms.count, 1)
        XCTAssertEqual(terms[0].weight, 90)
    }

    // 验证不同输入方案相互隔离
    func testdicscheme() throws {
        let (dictionary, url) = try mkdb()
        defer { rmdb(url) }

        try dictionary.add(text: "你好", code: "nihao", weight: 1, scheme: .fullPinyin)
        try dictionary.add(text: "你好", code: "nihk", weight: 2, scheme: .microsoft)

        XCTAssertEqual(try dictionary.candidates(input: "nih", scheme: .fullPinyin).map(\.code), ["nihao"])
        XCTAssertEqual(try dictionary.candidates(input: "nih", scheme: .microsoft).map(\.code), ["nihk"])
    }

    // 验证损坏行返回准确行号
    func testdicbadline() throws {
        let (dictionary, url) = try mkdb()
        defer { rmdb(url) }
        let source = "# comment\n缺少编码\n"

        XCTAssertThrowsError(try dictionary.importData(Data(source.utf8), scheme: .fullPinyin)) { error in
            XCTAssertEqual(error as? PersonalDictionaryError, .invalidLine(2))
        }
    }

    // 验证非法编码与手工词条被拒绝
    func testdicinvalid() throws {
        let (dictionary, url) = try mkdb()
        defer { rmdb(url) }

        XCTAssertThrowsError(try dictionary.importData(Data([0xFF]), scheme: .fullPinyin)) { error in
            XCTAssertEqual(error as? PersonalDictionaryError, .invalidUTF8)
        }
        XCTAssertThrowsError(try dictionary.add(text: "", code: "nihao", scheme: .fullPinyin))
        XCTAssertThrowsError(try dictionary.add(text: "你好", code: "", scheme: .fullPinyin))
        XCTAssertThrowsError(try dictionary.add(text: "你好", code: "nihao", weight: -1, scheme: .fullPinyin))
    }

    // 验证 Rime 百分比权重格式
    func testdicpercent() throws {
        let (dictionary, url) = try mkdb()
        defer { rmdb(url) }

        try dictionary.importData(Data("你好\tnihao\t75%".utf8), scheme: .fullPinyin)

        XCTAssertEqual(try dictionary.terms().first?.weight, 75)
    }

    // 验证学习次数持久化并可清除
    func testdiclearn() throws {
        let (dictionary, url) = try mkdb()
        defer { rmdb(url) }

        try dictionary.learn(input: "nihao", text: "你好", scheme: .fullPinyin)
        try dictionary.learn(input: "nihao", text: "你好", scheme: .fullPinyin)
        XCTAssertEqual(try dictionary.scores(input: "nihao", scheme: .fullPinyin)["你好"], 2)

        let reopened = try PersonalDictionary(url: url)
        XCTAssertEqual(try reopened.scores(input: "nihao", scheme: .fullPinyin)["你好"], 2)
        try reopened.clearLearning()
        XCTAssertTrue(try reopened.scores(input: "nihao", scheme: .fullPinyin).isEmpty)
    }

    // 验证词条搜索与删除
    func testdicdelete() throws {
        let (dictionary, url) = try mkdb()
        defer { rmdb(url) }
        try dictionary.add(text: "魔法键盘", code: "mofajianpan", weight: 80, scheme: .fullPinyin)
        let term = try XCTUnwrap(dictionary.terms(query: "魔法").first)

        try dictionary.delete(term.id)

        XCTAssertTrue(try dictionary.terms().isEmpty)
    }
}
