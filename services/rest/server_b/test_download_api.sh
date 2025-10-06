#!/bin/bash

echo "=========================================="
echo "Testing Service B - Download REST API"
echo "=========================================="
echo ""

BASE_URL="http://localhost:5002"

# Test 1: Health Check
echo "Test 1: Health Check"
echo "GET $BASE_URL/health"
curl -s "$BASE_URL/health" | python3 -m json.tool
echo ""
echo ""

# Test 2: Get Video Metadata
echo "Test 2: Get Video Metadata"
echo "POST $BASE_URL/metadata"
curl -s -X POST "$BASE_URL/metadata" \
  -H "Content-Type: application/json" \
  -d '{"video_url": "https://www.youtube.com/watch?v=njC24ts24Pg"}' \
  | python3 -m json.tool
echo ""
echo ""

# Test 3: Get Video Metadata - Invalid URL
echo "Test 3: Get Video Metadata - Invalid URL (should return 404)"
echo "POST $BASE_URL/metadata"
curl -s -X POST "$BASE_URL/metadata" \
  -H "Content-Type: application/json" \
  -d '{"video_url": "https://www.youtube.com/watch?v=INVALID"}' \
  | python3 -m json.tool
echo ""
echo ""

# Test 4: Missing video_url
echo "Test 4: Missing video_url (should return 400)"
echo "POST $BASE_URL/metadata"
curl -s -X POST "$BASE_URL/metadata" \
  -H "Content-Type: application/json" \
  -d '{}' \
  | python3 -m json.tool
echo ""
echo ""

# Test 5: Download Video (SSE stream - only show first few events)
echo "Test 5: Download Video with Progress (SSE stream)"
echo "POST $BASE_URL/download"
echo "Note: This will show progress events. Press Ctrl+C to stop."
echo ""
curl -N -X POST "$BASE_URL/download" \
  -H "Content-Type: application/json" \
  -d '{"video_url": "https://www.youtube.com/watch?v=njC24ts24Pg"}'
echo ""
echo ""

echo "=========================================="
echo "Tests completed!"
echo "=========================================="
