//
//  File.swift
//  
//
//  Created by Igor Ferreira on 06/04/2022.
//

import XCTest
@testable import GIFImage

final class InfrastructureTests: XCTestCase {
    
    override func setUp() async throws {
        URLProtocol.registerClass(MockedURLProtocol.self)
        MockedURLProtocol.reset()
    }
    
    override func tearDown() async throws {
        URLProtocol.unregisterClass(MockedURLProtocol.self)
        MockedURLProtocol.reset()
    }
    
    func testBasicMockStructure() async throws {
        let url = URL(string: "https://www.test.com")!
        MockedURLProtocol.register(.failure(URLError(.init(rawValue: 404))), to: url)
        let urlSession = MockedURLProtocol.buildTestSession()
        
        let (data, response) = try await urlSession.data(for: URLRequest(url: url))
        XCTAssertEqual(data, Data())
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 404)
    }
    
    func testMockedFileManager() async throws {
        let fileManager = MockedFileManager()
        let data = Data()
        let path = "/mock/path"
        fileManager.register(data, toPath: path)
        
        XCTAssertFalse(fileManager.fileExists(atPath: "/mock/empty_path"))
        XCTAssertNil(fileManager.contents(atPath: "/mock/empty_path"))
        
        XCTAssertTrue(fileManager.fileExists(atPath: path))
        XCTAssertEqual(data, fileManager.contents(atPath: path))
    }
}