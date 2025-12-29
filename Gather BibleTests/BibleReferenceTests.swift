//
//  BibleReferenceTests.swift
//  Gather BibleTests
//
//  Tests for BibleReference parsing utilities
//

import Testing
import YouVersionPlatform

@testable import Gather_Bible

struct BibleReferenceTests {

    // MARK: - parseVerseId Tests

    @Test func testParseVerseIdFullFormat() {
        let result = BibleReference.parseVerseId("GEN.1.1")

        #expect(result != nil)
        #expect(result?.book == "GEN")
        #expect(result?.chapter == 1)
        #expect(result?.verse == 1)
    }

    @Test func testParseVerseIdWithoutVerse() {
        let result = BibleReference.parseVerseId("EXO.3")

        #expect(result != nil)
        #expect(result?.book == "EXO")
        #expect(result?.chapter == 3)
        #expect(result?.verse == 1)
    }

    @Test func testParseVerseIdLargeNumbers() {
        let result = BibleReference.parseVerseId("PSA.119.176")

        #expect(result != nil)
        #expect(result?.book == "PSA")
        #expect(result?.chapter == 119)
        #expect(result?.verse == 176)
    }

    @Test func testParseVerseIdNewTestament() {
        let result = BibleReference.parseVerseId("MAT.28.19")

        #expect(result != nil)
        #expect(result?.book == "MAT")
        #expect(result?.chapter == 28)
        #expect(result?.verse == 19)
    }

    @Test func testParseVerseIdInvalidEmpty() {
        let result = BibleReference.parseVerseId("")
        #expect(result == nil)
    }

    @Test func testParseVerseIdInvalidNoChapter() {
        let result = BibleReference.parseVerseId("GEN")
        #expect(result == nil)
    }

    @Test func testParseVerseIdInvalidNonNumericChapter() {
        let result = BibleReference.parseVerseId("GEN.abc")
        #expect(result == nil)
    }

    // MARK: - validateVerseId Tests

    @Test func testValidateVerseIdValid() {
        #expect(BibleReference.validateVerseId("GEN.1.1") == true)
        #expect(BibleReference.validateVerseId("REV.22.21") == true)
        #expect(BibleReference.validateVerseId("PSA.23") == true)
    }

    @Test func testValidateVerseIdInvalid() {
        #expect(BibleReference.validateVerseId("") == false)
        #expect(BibleReference.validateVerseId("INVALID") == false)
        #expect(BibleReference.validateVerseId("GEN") == false)
    }
}
