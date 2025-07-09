# kuzu-swift

Official Swift language binding for [Kuzu](https://github.com/kuzudb/kuzu). Kuzu an embeddable property graph database management system built for query speed and scalability. For more information, please visit the [Kuzu GitHub repository](https://github.com/kuzudb/kuzu) or the [Kuzu website](https://kuzudb.com).

## Get started

To add kuzu-swift to your Swift project, you can use the Swift Package Manager:

Add `.package(url: "https://github.com/kuzudb/kuzu-swift/", branch: "main"),` to your Swift.package dependencies.

You can change the branch to a tag to use a specific version, e.g., `.package(url: "https://github.com/kuzudb/kuzu-swift/", branch: "v0.11.0"),` to use version 0.11.0.

Alternatively, you can add the package through Xcode:
1. Open your Xcode project.
2. Go to `File` > `Add Packages Dependencies...`.
3. Enter the URL of the kuzu-swift repository: `https://github.com/kuzudb/kuzu-swift`.
4. Select the version you want to use (e.g., `main` branch or a specific tag).

## Docs

The API documentation for kuzu-swift is [available here](https://api-docs.kuzudb.com/swift/documentation/kuzu/).

## Examples

A simple CLI example is provided in the [Example](Example) directory.

A demo iOS application is [provided here](https://github.com/kuzudb/kuzu-swift-demo).

## System requirements

kuzu-swift requires Swift 5.9 or later. It supports the following platforms:
- macOS v11 or later
- iOS v14 or later
- Linux platforms (see the [official documentation](https://www.swift.org/platform-support/) for the supported distros)

Windows platform is not supported and there is no future plan to support it. 

The CI pipeline tests the package on macOS v14 and Ubuntu 24.04.

## Build

```bash
swift build
```

## Tests

To run the tests, you can use the following command:

```bash
swift test
```

## Contributing
We welcome contributions to kuzu-swift. By contributing to kuzu-swift, you agree that your contributions will be licensed under the [MIT License](LICENSE). Please read the [contributing guide](CONTRIBUTING.md) for more information.
