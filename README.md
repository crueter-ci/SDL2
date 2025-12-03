# SDL2 CI

Scripts and CI for SDL2.

- [**Releases**](https://github.com/crueter-ci/SDL2/releases)
- Shared libraries (`BUILD_SHARED_LIBS=ON`) are supported.
- CMake target: `SDL2::SDL2`

## Building and Usage

See the [spec](https://github.com/crueter-ci/spec).

## Dependencies

All: CMake, unzip, ninja, bash, pkg-config

- UNIX (Linux, *BSD, etc): x11 libraries. See [`deps`](./deps) for more