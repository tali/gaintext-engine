//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//


public protocol StructuredStreamable: TextOutputStreamable {
    func write<Target: TextOutputStream>(to target: inout Target, indent level: Int)
}

extension StructuredStreamable {
    // indent defaults to zero
    public func write<Target: TextOutputStream>(to target: inout Target) {
        write(to: &target, indent: 0)
    }
}

public protocol HTMLStreamable: StructuredStreamable {
    var html: String { get }
}

public struct StringOutputStream: TextOutputStream {
    var content: String = ""
    public mutating func write(_ string: String) {
        content += string
    }
}

extension HTMLStreamable {
    public var html: String {
        var target = StringOutputStream()
        write(to: &target)
        return target.content
    }
}


// helper for indentation
private func _write<Target: TextOutputStream>(indentation level: Int, to s: inout Target) {
    s.write(String(repeating: " ", count: level))
}

private func _write<Target: TextOutputStream>(escaped string: String, to s: inout Target) {
    for c in string.characters {
        switch c {
        case "<": s.write("&lt;")
        case ">": s.write("&gt;")
        case "&": s.write("&amp;")
        default:  s.write(String(c))
        }
    }
}


extension NodeAttribute: TextOutputStreamable {
    public func write<Target : TextOutputStream>(to target: inout Target) {
        switch self {
        case .bool(let name):
            target.write(" \(name)")
        case .number(let name, let value):
            target.write(" \(name)=\(value)")
        case .text(let name, let value):
            // TBD: escape string
            target.write(" \(name)=\"\(value)\"")
        }
    }
}

extension Node: HTMLStreamable {
    public func write<Target: TextOutputStream>(to target: inout Target, indent level: Int) {
        _write(indentation: level, to: &target)
        target.write("<\(nodeType.name) start=\"\(range.start.right)\" end=\"\(range.end.left)\"")
        for attribute in attributes {
            attribute.write(to: &target)
        }
        target.write(">\n")
        if children.isEmpty {
            _write(indentation: level + 1, to: &target)
            target.write("<src>")
            _write(escaped: sourceContent, to: &target)
            target.write("</src>\n")
        } else {
            for child in children {
                child.write(to: &target, indent: level + 1)
            }
        }
        _write(indentation: level, to: &target)
        target.write("</\(nodeType.name)>\n")
    }
}

extension ASTNode: HTMLStreamable {
    public func write<Target : TextOutputStream>(to target: inout Target, indent level: Int) {
        switch self {
        case .element(let tag, let attributes, let children):
            _write(indentation: level, to: &target)
            target.write("<\(tag.name)")
            for attribute in attributes {
                attribute.write(to: &target)
            }
            target.write(">\n")
            for child in children {
                child.write(to: &target, indent: level + 1)
            }
            _write(indentation: level, to: &target)
            target.write("</\(tag.name)>\n")
        case .text(let text):
            _write(escaped: text, to: &target)
        case .comment(let text):
            // TBD: escape --> ?
            target.write("<!-- $\(text) -->")
        case .pi(let text):
            target.write("<!$\(text)!>")
        }
    }
}
