#!/bin/bash
set -e

echo "=== JCore RecordX Verification ==="
echo ""

cd /Users/Shared/dev/git/jcore/dart

echo "1. Running dart analyze --fatal-infos..."
dart analyze --fatal-infos
echo "✓ Analysis passed"
echo ""

echo "2. Running all tests..."
dart test
echo "✓ Tests passed"
echo ""

echo "3. Running specific remove-then-edit test..."
dart test test/record_x_test.dart -n "remove first row then edit"
echo "✓ Remove-then-edit scenario passed"
echo ""

echo "=== JCore verification complete ==="
