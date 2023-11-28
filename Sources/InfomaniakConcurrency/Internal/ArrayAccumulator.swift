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

/// A generic async/await accumulator, order preserving.
///
/// This is a thread safe actor.
/// It is backed by a fix length array, size defined at init.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
actor ArrayAccumulator<T> {
    /// Local Error Domain
    public enum ErrorDomain: Error {
        case outOfBounds
    }

    /// A buffer array
    private var buffer: [T?]

    /// Init an ArrayAccumulator
    /// - Parameters:
    ///   - count: The count of items in the accumulator
    ///   - wrapping: The type of the content wrapped in an array
    public init(count: Int, wrapping: T.Type) {
        buffer = [T?](repeating: nil, count: count)
    }

    /// Set an item at a specified index
    /// - Parameters:
    ///   - item: the item to be stored
    ///   - index: The index where we store the item
    public func set(item: T?, atIndex index: Int) throws {
        guard index < buffer.count else {
            throw ErrorDomain.outOfBounds
        }
        buffer[index] = item
    }

    /// The accumulated ordered nullable content at the time of calling
    /// - Returns: The ordered nullable content at the time of calling
    public var accumulation: [T?] {
        return buffer
    }

    /// The accumulated ordered result at the time of calling. Nil values are removed.
    /// - Returns: The ordered result at the time of calling. Nil values are removed.
    public var compactAccumulation: [T] {
        return buffer.compactMap { $0 }
    }
}
