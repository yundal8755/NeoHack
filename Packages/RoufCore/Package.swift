// swift-tools-version: 6.0
import PackageDescription

// 앱의 로직 계층. Foundation만 사용해서 macOS에서 `swift test`로 바로 검증한다.
// SwiftUI View, Alamofire, Supabase 같은 외부 구현체는 앱 타깃에 둔다.
let package = Package(
    name: "RoufCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "MVICore", targets: ["MVICore"]),
        .library(name: "RoufCore", targets: ["RoufCore"]),
        .library(name: "RoufMocks", targets: ["RoufMocks"]),
    ],
    targets: [
        // Reducer, Effect, Store
        .target(name: "MVICore"),

        // Entity, Domain(Repository 프로토콜), DataModel(DTO/Mapper), Feature(Reducer), AccessibilityID
        .target(name: "RoufCore", dependencies: ["MVICore"]),

        // 테스트와 앱 목 모드(-mock-mode)가 함께 쓰는 Mock 구현체
        .target(name: "RoufMocks", dependencies: ["RoufCore"]),

        // 테스트 전용 도우미(ReducerTester 등). 앱에는 링크하지 않는다.
        .target(name: "MVITestSupport", dependencies: ["MVICore"]),

        .testTarget(name: "MVICoreTests", dependencies: ["MVICore", "MVITestSupport"]),
        .testTarget(
            name: "RoufCoreTests",
            dependencies: ["RoufCore", "RoufMocks", "MVITestSupport"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
