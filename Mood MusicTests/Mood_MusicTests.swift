//
//  Mood_MusicTests.swift
//  Mood MusicTests
//
//  Created by Priyanshu Rastogi on 2025-04-23.
//
import Foundation
import Testing
@testable import Mood_Music

struct Mood_MusicTests {

    /// Tests that a song entry is properly added to history,
    /// and that duplicates are correctly identified by the SongHistoryManager.
    @Test
    func testAddAndCheckDuplicate() async throws {
        let testEntry = SongSuggestionHistoryEntry(title: "Test Song", artist: "Test Artist", date: Date(), emoji: "Happy")

        // Clear history first
        SongHistoryManager.saveHistory([])

        // Add entry
        SongHistoryManager.addToHistory(testEntry)

        // Assert it's now a duplicate
        #expect(SongHistoryManager.isDuplicate(testEntry) == true)

        // Add another unique entry
        let anotherEntry = SongSuggestionHistoryEntry(title: "New Song", artist: "New Artist", date: Date(), emoji: "Sad")
        #expect(SongHistoryManager.isDuplicate(anotherEntry) == false)
    }
    
    /// Tests decoding of a valid SongSuggestion JSON object
    /// to ensure the JSON structure matches the expected model.
    @Test
    func testSongSuggestionDecoding() async throws {
        let json = """
        {
            "title": "Cool Track",
            "artist": "Awesome Artist"
        }
        """.data(using: .utf8)!

        let suggestion = try JSONDecoder().decode(SongSuggestion.self, from: json)

        #expect(suggestion.title == "Cool Track")
        #expect(suggestion.artist == "Awesome Artist")
    }
    
    /// Tests that decoding an invalid OpenAI response (missing `choices`) correctly throws an error.
    /// This ensures error handling logic works when OpenAI response is malformed.
    @Test
    func testInvalidOpenAIResponse() async throws {
        let invalidJSON = """
        {
            "message": "Missing choices array"
        }
        """.data(using: .utf8)!

        do {
            _ = try JSONDecoder().decode(OpenAIResponse.self, from: invalidJSON)
            #expect(false, "Should not succeed decoding invalid response")
        } catch {
            #expect(true, "Caught expected decoding error")
        }
    }

}
