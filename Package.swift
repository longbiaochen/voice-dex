// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "voice-dex",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "VoiceDex", targets: ["VoiceDex"]),
    ],
    targets: [
        .executableTarget(
            name: "VoiceDex"
        ),
        .testTarget(
            name: "VoiceDexTests",
            dependencies: ["VoiceDex"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
