// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Mina",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Mina",
            targets: ["Mina"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.10.0"
        )
    ],
    targets: [
        .target(
            name: "Mina",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Mina",
            exclude: ["Resources"],
            sources: [
                "App",
                "DesignSystem",
                "Features",
                "MinaApp.swift",
                "Models",
                "Services"
            ]
        )
    ]
)
