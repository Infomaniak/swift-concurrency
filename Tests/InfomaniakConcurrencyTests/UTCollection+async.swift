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

enum SomeError: Error {
    case some
}

final class SomeClass: Sendable {
    init(value: Int) {
        self.value = value
    }

    let value: Int

    var valueAsync: Int {
        get async throws {
            let nanoseconds = UInt64.random(in: 100_000 ..< 100_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            return value
        }
    }
}

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

    // MARK: - asyncReduce

    // asyncReduce to int

    func testAsyncReduceInt() {
        asyncTestWrapper {
            // GIVEN
            let collectionToProcess = Array(0 ... 50)

            // WHEN
            let asyncSum = try await collectionToProcess.asyncReduce(0) { partialResult, item in
                // We arbitrarily remove elements
                if item % 10 == 0 {
                    try await Task.sleep(nanoseconds: 100_000_000)
                }

                return partialResult + item
            }

            // THEN
            let sum = collectionToProcess.reduce(0) { $0 + $1 }
            XCTAssertEqual(sum, asyncSum, "Expecting a naive sum to equal the async one")
        }
    }

    func testAsyncReduceIntThrow() {
        asyncTestWrapper {
            // GIVEN
            let collectionToProcess = Array(0 ... 50)

            // WHEN
            do {
                let asyncSum = try await collectionToProcess.asyncReduce(0) { partialResult, item in
                    // We arbitrarily remove elements
                    if item % 10 == 0 {
                        throw SomeError.some
                    }

                    return partialResult + item
                }

                XCTFail("expected to throw, got \(asyncSum) instead")
            }

            // THEN
            catch {
                guard let someError = error as? SomeError,
                      someError == .some else {
                    XCTFail("unexpected error: \(error)")
                    return
                }
                // all good
            }
        }
    }

    func testAsyncReduceIntInto() {
        asyncTestWrapper {
            // GIVEN
            let collectionToProcess = Array(0 ... 50)

            // WHEN
            let seed = 0
            let asyncSum = try await collectionToProcess.asyncReduce(into: seed) { partialResult, item in
                // We arbitrarily remove elements
                if item % 10 == 0 {
                    try await Task.sleep(nanoseconds: 100_000_000)
                }

                partialResult = partialResult + item
            }

            // THEN
            let sum = collectionToProcess.reduce(0) { $0 + $1 }
            XCTAssertEqual(sum, asyncSum, "Expecting a naive sum to equal the async one")
        }
    }

    func testAsyncReduceIntoIntThrow() {
        asyncTestWrapper {
            // GIVEN
            let collectionToProcess = Array(0 ... 50)

            // WHEN
            do {
                let seed = 0
                let asyncSum = try await collectionToProcess.asyncReduce(into: seed) { partialResult, item in
                    // Throw exception during the reduce process
                    if item % 10 == 0 {
                        throw SomeError.some
                    }

                    partialResult = partialResult + item
                }

                XCTFail("expected to throw, got \(asyncSum) instead")
            }

            // THEN
            catch {
                guard let someError = error as? SomeError,
                      someError == .some else {
                    XCTFail("unexpected error: \(error)")
                    return
                }
                // all good
            }
        }
    }

    // asyncReduce to Class

    func testAsyncReduceClass() {
        asyncTestWrapper {
            // GIVEN
            var collectionToProcess = [SomeClass]()
            for index in 0 ... 50 {
                collectionToProcess.append(SomeClass(value: index))
            }

            // WHEN
            let asyncSum = try await collectionToProcess.asyncReduce(0) { partialResult, item in
                let value = try await item.valueAsync
                return partialResult + value
            }

            // THEN
            let sum = collectionToProcess.reduce(0) { $0 + $1.value }
            XCTAssertEqual(sum, asyncSum, "Expecting a naive sum to equal the async one")
        }
    }

    func testAsyncReduceClassThrow() {
        asyncTestWrapper {
            // GIVEN
            var collectionToProcess = [SomeClass]()
            for index in 0 ... 50 {
                collectionToProcess.append(SomeClass(value: index))
            }

            // WHEN
            do {
                let asyncSum = try await collectionToProcess.asyncReduce(0) { partialResult, item in
                    let value = try await item.valueAsync

                    // Throw exception during the reduce process
                    if value % 10 == 0 {
                        throw SomeError.some
                    }

                    return partialResult + value
                }

                XCTFail("expected to throw, got \(asyncSum) instead")
            }

            // THEN
            catch {
                guard let someError = error as? SomeError,
                      someError == .some else {
                    XCTFail("unexpected error: \(error)")
                    return
                }
                // all good
            }
        }
    }

    func testAsyncReduceClassInto() {
        asyncTestWrapper {
            // GIVEN
            var collectionToProcess = [SomeClass]()
            for index in 0 ... 50 {
                collectionToProcess.append(SomeClass(value: index))
            }

            // WHEN
            let seed = 0
            let asyncSum = try await collectionToProcess.asyncReduce(into: seed) { partialResult, item in
                let value = try await item.valueAsync
                partialResult = partialResult + value
            }

            // THEN
            let sum = collectionToProcess.reduce(0) { $0 + $1.value }
            XCTAssertEqual(sum, asyncSum, "Expecting a naive sum to equal the async one")
        }
    }

    func testAsyncReduceIntoClassThrow() {
        asyncTestWrapper {
            // GIVEN
            var collectionToProcess = [SomeClass]()
            for index in 0 ... 50 {
                collectionToProcess.append(SomeClass(value: index))
            }

            // WHEN
            do {
                let seed = 0
                let asyncSum = try await collectionToProcess.asyncReduce(into: seed) { partialResult, item in
                    let value = try await item.valueAsync

                    // Throw exception during the reduce process
                    if value % 10 == 0 {
                        throw SomeError.some
                    }

                    partialResult = partialResult + value
                }

                XCTFail("expected to throw, got \(asyncSum) instead")
            }

            // THEN
            catch {
                guard let someError = error as? SomeError,
                      someError == .some else {
                    XCTFail("unexpected error: \(error)")
                    return
                }
                // all good
            }
        }
    }

    // asyncReduce no throw

    func testAsyncReduceIntNoThrow() {
        asyncTestWrapper {
            // GIVEN
            let collectionToProcess = Array(0 ... 50)

            // WHEN
            let asyncSum = await collectionToProcess.asyncReduce(0) { partialResult, item in
                return partialResult + item
            }

            // THEN
            let sum = collectionToProcess.reduce(0) { $0 + $1 }
            XCTAssertEqual(sum, asyncSum, "Expecting a naive sum to equal the async one")
        }
    }
}
