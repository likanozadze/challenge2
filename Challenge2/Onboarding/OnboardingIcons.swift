//
//  OnboardingIcons.swift
//  Challenge2
//
//  Animated versions of the mood illustrations (paths taken from the
//  motivated and energized SVG assets). Each icon is a pure function of
//  the time elapsed since `start`, so resetting `start` replays the animation.
//

import SwiftUI

// MARK: - Easing helpers

nonisolated enum Easing {
    static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    static func easeInOut(_ value: Double) -> Double {
        let x = clamp(value)
        return x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2
    }

    /// Ease-out with a small overshoot, used for "pop" effects.
    static func easeOutBack(_ value: Double) -> Double {
        let x = clamp(value)
        let c1 = 1.70158
        let c3 = c1 + 1
        return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
    }
}

// MARK: - Spiral (motivated)

/// The orange spiral draws itself from the bottom dot up to the arrow,
/// holds, fades out and starts again.
struct SpiralIcon: View {
    var start: Date

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let color = Color(red: 1, green: 0x92 / 255, blue: 0x30 / 255)
    private static let viewBox = CGRect(x: -1, y: -1, width: 35, height: 45)

    // Timeline (seconds) of one loop.
    private static let drawDuration = 2.4
    private static let fadeOutStart = 3.8
    private static let loopDuration = 4.4

    private static let line = SVGPath.parse("M9.28525481,41.7711348 C8.86485502,42.4160776 8.41093553,42.784989 7.92349634,42.877869 C6.01655,43.2412316 3.6177826,42.7126972 2.92698948,42.3492851 C2.11918113,41.9243136 0,40.9821534 0,38.7710662 C0,37.7719665 0.282409598,36.3012919 3.44226937,34.6513296 C4.89504149,33.8927456 6.63245266,33.1998576 9.49475474,33.348246 C12.3570568,33.4966345 14.2274493,33.984623 14.1908776,35.1627033 C14.0905912,38.393226 3.44226937,37.0110431 1.24812728,33.4450858 C-0.189228863,31.10907 2.41360427,28.4090816 4.89303712,27.347511 C6.82555502,26.5201023 9.2295004,25.6735107 12.4808543,25.956201 C15.7322081,26.2388914 18.7803698,27.0948261 18.934564,28.5921859 C19.0887582,30.0895457 16.0965071,31.0557845 12.6908809,31.0557845 C9.28525481,31.0557845 0.251416778,28.949377 1.80280981,24.0365744 C2.0239273,23.3363608 2.8451787,21.3115814 7.1412215,19.7720716 C8.95454277,19.1222583 11.2209989,18.5038697 15.2574082,18.6117012 C19.2938174,18.7195326 23.2186809,19.0946912 23.5764666,21.9038113 C23.9342522,24.7129313 18.7692291,24.819401 14.2994214,24.9600769 C9.82961361,25.1007527 7.31134541,23.8332562 5.3307682,22.4780482 C3.35019098,21.1228403 2.14362614,19.4852576 2.53781895,17.5472964 C2.93201176,15.6093353 5.49243788,13.8742826 7.92349634,12.7264494 C10.3545548,11.5786161 11.9475266,10.9888912 16.943379,10.8289188 C21.9392314,10.6689464 28.6013396,12.0981777 28.4203332,15.3013128 C28.2996622,17.4367362 24.3579883,18.4447646 16.5953115,18.3253979 C11.3452065,18.1279597 7.95037182,17.4039806 6.41080763,16.1534604 C4.10146135,14.2776803 -0.818936024,6.3407668 16.943379,3.46587022 C22.9470772,2.49414938 29.1973336,4.41918448 31.8084985,5.69458566 C34.3475296,6.93475367 33.503964,10.2760432 30.2018215,11.6616997 C26.8996791,13.0473561 26.1292574,13.2890233 24.7436211,12.7264494 C23.3579848,12.1638754 23.2877045,10.470796 23.1951361,8.81695697 C23.1334238,7.71439761 23.4123689,6.00893673 24.0319713,3.70057433")

    private static let arrowHead = SVGPath.parse("M23.7803361,3.12117677 L24.8793507,1.45559335 C22.7100618,2.50293628 21.4894194,2.78856845 21.2174233,2.31248987 C20.8094292,1.598372 26.130004,-0.113208361 26.5368486,0.00591473198 C26.9436931,0.125037825 28.4924768,5.38282561 27.7203647,5.47762906 C27.2056232,5.54083135 26.6436049,4.28863853 26.0343097,1.72105059 L24.7878949,3.16592207 L23.7803361,3.12117677 Z")

    private static let startDot = SVGPath.parse("M9.51655115,42.1618874 C9.93714386,42.1398451 10.2602328,41.7810185 10.2381905,41.3604258 C10.2161481,40.9398331 9.85732152,40.6167441 9.43672882,40.6387865 C9.01613611,40.6608288 8.69304719,41.0196554 8.71508952,41.4402481 C8.73713185,41.8608408 9.09595844,42.1839297 9.51655115,42.1618874 Z")

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            Canvas { canvas, size in
                // With Reduce Motion, show the finished drawing.
                let time = reduceMotion
                    ? Self.drawDuration + 1
                    : context.date.timeIntervalSince(start).truncatingRemainder(dividingBy: Self.loopDuration)

                let progress = Easing.easeInOut(time / Self.drawDuration)
                let headOpacity = Easing.clamp((time - (Self.drawDuration - 0.1)) / 0.3)
                canvas.opacity = 1 - Easing.clamp((time - Self.fadeOutStart) / 0.4)

                let transform = Path.fitting(Self.viewBox, in: size)
                let shading = GraphicsContext.Shading.color(Self.color)

                if progress > 0 {
                    canvas.fill(Self.startDot.applying(transform), with: shading)
                    canvas.stroke(
                        Self.line.trimmedPath(from: 0, to: progress).applying(transform),
                        with: shading,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )
                }

                var head = canvas
                head.opacity *= headOpacity
                let headPath = Self.arrowHead.applying(transform)
                head.fill(headPath, with: shading)
                head.stroke(headPath, with: shading, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Burst (energized)

/// The yellow burst pops in, then keeps pulsing while the outer sparks
/// twinkle and push outwards in a ripple. `intensity` (0...1) controls how
/// big and spread out it is, so it can follow the intensity slider.
/// Driven by its parent's timeline so both stay in sync.
struct BurstIcon: View {
    var time: TimeInterval
    var intensity: Double

    static let color = Color(red: 1, green: 0xD6 / 255, blue: 0)
    private static let viewBox = CGRect(x: 0, y: 0, width: 53, height: 52)
    private static let pulseDuration = 1.4

    private static let rays = SVGPath.polygon("21.9923067 31.6188231 13.5365295 39.5803909 21.5901792 28.8811835 13.1368442 33.3544712 21.2830672 27.26807 11.0211838 29.5326331 19.7253443 26.2040355 5.89334431 25.1741246 20.730886 24.435815 10.0719286 20.5309802 19.5768895 22.3015418 13.1678656 17.0123909 20.4858169 20.5085042 14.5923888 12.1094566 22.7751971 20.3627035 18.1685173 8.3139868 24.3727999 20.3627035 23.1288412 6.13007934 25.868032 17.8220498 27.9247517 10.8794576 27.6393547 19.1466641 31.9793003 11.8069979 30.1582934 18.4983166 37.0455503 12.1094566 29.7364022 21.8207099 38.8691061 16.7404952 32.7765006 22.019247 42.0954063 20.5085042 33.2635368 24.1712713 44.4870839 25.1741246 32.5624529 26.1357884 43.6401994 30.3919263 31.6938533 27.8357618 40.119269 34.3347478 30.1582934 28.848611 37.1132941 38.1534837 30.1582934 31.6188231 33.9987443 42.9804156 27.4128983 30.3919263 27.9247517 39.1740882 25.868032 32.0836845 23.256029 43.3495704 24.2316525 31.1110915 17.6659705 43.1324205")

    private static let raysCenter = CGPoint(x: rays.boundingRect.midX, y: rays.boundingRect.midY)

    /// Small spark ovals around the burst, in clockwise order from the top.
    private static let sparks: [Path] = [
        "M33.0966196,6.9457687 C33.3365403,7.03786561 33.9789901,5.94556023 34.5315716,4.50603636 C35.084153,3.06651249 35.3376147,1.82488853 35.097694,1.73279162 C34.8577734,1.64069472 34.2153235,2.73300009 33.6627421,4.17252396 C33.1101606,5.61204783 32.856699,6.85367179 33.0966196,6.9457687 Z",
        "M39.8783194,12.2075392 C40.0600386,12.3892584 41.0912264,11.6526957 42.1815418,10.5623804 C43.2718572,9.47206498 44.0084199,8.4408772 43.8267006,8.25915797 C43.6449814,8.07743874 42.6137936,8.81400144 41.5234782,9.90431682 C40.4331629,10.9946322 39.6966002,12.02582 39.8783194,12.2075392 Z",
        "M45.9934482,18.7582612 C46.0642842,19.0052956 47.323274,18.8610131 48.8054807,18.4359972 C50.2876874,18.0109813 51.4318294,17.4661768 51.3609934,17.2191424 C51.2901575,16.9721079 50.0311676,17.1163904 48.5489609,17.5414063 C47.0667542,17.9664223 45.9226122,18.5112267 45.9934482,18.7582612 Z",
        "M47.4571749,28.5059459 C47.4258557,28.7610201 48.6411377,29.1201339 50.1715831,29.308049 C51.7020285,29.4959641 52.9680888,29.4415208 52.999408,29.1864466 C53.0307272,28.9313723 51.8154453,28.5722586 50.2849998,28.3843435 C48.7545544,28.1964284 47.4884941,28.2508717 47.4571749,28.5059459 Z",
        "M44.1125733,37.6453137 C43.9802137,37.8655969 44.9443643,38.6879634 46.2660638,39.4821206 C47.5877633,40.2762777 48.7665111,40.7414945 48.8988706,40.5212112 C49.0312301,40.300928 48.0670796,39.4785615 46.7453801,38.6844043 C45.4236805,37.8902472 44.2449328,37.4250304 44.1125733,37.6453137 Z",
        "M36.3817776,43.2046105 C36.1614943,43.33697 36.6267111,44.5157178 37.4208682,45.8374173 C38.2150254,47.1591168 39.0373919,48.1232673 39.2576751,47.9909078 C39.4779584,47.8585483 39.0127416,46.6798005 38.2185845,45.358101 C37.4244273,44.0364015 36.6020608,43.0722509 36.3817776,43.2046105 Z",
        "M27.3879051,45.6045601 C27.1315414,45.6224868 27.0109122,46.8839627 27.1184724,48.4221454 C27.2260327,49.9603281 27.5210514,51.1927391 27.7774151,51.1748124 C28.0337789,51.1568857 28.154408,49.8954098 28.0468478,48.3572271 C27.9392876,46.8190444 27.6442689,45.5866334 27.3879051,45.6045601 Z",
        "M18.3004893,44.5252764 C18.0589978,44.4373807 17.4357092,45.540732 16.908335,46.9896805 C16.3809609,48.438629 16.1492072,49.6844874 16.3906986,49.7723831 C16.63219,49.8602788 17.2554787,48.7569275 17.7828528,47.307979 C18.3102269,45.8590305 18.5419807,44.6131721 18.3004893,44.5252764 Z",
        "M10.3577285,39.6255399 C10.1792084,39.4406769 9.13532291,40.1591307 8.02614497,41.2302514 C6.91696703,42.3013721 6.1625198,43.319548 6.34103991,43.504411 C6.51956003,43.689274 7.56344555,42.9708202 8.67262349,41.8996995 C9.78180143,40.8285788 10.5362487,39.8104029 10.3577285,39.6255399 Z",
        "M7.63382337,30.9155195 C7.56730951,30.6672864 6.30599334,30.7895745 4.81659484,31.1886576 C3.32719635,31.5877408 2.17372044,32.1124942 2.24023429,32.3607273 C2.30674815,32.6089604 3.56806432,32.4866723 5.05746282,32.0875891 C6.54686131,31.688506 7.70033722,31.1637526 7.63382337,30.9155195 Z",
        "M5.53028624,22.0998325 C5.56605231,21.8453437 4.35722287,21.465075 2.83029013,21.2504786 C1.30335738,21.0358822 0.0365396976,21.0682214 0.000773630512,21.3227101 C-0.0349924366,21.5771989 1.173837,21.9574676 2.70076974,22.172064 C4.22770249,22.3866604 5.49452017,22.3543213 5.53028624,22.0998325 Z",
        "M9.0570301,13.735687 C9.20808492,13.5277778 8.31927721,12.6245095 7.07182253,11.7181806 C5.82436785,10.8118517 4.6906519,10.2456706 4.53959708,10.4535797 C4.38854227,10.6614889 5.27734998,11.5647572 6.52480466,12.4710861 C7.77225934,13.377415 8.90597529,13.9435961 9.0570301,13.735687 Z",
        "M16.2174341,8.64243943 C16.4422024,8.51784831 16.0184068,7.32358279 15.27086,5.97497274 C14.5233132,4.62636269 13.7350961,3.6340993 13.5103278,3.75869042 C13.2855594,3.88328155 13.7093551,5.07754707 14.4569018,6.42615712 C15.2044486,7.77476717 15.9926657,8.76703056 16.2174341,8.64243943 Z",
        "M24.3164229,5.57631043 C24.5730605,5.56286063 24.7156871,4.30368211 24.6349882,2.76385649 C24.5542894,1.22403088 24.2808242,-0.0133411919 24.0241866,0.0001086149 C23.767549,0.0135584217 23.6249224,1.27273694 23.7056213,2.81256255 C23.7863201,4.35238817 24.0597853,5.58976024 24.3164229,5.57631043 Z",
    ].map(SVGPath.parse)

    var body: some View {
        Canvas { canvas, size in
            let wave = 2 * .pi * time / Self.pulseDuration

            // Rays: pop in, grow with intensity, then breathe and sway gently.
            let pop = Easing.easeOutBack(time / 0.6)
            let rayScale = pop * (0.45 + 0.55 * intensity) * (1 + 0.06 * sin(wave))
            let raySway = Angle.degrees(5 * sin(2 * .pi * time / 4))

            // Inset so sparks pushed outwards still fit inside the canvas.
            let transform = Path.fitting(Self.viewBox.insetBy(dx: -2, dy: -2), in: size)
            let shading = GraphicsContext.Shading.color(Self.color)

            let rays = Self.rays.transformed(around: Self.raysCenter, scale: rayScale, rotation: raySway)
            canvas.stroke(rays.applying(transform), with: shading, style: StrokeStyle(lineWidth: 1, lineJoin: .round))

            // Sparks fly out from near the centre, then ripple around the ring.
            // At low intensity they huddle closer and fade.
            let flyOut = Easing.easeOutBack((time - 0.2) / 0.6)
            let spread = 0.55 + 0.45 * intensity
            for (index, spark) in Self.sparks.enumerated() {
                let ripple = 0.5 + 0.5 * sin(wave - Double(index) * 0.45)
                let mid = CGPoint(x: spark.boundingRect.midX, y: spark.boundingRect.midY)
                let dx = mid.x - Self.raysCenter.x
                let dy = mid.y - Self.raysCenter.y
                let distance = max(hypot(dx, dy), 0.001)

                // Radial position: fly from 50% radius to the settled ring, ripple by ~1.5 units.
                let radial = (0.5 + 0.5 * flyOut) * spread * distance + 1.5 * ripple - 0.75
                let shift = CGAffineTransform(
                    translationX: dx / distance * radial - dx,
                    y: dy / distance * radial - dy
                )

                var sparkContext = canvas
                sparkContext.opacity = Easing.clamp((time - 0.2) / 0.3)
                    * (0.45 + 0.55 * ripple)
                    * (0.25 + 0.75 * intensity)
                sparkContext.fill(spark.applying(shift).applying(transform), with: shading)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    TimelineView(.animation) { context in
        let time = context.date.timeIntervalSinceReferenceDate
        HStack(spacing: 24) {
            SpiralIcon(start: .now).frame(width: 150, height: 180)
            BurstIcon(time: time, intensity: 0.5 + 0.5 * sin(time)).frame(width: 120, height: 120)
        }
    }
    .padding()
    .background(.black)
}
