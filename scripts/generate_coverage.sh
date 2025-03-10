#!/bin/bash

# Exit on error
set -e

# Change to project root directory
cd "$(dirname "$0")/.."

# Create coverage directory if it doesn't exist
mkdir -p coverage

# Check if xcpretty is installed
if ! command -v xcpretty &> /dev/null; then
    echo "Installing xcpretty..."
    gem install xcpretty
fi

# Clean up existing coverage files
echo "Cleaning up existing coverage files..."
rm -rf coverage/coverage.xcresult coverage/coverage.json coverage/coverage.xml

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
    -resultBundlePath ./coverage/coverage.xcresult \
    | xcpretty

# Generate coverage report
echo "Generating coverage report..."
xcrun xccov view --report --json coverage/coverage.xcresult > coverage/coverage.json

# Convert to SonarQube format using the generic converter
echo "Converting to SonarQube format..."
./scripts/xccov-to-sonarqube-generic.sh coverage/coverage.xcresult > coverage/coverage.xml

# Verify files were created
echo "Verifying coverage files..."
if [ -f "coverage/coverage.json" ]; then
    echo "✓ coverage.json created successfully"
else
    echo "✗ Failed to create coverage.json"
    exit 1
fi

if [ -f "coverage/coverage.xml" ]; then
    echo "✓ coverage.xml created successfully"
    echo "File location: $(pwd)/coverage/coverage.xml"
    # Print the first few lines of the coverage file to verify format
    echo "Coverage file contents:"
    head -n 10 coverage/coverage.xml
else
    echo "✗ Failed to create coverage.xml"
    exit 1
fi

echo "Coverage report generated successfully!" 
