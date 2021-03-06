//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

import Foundation

public protocol ObjectIdentity: class, Hashable {}
extension ObjectIdentity {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
}

public protocol DocumentLoaderDelegate {
    func load(fromFile: String, scope: Scope) throws -> Document
}

public class Document: ObjectIdentity {
    public init(source: String, global: Scope, loader: DocumentLoaderDelegate) {
        self.source = source
        self.global = global
        self.loader = loader
    }

    let source: String
    public let global: Scope
    public let loader: DocumentLoaderDelegate

    func start() -> Cursor {
        return Cursor(at: block, scope: global, element: nil)
    }

    var root: Node?
    private lazy var block: Block = self.createRootBlock()
}

extension Document {

    /// Parse the entire document
    public func parse() -> [Node] {
        let whole = global.blockParser <+> expectEndOfBlock
        let (nodes, _) = try! whole.parse(start())
        return nodes
    }
}

extension Document {

    private func primordialBlock() -> Block {
        let start = Position(startOf: self)
        let primordial = Line(start: start, endIndex: source.endIndex)
        return Block(document: self, lines: [primordial])
    }

    fileprivate func createRootBlock() -> Block {
        var primordial = Cursor(at: primordialBlock(), scope: global, element: nil)
        var lines: [Line] = []
        var lineStart = primordial.position
        var lineEnd = lineStart
        // go through the document (one 'line' in the primordial block)
        while !primordial.atEndOfLine {
            switch source[primordial.position.index] {
            case "\n":
                let line = Line(start: lineStart, endIndex: lineEnd.index)
                lines.append(line)
                try! primordial.advance()
                lineStart = primordial.position
                lineEnd = lineStart
            case "\r":
                // ignore it, don't advance lineEnd
                try! primordial.advance()
            default:
                try! primordial.advance()
                lineEnd = primordial.position
            }
        }
        if lineStart != lineEnd {
            let line = Line(start: lineStart, endIndex: lineEnd.index)
            lines.append(line)
        }

        return Block(document: self, lines: lines)
    }
}


// Nodes are used for the first parst phase
// They describe the hierarchical structure of the
// input document
public struct Node {
    public let range: SourceRange
    public let document: Document
    public let nodeType: NodeType
    public let attributes: [String: String]
    public let children: [Node]
}

extension Node {
    public init(start: Position, end: Cursor, nodeType: NodeType,
                attributes: [String: String] = [:], children: [Node] = []) {
        self.range = SourceRange(start: start, end: end.position)
        self.document = end.document
        self.nodeType = nodeType
        self.attributes = attributes
        self.children = children

        self.nodeType.prepare(self, end.scope)
    }
}

extension Node: Equatable {
    public static func ==(lhs: Node, rhs: Node) -> Bool {
        return lhs.document == rhs.document
            && lhs.range == rhs.range
            && ObjectIdentifier(lhs.nodeType) == ObjectIdentifier(rhs.nodeType)
    }
}

extension Node {
    public var sourceRange: String {
        return String(describing: range)
    }
    public var sourceContent: Substring {
        return range.content
    }
}

open class NodeType {
    public var name: String
    public init(name: String) {
        self.name = name
    }
    open func prepare(_ node: Node, _ scope: Scope) {}
}

extension NodeType: CustomStringConvertible {
    public var description: String { return name }
}


/// A position within the source document.
/// It points between characters, so there always is one character
/// to the left and one to the right of each position
/// (but not for document start and end, obviously).
public struct Position {
    var index: String.Index
    fileprivate let document: Document
    fileprivate var line: Int
    fileprivate var column: Int

    fileprivate init(startOf document: Document) {
        self.index = document.source.startIndex
        self.document = document
        self.line = 1
        self.column = 0
    }

    init(at block: Block) {
        let lineIndex = block.lines.startIndex
        if lineIndex != block.lines.endIndex {
            self = block.lines[lineIndex].start
        } else {
            // no position available
            index = block.document.source.endIndex
            document = block.document
            line = 0
            column = 0
        }
    }
}

extension Position: CustomDebugStringConvertible {
    public var debugDescription: String { return right }

    /// Get the human readable position of the character to the left.
    var left: String {
        return "\(line):\(column)"
    }
    /// Get the human readable position of the character to the right.
    var right: String {
        return "\(line):\(column+1)"
    }
}

extension Position {
    /// Return a new Position pointing to the next character.
    func next() -> Position {
        let source = document.source
        var pos = self
        if source[index] == "\n" {
            pos.line += 1
            pos.column = 0
        } else {
            pos.column += 1
        }
        pos.index = source.index(after: index)
        return pos
    }
}

extension Position: Equatable {
    public static func ==(lhs: Position, rhs: Position) -> Bool {
        return lhs.index == rhs.index
            && lhs.document == rhs.document
    }
}
extension Position: Hashable {
    public var hashValue: Int {
        return index.encodedOffset
    }
}

public struct SourceRange {
    var start: Position
    var end: Position
}

extension SourceRange: CustomStringConvertible {
    public var description: String {
        return "\(start.right)..\(end.left)"
    }
}

extension SourceRange {
    public var content: Substring {
        assert(start.document == end.document)
        let source = start.document.source
        return source[start.index..<end.index]
    }
}

extension SourceRange: Equatable {
    public static func ==(lhs: SourceRange, rhs: SourceRange) -> Bool {
        return lhs.start == rhs.start && lhs.end == rhs.end
    }
}
