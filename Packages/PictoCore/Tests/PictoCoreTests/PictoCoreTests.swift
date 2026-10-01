import XCTest
import CoreGraphics
@testable import PictoCore

final class GridMathTests: XCTestCase {
    func testGridSizeIsClamped() {
        let size = GridSize(columns: 0, rows: 99)
        XCTAssertEqual(size.columns, 1)
        XCTAssertEqual(size.rows, 6)
    }

    func testFirstFreeSlot() {
        XCTAssertEqual(GridMath.firstFreeSlot(occupied: [], capacity: 4), 0)
        XCTAssertEqual(GridMath.firstFreeSlot(occupied: [0, 1, 3], capacity: 4), 2)
        XCTAssertNil(GridMath.firstFreeSlot(occupied: [0, 1, 2, 3], capacity: 4))
    }

    func testResizeKeepsVisualPositions() {
        // 2×2: a at (0,0), b at (1,1) → 3×2: a stays (0,0)=0, b stays (1,1)=4.
        let result = GridMath.resize(["a": 0, "b": 3], from: GridSize(columns: 2, rows: 2), to: GridSize(columns: 3, rows: 2))
        XCTAssertEqual(result, ["a": 0, "b": 4])
    }

    func testResizeMovesOverflowIntoFreeSlots() {
        // 3×1: a=0, b=1, c=2 → 2×2: c at column 2 no longer exists, goes to first free slot (2).
        let result = GridMath.resize(["a": 0, "b": 1, "c": 2], from: GridSize(columns: 3, rows: 1), to: GridSize(columns: 2, rows: 2))
        XCTAssertEqual(result, ["a": 0, "b": 1, "c": 2])

        // 2×2: d at (1,1)=3 → 2×1: row 1 is gone, d goes to free slot 1.
        let shrunk = GridMath.resize(["a": 0, "d": 3], from: GridSize(columns: 2, rows: 2), to: GridSize(columns: 2, rows: 1))
        XCTAssertEqual(shrunk, ["a": 0, "d": 1])
    }

    func testResizeFailsWhenTooManyItems() {
        XCTAssertNil(GridMath.resize(["a": 0, "b": 1, "c": 2], from: GridSize(columns: 2, rows: 2), to: GridSize(columns: 2, rows: 1)))
    }
}

final class SpeechResolverTests: XCTestCase {
    func testRecordingWins() {
        let data = Data([1, 2, 3])
        XCTAssertEqual(SpeechResolver.resolve(label: "pomme", spokenText: "une pomme", recording: data), .recording(data))
    }

    func testSpokenTextBeforeLabel() {
        XCTAssertEqual(SpeechResolver.resolve(label: "pomme", spokenText: " une pomme ", recording: nil), .text("une pomme"))
    }

    func testFallsBackToLabel() {
        XCTAssertEqual(SpeechResolver.resolve(label: "pomme", spokenText: "  ", recording: Data()), .text("pomme"))
        XCTAssertEqual(SpeechResolver.resolve(label: " ", spokenText: nil, recording: nil), .none)
    }
}

final class LabelStyleTests: XCTestCase {
    func testFrenchUppercase() {
        XCTAssertEqual(LabelStyle.uppercase.format("gâteau"), "GÂTEAU")
        XCTAssertEqual(LabelStyle.lowercase.format("Élodie"), "élodie")
        XCTAssertEqual(LabelStyle.asTyped.format(" Lait "), "Lait")
        XCTAssertNil(LabelStyle.hidden.format("lait"))
        XCTAssertNil(LabelStyle.uppercase.format("  "))
    }
}

final class TapDebouncerTests: XCTestCase {
    func testIgnoresFastRepeats() {
        var debouncer = TapDebouncer()
        let start = Date(timeIntervalSince1970: 1000)
        XCTAssertTrue(debouncer.shouldAccept(at: start, minimumInterval: 0.5))
        XCTAssertFalse(debouncer.shouldAccept(at: start.addingTimeInterval(0.2), minimumInterval: 0.5))
        XCTAssertTrue(debouncer.shouldAccept(at: start.addingTimeInterval(0.6), minimumInterval: 0.5))
    }
}

final class CropMathTests: XCTestCase {
    func testSquareImageFullCrop() {
        let rect = CropMath.cropRect(imageSize: CGSize(width: 1000, height: 1000), side: 500, zoom: 1, offset: .zero)
        XCTAssertEqual(rect, CGRect(x: 0, y: 0, width: 1000, height: 1000))
    }

    func testLandscapeImageCentreCrop() {
        let rect = CropMath.cropRect(imageSize: CGSize(width: 2000, height: 1000), side: 500, zoom: 1, offset: .zero)
        XCTAssertEqual(rect, CGRect(x: 500, y: 0, width: 1000, height: 1000))
    }

    func testZoomAndOffset() {
        // Zoom 2 on a 1000×1000 image in a 500 square: scale is 1, the visible area is 500×500
        // image points, centred at (250, 250). Moving the image 100 points right shows 100 points further left.
        let rect = CropMath.cropRect(imageSize: CGSize(width: 1000, height: 1000), side: 500, zoom: 2, offset: CGSize(width: 100, height: 0))
        XCTAssertEqual(rect, CGRect(x: 150, y: 250, width: 500, height: 500))
    }

    func testOffsetIsClamped() {
        let clamped = CropMath.clampedOffset(CGSize(width: 900, height: -900), imageSize: CGSize(width: 2000, height: 1000), side: 500, zoom: 1)
        XCTAssertEqual(clamped, CGSize(width: 250, height: 0))
    }
}

final class ParentCodeTests: XCTestCase {
    func testValidation() {
        XCTAssertTrue(ParentCode.isValid("1234"))
        XCTAssertTrue(ParentCode.isValid("123456"))
        XCTAssertFalse(ParentCode.isValid("123"))
        XCTAssertFalse(ParentCode.isValid("12a4"))
        XCTAssertFalse(ParentCode.isValid("１２３４"))
    }
}
