# kuzu-swift-example

A simple CLI example using kuzu-swift.

## Build

```bash
swift build
```

## Run

1. Copy the built executable to the data directory:
  ```bash
  cp ./.build/arm64-apple-macosx/debug/kuzu-swift-get-started ./data
  ```

  If you are using an Intel Mac or Linux, replace `arm64-apple-macosx` with your specific architecture accordingly.

2. Run the executable:
  ```bash
  cd ./data
  ./kuzu-swift-get-started
  ```
