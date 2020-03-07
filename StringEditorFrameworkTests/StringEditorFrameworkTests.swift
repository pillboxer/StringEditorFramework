//
//  StringEditorFrameworkTests.swift
//  StringEditorFrameworkTests
//
//  Created by Henry Cooper on 03/03/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import XCTest
@testable import StringEditorFramework

class StringEditorFrameworkTests: XCTestCase {

   let manager = BitbucketManager.shared
    
    override func setUp() {
        let semaphore = DispatchSemaphore(value: 0)
        manager.load { (error) in
            if let error = error {
                starPrint(error)
            }
            semaphore.signal()
        }
        semaphore.wait()
    }
    
    func testLatestHashIsValidHash() {
        let expectation = self.expectation(description: "Valid Hash Expectation")
        var latestHash: String?
        
        manager.getLatestHash { (error, commitHash) in
            latestHash = commitHash
            expectation.fulfill()
        }
        waitForExpectations(timeout: 25, handler: nil)
        
        if let latestHash = latestHash {
            XCTAssertTrue(latestHash.count == 40, "\(latestHash.count) is not equal to 40")
        }
    }
    
    func testStringsFileIsRetrievable() {
        XCTAssert(manager.latestStrings != nil)
    }
    
    func testCanAddToStringsFile() {
        let newKey = "*** THIS IS MY KEY ***"
        let newValue = "*** THIS IS MY VALUE ***"
        if var stringsFile = manager.latestStrings {
            stringsFile.add(key: newKey, value: newValue)
            XCTAssert(stringsFile.contains(key: newKey))
        }
        else {
            XCTAssert(false)
        }
        
    }
    
    func testAddedKeyAndValueAreInNewStringsFile() {
        
        let expectation = self.expectation(description: "New Strings File Contains Key And Value")
        let key = UUID().uuidString
        let value = "MyValue"
        
        if var stringsFile  = manager.latestStrings {
            if !stringsFile.add(key: key, value: value) {
                XCTAssert(false, "File already contains key")
                return
            }
            
            let endpoint = Endpoint.src
            var request = URLRequest(endpoint: endpoint)
            var latestError: RequestError?
            request.postWithData(data: stringsFile.dataReadyForFormRequest(formKey: endpoint.formKey)) { (error) in
                latestError = error
                self.manager.load { (error) in
                    latestError = error
                    if let latestError = latestError {
                        print(latestError)
                        XCTAssert(false)
                        return
                    }
                    expectation.fulfill()
                }
                
            }
            waitForExpectations(timeout: 25, handler: nil)
            
            guard let latestStrings = self.manager.latestStrings else {
                XCTAssert(false)
                return
            }
            
            XCTAssert(latestStrings.contains(key: key))
        }
    }
}
