# kuzu-swift-example

A simple CLI example using kuzu-swift.

## Build

```bash
swift build -c release
```

## Run

1. Copy the built executable to the data directory:
  ```bash
  cp ./.build/arm64-apple-macosx/release/kuzu-swift-example .
  ```

  If you are using an Intel Mac or Linux, replace `arm64-apple-macosx` with your specific architecture accordingly.

2. Run the executable:
  ```bash
  ./kuzu-swift-example
  ```
