//
// GainText parser
// Copyright Martin Waitz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//

import Engine
import GainText

import XCTest
import Nimble


class ExampleTests: XCTestCase {

    func testWritingText() throws {
        let doc = simpleDocument(
            "Headline\n" +
            "========\n" +
            "\n" +
            "Text with _embedded_ `markup`.\n" +
            "\n" +
            "Lists can be introduced by dashes or asterisks:\n" +
            " * Layout in source is important\n" +
            "   - allows to write beautiful source documents\n" +
            "   - also readable by non-techies\n" +
            " * TBD\n")
        let nodes = doc.parse()

        expect(nodes).to(haveCount(1))

        expect(nodes[0].nodeType.name) == "section"

        expect(nodes[0].children).to(haveCount(4))
        expect(nodes[0].children[0].nodeType.name) == "gaintext-title"
        expect(nodes[0].children[1].nodeType.name) == "p"
        expect(nodes[0].children[2].nodeType.name) == "p"
        expect(nodes[0].children[3].nodeType.name) == "ul"

        let items = nodes[0].children[3].children
        expect(items).to(haveCount(2))
        expect(items[0].nodeType.name) == "li"
        expect(items[0].sourceRange) == "7:2..10:1"
        expect(items[0].children).to(haveCount(2))
        expect(items[0].children[0].nodeType.name) == "p"
        expect(items[0].children[1].nodeType.name) == "ul"
        expect(items[1].nodeType.name) == "li"
        expect(items[1].sourceRange) == "10:2..10:6"
        expect(items[1].children).to(haveCount(1))
        expect(items[1].children[0].nodeType.name) == "p"
    }

    func testStructuredElements() throws {
        let doc = simpleDocument(
            "author: Martin Waitz\n" +
            "  city: Nuremberg\n" +
            "  country: Germany\n")
        doc.global.register(block: ElementType("author"))
        doc.global.register(block: ElementType("city"))
        doc.global.register(block: ElementType("country"))
        let nodes = doc.parse()

        expect(nodes).to(haveCount(1))

        expect(nodes[0].nodeType.name) == "author"
        let n = nodes[0].children
        expect(n).to(haveCount(3))
        expect(n[0].nodeType.name) == "gaintext-title"
        expect(n[0].sourceContent) == "Martin Waitz"
        expect(n[1].nodeType.name) == "city"
        expect(n[1].children[0].sourceContent) == "Nuremberg"
        expect(n[2].nodeType.name) == "country"
        expect(n[2].children[0].sourceContent) == "Germany"
    }

    func testStructuredText() throws {
        let doc = simpleDocument(
            "title: GainText example\n" +
            "author: Martin Waitz\n" +
            "\n" +
            "abstract:\n" +
            "  This is a small example which shows some *GainText* features.\n" +
            "\n" +
            "Chapter 1\n" +
            "=========\n" +
            "\n" +
            "Blah blah, see [figure:f1].\n" +
            "\n" +
            "figure: #f1\n" +
            "  image: fig1.png\n" +
            "  caption: A nice graphic explaining the text\n" +
            "\n")
        doc.global.register(block: ElementType("title"))
        doc.global.register(block: ElementType("author"))
        doc.global.register(block: ElementType("abstract"))
        doc.global.register(block: ElementType("figure"))

        let nodes = doc.parse()

        expect(nodes).to(haveCount(4))

        expect(nodes[0].nodeType.name) == "title"
        expect(nodes[1].nodeType.name) == "author"
        expect(nodes[2].nodeType.name) == "abstract"
        expect(nodes[3].nodeType.name) == "section"

    }

    static var allTests : [(String, (ExampleTests) -> () throws -> Void)] {
        return [
            ("testWritingText", testWritingText),
            ("testStructuredElements", testStructuredElements),
            ("testStructuredText", testStructuredText),
        ]
    }
}
