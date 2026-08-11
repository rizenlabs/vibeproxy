import XCTest
@testable import CLIProxyMenuBar

final class ThinkingProxyRequestBodyTests: XCTestCase {
    func testPassThroughPreservesClientCacheControlsByteForByte() {
        let input = #"{"model":"claude-sonnet-4-6","system":[{"type":"text","text":"system","cache_control":{"type":"ephemeral","ttl":"1h"}}],"messages":[{"role":"user","content":[{"type":"text","text":"hello","cache_control":{"type":"ephemeral"}}]}],"tools":[{"name":"search","cache_control":{"type":"ephemeral"}}]}"#

        let result = ThinkingProxy().processRequestBody(input)

        XCTAssertEqual(result.body, input)
        XCTAssertFalse(result.thinkingEnabled)
        XCTAssertFalse(result.matchedCopilotAlias)
    }

    func testThinkingTransformPreservesCacheControlsAtEverySupportedLocation() throws {
        let input = #"{"model":"claude-sonnet-4-5-thinking-2000","max_tokens":1000,"system":[{"type":"text","text":"system","cache_control":{"type":"ephemeral","ttl":"1h"}}],"messages":[{"role":"user","content":[{"type":"text","text":"hello","cache_control":{"type":"ephemeral"}}]}],"tools":[{"name":"search","cache_control":{"type":"ephemeral"}}]}"#

        let result = ThinkingProxy().processRequestBody(input)
        let data = try XCTUnwrap(result.body.data(using: .utf8))
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertTrue(result.thinkingEnabled)
        XCTAssertEqual(body["model"] as? String, "claude-sonnet-4-5")
        XCTAssertEqual(body["max_tokens"] as? Int, 3024)

        let system = try XCTUnwrap(body["system"] as? [[String: Any]])
        let systemCache = try XCTUnwrap(system.first?["cache_control"] as? [String: String])
        XCTAssertEqual(systemCache, ["type": "ephemeral", "ttl": "1h"])

        let messages = try XCTUnwrap(body["messages"] as? [[String: Any]])
        let content = try XCTUnwrap(messages.first?["content"] as? [[String: Any]])
        let messageCache = try XCTUnwrap(content.first?["cache_control"] as? [String: String])
        XCTAssertEqual(messageCache, ["type": "ephemeral"])

        let tools = try XCTUnwrap(body["tools"] as? [[String: Any]])
        let toolCache = try XCTUnwrap(tools.first?["cache_control"] as? [String: String])
        XCTAssertEqual(toolCache, ["type": "ephemeral"])
    }
}
