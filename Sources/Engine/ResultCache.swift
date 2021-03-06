//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

/// Key to identify parser results.
struct CacheKey: Hashable {
    let cache: ObjectIdentifier
    let position: Position
    let startOfWord: Bool
}

/// Stored parser result.
enum CachedResult {
    case cached(nodes: [Node], cursor: Cursor)
    case error(error: ParserError)
}

private class Wrapper {
    let parser: Parser<[Node]>
    init(_ parser: Parser<[Node]>) { self.parser = parser }
    var id: ObjectIdentifier { return ObjectIdentifier(self) }
}

/// Cache the result of a delegate parser.
/// Any further `parse` calls will return the exact same result.
public func cached(_ parser: Parser<[Node]>) -> Parser<[Node]> {
    let wrapper = Wrapper(parser)
    return Parser { input in
        let key = CacheKey(cache: wrapper.id,
                           position: input.position,
                           startOfWord: input.atStartOfWord)
        let scope = input.block

        if let found = scope.cache[key] {
            switch found {
            case .cached(let nodes, let cursor):
                return (nodes, cursor)
            case .error(let error):
                throw error
            }
        }
        do {
            let (nodes, cursor) = try wrapper.parser.parse(input)
            scope.cache[key] = .cached(nodes: nodes, cursor: cursor)
            return (nodes, cursor)
        } catch let error as ParserError {
            scope.cache[key] = .error(error: error)
            throw error
        }
    }
}
