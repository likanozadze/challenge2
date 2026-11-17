//
//  SVGPath.swift
//  Challenge2
//

import SwiftUI

/// Minimal SVG path parser so the illustrations exported from the design file
/// can be drawn (and animated) as SwiftUI paths.
/// Supports the absolute commands used by our assets: `M`, `L`, `C` and `Z`.
nonisolated enum SVGPath {
    private enum Token {
        case command(Character)
        case number(CGFloat)
    }

    /// Parses the `d` attribute of an SVG `<path>`.
    static func parse(_ data: String) -> Path {
        let tokens = tokenize(data)
        var path = Path()
        var index = 0
        var command: Character = "M"

        func nextNumber() -> CGFloat? {
            guard index < tokens.count, case .number(let value) = tokens[index] else { return nil }
            index += 1
            return value
        }

        func nextPoint() -> CGPoint? {
            guard let x = nextNumber(), let y = nextNumber() else { return nil }
            return CGPoint(x: x, y: y)
        }

        while index < tokens.count {
            if case .command(let character) = tokens[index] {
                command = character
                index += 1
            }

            switch command {
            case "M":
                guard let point = nextPoint() else { return path }
                path.move(to: point)
                // Extra coordinate pairs after a move are implicit line-tos.
                command = "L"
            case "L":
                guard let point = nextPoint() else { return path }
                path.addLine(to: point)
            case "C":
                guard let control1 = nextPoint(),
                      let control2 = nextPoint(),
                      let end = nextPoint() else { return path }
                path.addCurve(to: end, control1: control1, control2: control2)
            case "Z":
                path.closeSubpath()
            default:
                // Unsupported command: skip its token so parsing can't loop forever.
                index += 1
            }
        }
        return path
    }

    /// Parses the `points` attribute of an SVG `<polygon>`.
    static func polygon(_ points: String) -> Path {
        let values = tokenize(points).compactMap { token -> CGFloat? in
            if case .number(let value) = token { return value }
            return nil
        }
        var path = Path()
        for pairIndex in stride(from: 0, to: values.count - 1, by: 2) {
            let point = CGPoint(x: values[pairIndex], y: values[pairIndex + 1])
            if pairIndex == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    private static func tokenize(_ string: String) -> [Token] {
        var tokens: [Token] = []
        var number = ""

        func flush() {
            if let value = Double(number) {
                tokens.append(.number(CGFloat(value)))
            }
            number = ""
        }

        for character in string {
            if character.isLetter {
                flush()
                tokens.append(.command(character))
            } else if character == "-" {
                // A minus sign always starts a new number ("1.5-2" is two values).
                flush()
                number = "-"
            } else if character.isNumber {
                number.append(character)
            } else if character == "." {
                // A second dot also starts a new number ("0.5.5" is two values).
                if number.contains(".") { flush() }
                number.append(character)
            } else {
                flush()
            }
        }
        flush()
        return tokens
    }
}

extension Path {
    /// Returns a transform that scales `viewBox` to fit inside `size`, centered.
    static func fitting(_ viewBox: CGRect, in size: CGSize) -> CGAffineTransform {
        let scale = min(size.width / viewBox.width, size.height / viewBox.height)
        let offsetX = (size.width - viewBox.width * scale) / 2 - viewBox.minX * scale
        let offsetY = (size.height - viewBox.height * scale) / 2 - viewBox.minY * scale
        return CGAffineTransform(translationX: offsetX, y: offsetY).scaledBy(x: scale, y: scale)
    }

    /// Scales and rotates the path around `anchor`.
    func transformed(around anchor: CGPoint, scale: CGFloat = 1, rotation: Angle = .zero) -> Path {
        let transform = CGAffineTransform(translationX: anchor.x, y: anchor.y)
            .rotated(by: rotation.radians)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -anchor.x, y: -anchor.y)
        return applying(transform)
    }
}
