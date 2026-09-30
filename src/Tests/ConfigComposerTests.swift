import XCTest
@testable import CLIProxyMenuBar

final class ConfigComposerTests: XCTestCase {
    func testPreservesClientKeysAfterV8DashboardMigration() {
        // v8 moves client authentication to access.api-keys. Root api-keys now holds upstream credentials.
        let migrated: [String: Any] = [
            "config-version": 8,
            "access": ["api-keys": ["dashboard-client-key"]],
            "api-keys": ["claude": [["keys": [["api-key": "upstream-only"]]]]]
        ]
        let result = ConfigComposer.preservingRuntimeEditableTopLevelKeys(in: ["port": 8318], from: migrated)
        XCTAssertEqual(result["api-keys"] as? [String], ["dashboard-client-key"])
        XCTAssertEqual(result["port"] as? Int, 8318)
    }

    func testDoesNotImportV8UpstreamGroupsAsClientKeys() {
        let migrated: [String: Any] = ["api-keys": ["claude": [["keys": [["api-key": "upstream-only"]]]]]]
        let result = ConfigComposer.preservingRuntimeEditableTopLevelKeys(in: [:], from: migrated)
        XCTAssertNil(result["api-keys"])
    }

    func testExplicitV8ClientKeysOverrideRuntimeKeysIncludingEmptyList() {
        for keys in [["configured-key"], []] {
            let root: [String: Any] = ["access": ["api-keys": keys]]
            let result = ConfigComposer.preservingRuntimeEditableTopLevelKeys(in: root, from: ["api-keys": ["runtime-key"]])
            XCTAssertNil(result["api-keys"])
            XCTAssertEqual((result["access"] as? [String: Any])?["api-keys"] as? [String], keys)
        }
    }

    func testPreservesRuntimeEditedTopLevelAPIKeysWhenBaseDoesNotDefineThem() {
        let root: [String: Any] = ["port": 8318]
        let runtimeRoot: [String: Any] = [
            "api-keys": ["local-key"],
            "port": 9000
        ]

        let result = ConfigComposer.preservingRuntimeEditableTopLevelKeys(
            in: root,
            from: runtimeRoot
        )

        XCTAssertEqual(result["api-keys"] as? [String], ["local-key"])
        XCTAssertEqual(result["port"] as? Int, 8318)
    }

    func testDoesNotOverwriteExplicitTopLevelAPIKeys() {
        let root: [String: Any] = ["api-keys": ["configured-key"]]
        let runtimeRoot: [String: Any] = ["api-keys": ["runtime-key"]]

        let result = ConfigComposer.preservingRuntimeEditableTopLevelKeys(
            in: root,
            from: runtimeRoot
        )

        XCTAssertEqual(result["api-keys"] as? [String], ["configured-key"])
    }
}
