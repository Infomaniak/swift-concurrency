# InfomaniakConcurrency

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FInfomaniak%2Fswift-concurrency%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Infomaniak/swift-concurrency) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FInfomaniak%2Fswift-concurrency%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Infomaniak/swift-concurrency)

## Abstract

Minimalist asynchronous concurrent operations on `Collection`. 

You can easily use more than one thread to perform work on a collection, achieving better parallelism while writing standard Swift with structured concurrency.

Support any first party Swift platfom. [ iOS / iPadOS / watchOS / macOS / Linux ]

Well tested. Used in production across Infomaniak's Apps written in Swift.

## Features

- `concurrentMap` 
    - Maps a task with nullable result __concurrently__, returning only non nil values. Input order __preserved__.
    - With this, you can easily __parallelize__  _async/await_ code.

- `concurrentCompactMap`
    - Maps a task to a collection of items concurrently. Input order __preserved__.
    - With this, you can easily __parallelize__  _async/await_ code.

An heuristic determines __parallelism__ for you, but can be customised.

This runs right now in production code but will be refactored to be more in line with Swift 5.9 paradigms.

This do not use `Task.yield()`. Implement yielding at your own discretion depending on your own workload. 

## Roadmap

This library is looking forward. 
Right now the internals are not exposed, as they will be replaced at some point.

I'd like to support [Custom Actor Executors](https://github.com/apple/swift-evolution/blob/main/proposals/0392-custom-actor-executors.md) to replace current internals ASAP.
