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

import InfomaniakConcurrency
import XCTest

// MARK: - UTCollection async -

/// Minimal testing of the `async` functions, that are shorthands for the `concurrent` functions that are well tested
final class UTCollection_async: XCTestCase {
    // MARK: - asyncForEach

    func testAsyncForEach() {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let expectations = collectionToProcess.map { index in
            XCTestExpectation(description: "idx:\(index)")
        }

        XCTAssertEqual(collectionToProcess.count, 51)
        XCTAssertEqual(expectations.count, collectionToProcess.count, "Expected to match")

        // WHEN
        Task {
            await collectionToProcess.asyncForEach { index in
                expectations[index].fulfill()
            }
        }

        // THEN
        wait(for: expectations, timeout: 10.0)
    }

    // MARK: - asyncMap

    func testAsyncMap() {
        asyncTestWrapper {
            // GIVEN
            let collectionToProcess = Array(0 ... 50)

            // WHEN
            let result = await collectionToProcess.concurrentMap { item in
                return item * 10
            }

            // THEN
            // We check order is preserved
            _ = result.reduce(-1) { partialResult, item in
                XCTAssertGreaterThan(item, partialResult)
                return item
            }

            XCTAssertEqual(result.count, collectionToProcess.count)
        }
    }
    
    // MARK: - asyncCompactMap
    
    func testAsyncCompactMap() {
        asyncTestWrapper {
            // GIVEN
            let collectionToProcess = Array(0 ... 50)

            // WHEN
            let result: [Int] = await collectionToProcess.asyncCompactMap { item in
                // We arbitrarily remove elements
                if item % 10 == 0 {
                    return nil
                }
                return item * 10
            }

            // THEN
            // We check order is preserved
            _ = result.reduce(-1) { partialResult, item in
                XCTAssertGreaterThan(item, partialResult)
                return item
            }

            XCTAssertEqual(result.count, collectionToProcess.count - 6)
        }
    }
}
