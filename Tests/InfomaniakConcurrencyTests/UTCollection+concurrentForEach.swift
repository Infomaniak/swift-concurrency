//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

import Foundation
import XCTest

// MARK: - UTConcurrentForEach -

final class UTConcurrentForEach: XCTestCase {
    private enum DomainError: Error {
        case some
        case someOther
    }

    // MARK: - concurrentForEach

    func testConcurrentForEach() {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let expectations = collectionToProcess.map { index in
            XCTestExpectation(description: "idx:\(index)")
        }

        XCTAssertEqual(collectionToProcess.count, 51)
        XCTAssertEqual(expectations.count, collectionToProcess.count, "Expected to match")

        // WHEN
        Task {
            await collectionToProcess.concurrentForEach { index in
                expectations[index].fulfill()
            }
        }

        // THEN
        wait(for: expectations, timeout: 10.0)
    }

    func testConcurrentForEach_ArraySlice() {
        // GIVEN
        let collectionToProcess = Array(0 ... 200)
        let collectionSlice: ArraySlice<Int> = collectionToProcess[0 ... 50]
        let expectations = collectionSlice.map { index in
            XCTestExpectation(description: "idx:\(index)")
        }

        XCTAssertEqual(collectionToProcess.count, 201)
        XCTAssertEqual(collectionSlice.count, 51)
        XCTAssertEqual(expectations.count, collectionSlice.count, "Expected to match")

        // WHEN
        Task {
            await collectionSlice.concurrentForEach { index in
                expectations[index].fulfill()
            }
        }

        // THEN
        wait(for: expectations, timeout: 10.0)
    }

    func testConcurrentForEach_Dictionary() {
        // GIVEN
        let key = Array(0 ... 50)

        var dictionaryToProcess = [String: Int]()
        for (key, value) in key.enumerated() {
            dictionaryToProcess["\(key)"] = value
        }

        let expectations = dictionaryToProcess.map { node in
            XCTestExpectation(description: "idx:\(node.key)")
        }

        XCTAssertEqual(dictionaryToProcess.count, 51)
        XCTAssertEqual(expectations.count, dictionaryToProcess.count, "Expected to match")

        let toProcess = dictionaryToProcess
        // WHEN
        Task {
            await toProcess.concurrentForEach { node in
                guard let index = Int(node.key) else {
                    XCTFail("Unexpected issue \(node.key)")
                    return
                }
                expectations[index].fulfill()
            }
        }

        // THEN
        wait(for: expectations, timeout: 10.0)
    }

    func testConcurrentForEach_Sleep() {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let expectations = collectionToProcess.map { index in
            XCTestExpectation(description: "idx:\(index)")
        }

        XCTAssertEqual(collectionToProcess.count, 51)
        XCTAssertEqual(expectations.count, collectionToProcess.count, "Expected to match")

        // WHEN
        asyncTestWrapper {
            try await collectionToProcess.concurrentForEach { index in
                // Make the process take some short arbitrary time to complete
                let randomShortTime = UInt64.random(in: 1 ... 100)
                try await Task.sleep(nanoseconds: randomShortTime)

                expectations[index].fulfill()
            }
        }

        // THEN
        wait(for: expectations, timeout: 10.0)
    }

    func testConcurrentForEach_Throwing() {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let expectation = XCTestExpectation(description: "Await async function to throw")

        XCTAssertEqual(collectionToProcess.count, 51)

        // WHEN
        asyncTestWrapper {
            do {
                try await collectionToProcess.concurrentForEach { index in
                    // Make the process take some short arbitrary time to complete
                    let randomShortTime = UInt64.random(in: 1 ... 100)
                    try await Task.sleep(nanoseconds: randomShortTime)

                    if index == 20 {
                        throw DomainError.some
                    }
                }
            } catch {
                guard let error = error as? DomainError else {
                    XCTFail("Unexpected error type")
                    return
                }

                guard error == .some else {
                    XCTFail("Unexpected error case")
                    return
                }

                // All good at this point
                expectation.fulfill()
            }
        }

        // THEN
        wait(for: [expectation], timeout: 10.0)
        // All good at this point
    }
}
