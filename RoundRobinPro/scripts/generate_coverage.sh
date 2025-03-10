#!/bin/bash

# Exit on error
set -e

# Change to project root directory
cd "$(dirname "$0")/../.."

# Create coverage directory if it doesn't exist
mkdir -p RoundRobinPro/coverage

# Check if xcpretty is installed
if ! command -v xcpretty &> /dev/null; then
    echo "Installing xcpretty..."
    gem install xcpretty
fi

# Clean up existing coverage files
echo "Cleaning up existing coverage files..."
rm -rf RoundRobinPro/coverage/coverage.xcresult RoundRobinPro/coverage/coverage.json RoundRobinPro/coverage/coverage.xml

# Clean the build folder
echo "Cleaning build folder..."
xcodebuild clean -project RoundRobinPro.xcodeproj -scheme RoundRobinPro

# Run tests with coverage enabled and generate result bundle
echo "Running tests with coverage..."
xcodebuild test \
    -project RoundRobinPro.xcodeproj \
    -scheme RoundRobinPro \
    -destination "platform=iOS Simulator,id=7F6A69BD-4ED0-47F7-B802-2445431224AB" \
    -enableCodeCoverage YES \
    -resultBundlePath ./RoundRobinPro/coverage/coverage.xcresult \
    | xcpretty

# Generate coverage report
echo "Generating coverage report..."
xcrun xccov view --report --json RoundRobinPro/coverage/coverage.xcresult > RoundRobinPro/coverage/coverage.json

# Convert to SonarQube format
echo "Converting to SonarQube format..."
xcrun xccov view --report RoundRobinPro/coverage/coverage.xcresult > RoundRobinPro/coverage/coverage.xml

# Verify files were created
echo "Verifying coverage files..."
if [ -f "RoundRobinPro/coverage/coverage.json" ]; then
    echo "✓ coverage.json created successfully"
else
    echo "✗ Failed to create coverage.json"
    exit 1
fi

if [ -f "RoundRobinPro/coverage/coverage.xml" ]; then
    echo "✓ coverage.xml created successfully"
    echo "File location: $(pwd)/RoundRobinPro/coverage/coverage.xml"
else
    echo "✗ Failed to create coverage.xml"
    exit 1
fi

echo "Coverage report generated successfully!" 
