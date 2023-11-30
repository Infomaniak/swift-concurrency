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

// MARK: - UTConcurrentMap -

final class UTConcurrentMap: XCTestCase {
    private enum DomainError: Error {
        case some
    }

    // MARK: - concurrentMap

    func testConcurrentMapToArray() async {
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

    func testConcurrentMapToArraySlice() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let collectionSlice: ArraySlice<Int> = collectionToProcess[0 ... 10]

        // WHEN
        let result = await collectionSlice.concurrentMap { item in
            return item * 10
        }

        // THEN
        // We check order is preserved
        _ = result.reduce(-1) { partialResult, item in
            XCTAssertGreaterThan(item, partialResult)
            return item
        }

        XCTAssertEqual(result.count, collectionSlice.count)
    }

    func testConcurrentMapToDictionary() async {
        // GIVEN
        let key = Array(0 ... 50)

        var dictionaryToProcess = [String: Int]()
        for (key, value) in key.enumerated() {
            dictionaryToProcess["\(key)"] = value
        }

        XCTAssertEqual(dictionaryToProcess.count, 51, "sanity check precond")

        // WHEN
        let result = await dictionaryToProcess.concurrentMap { item in
            let newItem = (item.key, item.value * 10)
            return newItem
        }

        // THEN

        // NOTE: Not checking for order, since this is a Dictionary

        XCTAssertEqual(result.count, dictionaryToProcess.count)

        for (_, tuple) in result.enumerated() {
            let key = tuple.0
            guard let intKey = Int(key) else {
                XCTFail("Unexpected")
                return
            }

            let value = tuple.1
            XCTAssertEqual(intKey * 10, value, "expecting the computation to have happened")
        }
    }

    // MARK: - concurrentMap throwing sleep

    func testConcurrentMapToArrayThrowingSleep() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)

        // WHEN
        do {
            let result = try await collectionToProcess.concurrentMap { item in
                // Make the process take some short arbitrary time to complete
                let randomShortTime = UInt64.random(in: 1 ... 100)
                try await Task.sleep(nanoseconds: randomShortTime)

                return item * 10
            }

            // THEN
            // We check order is preserved
            _ = result.reduce(-1) { partialResult, item in
                XCTAssertGreaterThan(item, partialResult)
                return item
            }

            XCTAssertEqual(result.count, collectionToProcess.count)

        } catch {
            XCTFail("Unexpected")
            return
        }
    }

    func testConcurrentMapToArraySliceThrowingSleep() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let collectionSlice: ArraySlice<Int> = collectionToProcess[0 ... 10]

        // WHEN
        do {
            let result = try await collectionSlice.concurrentMap { item in
                // Make the process take some short arbitrary time to complete
                let randomShortTime = UInt64.random(in: 1 ... 100)
                try await Task.sleep(nanoseconds: randomShortTime)

                return item * 10
            }

            // THEN
            // We check order is preserved
            _ = result.reduce(-1) { partialResult, item in
                XCTAssertGreaterThan(item, partialResult)
                return item
            }

            XCTAssertEqual(result.count, collectionSlice.count)

        } catch {
            XCTFail("Unexpected")
            return
        }
    }

    func testConcurrentMapToDictionaryThrowingSleep() async {
        // GIVEN
        let key = Array(0 ... 50)

        var dictionaryToProcess = [String: Int]()
        for (key, value) in key.enumerated() {
            dictionaryToProcess["\(key)"] = value
        }

        XCTAssertEqual(dictionaryToProcess.count, 51, "sanity check precond")

        // WHEN
        do {
            let result = try await dictionaryToProcess.concurrentMap { item in
                let newItem = (item.key, item.value * 10)
                // Make the process take some short arbitrary time to complete
                let randomShortTime = UInt64.random(in: 1 ... 100)
                try await Task.sleep(nanoseconds: randomShortTime)
                return newItem
            }

            // THEN

            // NOTE: Not checking for order, since this is a Dictionary

            XCTAssertEqual(result.count, dictionaryToProcess.count)

            for (_, tuple) in result.enumerated() {
                let key = tuple.0
                guard let intKey = Int(key) else {
                    XCTFail("Unexpected")
                    return
                }

                let value = tuple.1
                XCTAssertEqual(intKey * 10, value, "expecting the computation to have happened")
            }

        } catch {
            XCTFail("Unexpected")
            return
        }
    }

    // MARK: - concurrentMap throwing computation

    func testConcurrentMapToArrayThrowingComputation() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)

        // WHEN
        do {
            let _ = try await collectionToProcess.concurrentMap { item in
                if item == 10 {
                    throw DomainError.some
                }

                return item * 10
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard case DomainError.some = error else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }

    func testConcurrentMapToArraySliceThrowingComputation() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let collectionSlice: ArraySlice<Int> = collectionToProcess[0 ... 10]

        // WHEN
        do {
            let _ = try await collectionSlice.concurrentMap { item in
                if item == 10 {
                    throw DomainError.some
                }

                return item * 10
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard case DomainError.some = error else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }

    func testConcurrentMapToDictionaryThrowingComputation() async {
        // GIVEN
        let key = Array(0 ... 50)

        var dictionaryToProcess = [String: Int]()
        for (key, value) in key.enumerated() {
            dictionaryToProcess["\(key)"] = value
        }

        XCTAssertEqual(dictionaryToProcess.count, 51, "sanity check precond")

        // WHEN
        do {
            let _ = try await dictionaryToProcess.concurrentMap { item in
                let newItem = (item.key, item.value * 10)

                if item.value == 10 {
                    throw DomainError.some
                }

                return newItem
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard case DomainError.some = error else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }

    // MARK: - concurrentMap throwing cancellation

    func testConcurrentMapToArrayThrowingCancellation() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)

        // WHEN
        do {
            let _ = try await collectionToProcess.concurrentMap { item in
                if item == 10 {
                    throw CancellationError()
                }

                return item * 10
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard error is CancellationError else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }

    func testConcurrentMapToArraySliceThrowingCancellation() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let collectionSlice: ArraySlice<Int> = collectionToProcess[0 ... 10]

        // WHEN
        do {
            let _ = try await collectionSlice.concurrentMap { item in
                if item == 10 {
                    throw CancellationError()
                }

                return item * 10
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard error is CancellationError else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }

    func testConcurrentMapToDictionaryThrowingCancellation() async {
        // GIVEN
        let key = Array(0 ... 50)

        var dictionaryToProcess = [String: Int]()
        for (key, value) in key.enumerated() {
            dictionaryToProcess["\(key)"] = value
        }

        XCTAssertEqual(dictionaryToProcess.count, 51, "sanity check precond")

        // WHEN
        do {
            let _ = try await dictionaryToProcess.concurrentMap { item in
                let newItem = (item.key, item.value * 10)

                if item.value == 10 {
                    throw CancellationError()
                }

                return newItem
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard error is CancellationError else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }

    // MARK: - nullability of output types

    func testConcurrentMapNonNullableOutputTypes() async {
        // GIVEN
        let collectionToProcess: [Int] = [1, 2, 3, 4, 5]

        let result: [Int] = await collectionToProcess.concurrentMap { someInt in
            return someInt + 1
        }

        // THEN
        // We check order is preserved
        _ = result.reduce(-1) { partialResult, item in
            XCTAssertGreaterThan(item, partialResult)
            return item
        }

        // Expecting same behaviour as a standard lib map
        XCTAssertEqual(result.count, collectionToProcess.count)
    }

    func testConcurrentMapNullableOutputTypes() async {
        // GIVEN
        let collectionToProcess: [Int?] = [1, nil, 3, 4, nil, 5]

        let result: [Int?] = await collectionToProcess.concurrentMap { someInt in
            guard let someInt else {
                return nil
            }

            return someInt + 1
        }

        // THEN
        // We check order is preserved
        _ = result.reduce(-1) { partialResult, item in
            guard let item else {
                // Ok to find a nil here
                return partialResult
            }

            XCTAssertGreaterThan(item, partialResult)
            return item
        }

        // Expecting same behaviour as a standard lib map, preserving nullable in result.
        XCTAssertEqual(result.count, collectionToProcess.count)
    }
}

// MARK: - UTConcurrentMap_CustomConcurrency -

final class UTConcurrentMap_CustomConcurrency: XCTestCase {
    private enum DomainError: Error {
        case some
    }

    // MARK: - concurrentMap

    func testConcurrentMapToArray() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)

        // WHEN
        let result = await collectionToProcess.concurrentMap(customConcurrency: randomConcurrencyDepth) { item in
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

    func testConcurrentMapToArraySlice() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let collectionSlice: ArraySlice<Int> = collectionToProcess[0 ... 10]

        // WHEN
        let result = await collectionSlice.concurrentMap(customConcurrency: randomConcurrencyDepth) { item in
            return item * 10
        }

        // THEN
        // We check order is preserved
        _ = result.reduce(-1) { partialResult, item in
            XCTAssertGreaterThan(item, partialResult)
            return item
        }

        XCTAssertEqual(result.count, collectionSlice.count)
    }

    func testConcurrentMapToDictionary() async {
        // GIVEN
        let key = Array(0 ... 50)

        var dictionaryToProcess = [String: Int]()
        for (key, value) in key.enumerated() {
            dictionaryToProcess["\(key)"] = value
        }

        XCTAssertEqual(dictionaryToProcess.count, 51, "sanity check precond")

        // WHEN
        let result = await dictionaryToProcess.concurrentMap(customConcurrency: randomConcurrencyDepth) { item in
            let newItem = (item.key, item.value * 10)
            return newItem
        }

        // THEN

        // NOTE: Not checking for order, since this is a Dictionary

        XCTAssertEqual(result.count, dictionaryToProcess.count)

        for (_, tuple) in result.enumerated() {
            let key = tuple.0
            guard let intKey = Int(key) else {
                XCTFail("Unexpected")
                return
            }

            let value = tuple.1
            XCTAssertEqual(intKey * 10, value, "expecting the computation to have happened")
        }
    }

    // MARK: - concurrentMap throwing sleep

    func testConcurrentMapToArrayThrowingSleep() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)

        // WHEN
        do {
            let result = try await collectionToProcess.concurrentMap(customConcurrency: randomConcurrencyDepth) { item in
                // Make the process take some short arbitrary time to complete
                let randomShortTime = UInt64.random(in: 1 ... 100)
                try await Task.sleep(nanoseconds: randomShortTime)

                return item * 10
            }

            // THEN
            // We check order is preserved
            _ = result.reduce(-1) { partialResult, item in
                XCTAssertGreaterThan(item, partialResult)
                return item
            }

            XCTAssertEqual(result.count, collectionToProcess.count)

        } catch {
            XCTFail("Unexpected")
            return
        }
    }

    func testConcurrentMapToArraySliceThrowingSleep() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let collectionSlice: ArraySlice<Int> = collectionToProcess[0 ... 10]

        // WHEN
        do {
            let result = try await collectionSlice.concurrentMap(customConcurrency: randomConcurrencyDepth) { item in
                // Make the process take some short arbitrary time to complete
                let randomShortTime = UInt64.random(in: 1 ... 100)
                try await Task.sleep(nanoseconds: randomShortTime)

                return item * 10
            }

            // THEN
            // We check order is preserved
            _ = result.reduce(-1) { partialResult, item in
                XCTAssertGreaterThan(item, partialResult)
                return item
            }

            XCTAssertEqual(result.count, collectionSlice.count)

        } catch {
            XCTFail("Unexpected")
            return
        }
    }

    func testConcurrentMapToDictionaryThrowingSleep() async {
        // GIVEN
        let key = Array(0 ... 50)

        var dictionaryToProcess = [String: Int]()
        for (key, value) in key.enumerated() {
            dictionaryToProcess["\(key)"] = value
        }

        XCTAssertEqual(dictionaryToProcess.count, 51, "sanity check precond")

        // WHEN
        do {
            let result = try await dictionaryToProcess.concurrentMap(customConcurrency: randomConcurrencyDepth) { item in
                let newItem = (item.key, item.value * 10)
                // Make the process take some short arbitrary time to complete
                let randomShortTime = UInt64.random(in: 1 ... 100)
                try await Task.sleep(nanoseconds: randomShortTime)
                return newItem
            }

            // THEN

            // NOTE: Not checking for order, since this is a Dictionary

            XCTAssertEqual(result.count, dictionaryToProcess.count)

            for (_, tuple) in result.enumerated() {
                let key = tuple.0
                guard let intKey = Int(key) else {
                    XCTFail("Unexpected")
                    return
                }

                let value = tuple.1
                XCTAssertEqual(intKey * 10, value, "expecting the computation to have happened")
            }

        } catch {
            XCTFail("Unexpected")
            return
        }
    }

    // MARK: - concurrentMap throwing computation

    func testConcurrentMapToArrayThrowingComputation() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)

        // WHEN
        do {
            let _ = try await collectionToProcess.concurrentMap(customConcurrency: randomConcurrencyDepth) { item in
                if item == 10 {
                    throw DomainError.some
                }

                return item * 10
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard case DomainError.some = error else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }

    func testConcurrentMapToArraySliceThrowingComputation() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let collectionSlice: ArraySlice<Int> = collectionToProcess[0 ... 10]

        // WHEN
        do {
            let _ = try await collectionSlice.concurrentMap(customConcurrency: randomConcurrencyDepth) { item in
                if item == 10 {
                    throw DomainError.some
                }

                return item * 10
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard case DomainError.some = error else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }

    func testConcurrentMapToDictionaryThrowingComputation() async {
        // GIVEN
        let key = Array(0 ... 50)

        var dictionaryToProcess = [String: Int]()
        for (key, value) in key.enumerated() {
            dictionaryToProcess["\(key)"] = value
        }

        XCTAssertEqual(dictionaryToProcess.count, 51, "sanity check precond")

        // WHEN
        do {
            let _ = try await dictionaryToProcess.concurrentMap(customConcurrency: randomConcurrencyDepth) { item in
                let newItem = (item.key, item.value * 10)

                if item.value == 10 {
                    throw DomainError.some
                }

                return newItem
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard case DomainError.some = error else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }

    // MARK: - concurrentMap throwing cancellation

    func testConcurrentMapToArrayThrowingCancellation() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)

        // WHEN
        do {
            let _ = try await collectionToProcess.concurrentMap(customConcurrency: randomConcurrencyDepth) { item in
                if item == 10 {
                    throw CancellationError()
                }

                return item * 10
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard error is CancellationError else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }

    func testConcurrentMapToArraySliceThrowingCancellation() async {
        // GIVEN
        let collectionToProcess = Array(0 ... 50)
        let collectionSlice: ArraySlice<Int> = collectionToProcess[0 ... 10]

        // WHEN
        do {
            let _ = try await collectionSlice.concurrentMap(customConcurrency: randomConcurrencyDepth) { item in
                if item == 10 {
                    throw CancellationError()
                }

                return item * 10
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard error is CancellationError else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }

    func testConcurrentMapToDictionaryThrowingCancellation() async {
        // GIVEN
        let key = Array(0 ... 50)

        var dictionaryToProcess = [String: Int]()
        for (key, value) in key.enumerated() {
            dictionaryToProcess["\(key)"] = value
        }

        XCTAssertEqual(dictionaryToProcess.count, 51, "sanity check precond")

        // WHEN
        do {
            let _ = try await dictionaryToProcess.concurrentMap(customConcurrency: randomConcurrencyDepth) { item in
                let newItem = (item.key, item.value * 10)

                if item.value == 10 {
                    throw CancellationError()
                }

                return newItem
            }

            // THEN
            XCTFail("Expected to throw")

        } catch {
            guard error is CancellationError else {
                XCTFail("Unexpected")
                return
            }

            // All good
        }
    }

    // MARK: - nullability of output types

    func testConcurrentMapNonNullableOutputTypes() async {
        // GIVEN
        let collectionToProcess: [Int] = [1, 2, 3, 4, 5]

        let result: [Int] = await collectionToProcess.concurrentMap(customConcurrency: randomConcurrencyDepth) { someInt in
            return someInt + 1
        }

        // THEN
        // We check order is preserved
        _ = result.reduce(-1) { partialResult, item in
            XCTAssertGreaterThan(item, partialResult)
            return item
        }

        // Expecting same behaviour as a standard lib map
        XCTAssertEqual(result.count, collectionToProcess.count)
    }

    func testConcurrentMapNullableOutputTypes() async {
        // GIVEN
        let collectionToProcess: [Int?] = [1, nil, 3, 4, nil, 5]

        let result: [Int?] = await collectionToProcess.concurrentMap(customConcurrency: randomConcurrencyDepth) { someInt in
            guard let someInt else {
                return nil
            }

            return someInt + 1
        }

        // THEN
        // We check order is preserved
        _ = result.reduce(-1) { partialResult, item in
            guard let item else {
                // Ok to find a nil here
                return partialResult
            }

            XCTAssertGreaterThan(item, partialResult)
            return item
        }

        // Expecting same behaviour as a standard lib map, preserving nullable in result.
        XCTAssertEqual(result.count, collectionToProcess.count)
    }
}
