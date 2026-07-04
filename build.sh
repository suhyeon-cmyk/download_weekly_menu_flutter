#!/bin/bash

# Exit on error
set -e

echo "=== Installing Flutter SDK ==="
# Clone Flutter SDK stable branch with depth 1 to save time
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# Add Flutter to the path
export PATH="$PATH:$(pwd)/flutter/bin"

# Download the web build artifacts
flutter precache --web

# Build the web version of our app
echo "=== Building Flutter Web ==="
flutter build web --release

echo "=== Build Complete ==="
