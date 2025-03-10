#!/bin/bash

# Exit on error
set -e

# Change to project root directory
cd "$(dirname "$0")/../.."

# Check if xcpretty is installed
if ! command -v xcpretty &> /dev/null; then
    echo "Installing xcpretty..."
    gem install xcpretty
fi

# Clean the build folder
echo "Cleaning build folder..."
xcodebuild clean -project RoundRobinPro.xcodeproj -scheme RoundRobinPro

# Run tests with coverage enabled
echo "Running tests with coverage..."
xcodebuild test \
    -project RoundRobinPro.xcodeproj \
    -scheme RoundRobinPro \
    -destination "platform=iOS Simulator,id=7F6A69BD-4ED0-47F7-B802-2445431224AB" \
    -enableCodeCoverage YES \
    | xcpretty

# Get the path to the coverage data
COVERAGE_DATA=$(find ~/Library/Developer/Xcode/DerivedData -name "*.profdata" | head -n 1)
if [ -z "$COVERAGE_DATA" ]; then
    echo "Error: Could not find coverage data file"
    exit 1
fi
echo "Found coverage data at: $COVERAGE_DATA"

# Get the path to the derived data
DERIVED_DATA=$(find ~/Library/Developer/Xcode/DerivedData -name "RoundRobinPro-*" -type d | head -n 1)
if [ -z "$DERIVED_DATA" ]; then
    echo "Error: Could not find derived data directory"
    exit 1
fi
echo "Found derived data at: $DERIVED_DATA"

# Get the path to the app bundle
APP_BUNDLE="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/RoundRobinPro.app"
if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: Could not find app bundle at: $APP_BUNDLE"
    echo "Available files in Build/Products/Debug-iphonesimulator:"
    ls -la "$DERIVED_DATA/Build/Products/Debug-iphonesimulator/"
    exit 1
fi

# Find the test binary inside the app bundle
TEST_BINARY=$(find "$APP_BUNDLE" -type f -name "RoundRobinProTests" | head -n 1)
if [ -z "$TEST_BINARY" ]; then
    echo "Error: Could not find test binary in app bundle at: $APP_BUNDLE"
    echo "Available files in app bundle:"
    ls -la "$APP_BUNDLE"
    exit 1
fi
echo "Found test binary at: $TEST_BINARY"

# Generate coverage report
echo "Generating coverage report..."
xcrun llvm-cov export \
    -instr-profile "$COVERAGE_DATA" \
    "$TEST_BINARY" \
    > coverage.json

# Convert to SonarQube format
echo "Converting to SonarQube format..."
xcrun llvm-cov show \
    -instr-profile "$COVERAGE_DATA" \
    "$TEST_BINARY" \
    > coverage.xml

echo "Coverage report generated successfully!" 