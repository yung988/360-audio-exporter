import Testing
@testable import Orbit360

struct TimecodeParserTests {
    @Test func parsesFullTimecode() {
        #expect(TimecodeParser.parse(timecode: "01:02:03.50") == 3723.5)
    }

    @Test func formatsShortDuration() {
        #expect(TimecodeParser.format(seconds: 65) == "01:05")
    }

    @Test func formatsEta() {
        #expect(TimecodeParser.formatDuration(seconds: 125) == "2 min 5 s")
    }
}
