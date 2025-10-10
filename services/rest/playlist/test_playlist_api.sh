#!/bin/bash

echo "=========================================="
echo "Testing Service A - Playlist REST API"
echo "=========================================="
echo ""

BASE_URL="http://localhost:5001"

# Test 1: Health Check
echo "Test 1: Health Check"
echo "GET $BASE_URL/health"
curl -s "$BASE_URL/health" | python3 -m json.tool
echo ""
echo ""

# Test 2: Create Playlist
echo "Test 2: Create Playlist"
echo "POST $BASE_URL/playlists"
PLAYLIST_RESPONSE=$(curl -s -X POST "$BASE_URL/playlists" \
  -H "Content-Type: application/json" \
  -d '{"name": "Minha Playlist de Testes"}')
echo "$PLAYLIST_RESPONSE" | python3 -m json.tool
PLAYLIST_ID=$(echo "$PLAYLIST_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")
echo ""
echo "Playlist ID criado: $PLAYLIST_ID"
echo ""
echo ""

# Test 3: List Playlists
echo "Test 3: List All Playlists"
echo "GET $BASE_URL/playlists"
curl -s "$BASE_URL/playlists" | python3 -m json.tool
echo ""
echo ""

# Test 4: Get Playlist by ID
echo "Test 4: Get Playlist by ID"
echo "GET $BASE_URL/playlists/$PLAYLIST_ID"
curl -s "$BASE_URL/playlists/$PLAYLIST_ID" | python3 -m json.tool
echo ""
echo ""

# Test 5: Update Playlist
echo "Test 5: Update Playlist"
echo "PATCH $BASE_URL/playlists/$PLAYLIST_ID"
curl -s -X PATCH "$BASE_URL/playlists/$PLAYLIST_ID" \
  -H "Content-Type: application/json" \
  -d '{"name": "Playlist Atualizada"}' \
  | python3 -m json.tool
echo ""
echo ""

# Test 6: Add Video to Playlist (requires Service B running)
echo "Test 6: Add Video to Playlist (requires Service B)"
echo "POST $BASE_URL/videos"
VIDEO_RESPONSE=$(curl -s -X POST "$BASE_URL/videos" \
  -H "Content-Type: application/json" \
  -d "{\"playlist_id\": \"$PLAYLIST_ID\", \"url\": \"https://www.youtube.com/watch?v=njC24ts24Pg\"}")
echo "$VIDEO_RESPONSE" | python3 -m json.tool

if echo "$VIDEO_RESPONSE" | grep -q '"id"'; then
  VIDEO_ID=$(echo "$VIDEO_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")
  echo ""
  echo "Video ID criado: $VIDEO_ID"
  echo ""
  echo ""
  
  # Test 7: Get Video by ID
  echo "Test 7: Get Video by ID"
  echo "GET $BASE_URL/videos/$VIDEO_ID"
  curl -s "$BASE_URL/videos/$VIDEO_ID" | python3 -m json.tool
  echo ""
  echo ""
  
  # Test 8: Get Playlist with Videos
  echo "Test 8: Get Playlist with Videos"
  echo "GET $BASE_URL/playlists/$PLAYLIST_ID"
  curl -s "$BASE_URL/playlists/$PLAYLIST_ID" | python3 -m json.tool
  echo ""
  echo ""
  
  # Test 9: Delete Video
  echo "Test 9: Delete Video"
  echo "DELETE $BASE_URL/videos/$VIDEO_ID"
  curl -s -X DELETE "$BASE_URL/videos/$VIDEO_ID" -w "\nHTTP Status: %{http_code}\n"
  echo ""
  echo ""
else
  echo ""
  echo "Skipping video tests (Service B may not be running)"
  echo ""
  echo ""
fi

# Test 10: Try to create duplicate playlist (should fail)
echo "Test 10: Try to create duplicate playlist (should return 409)"
echo "POST $BASE_URL/playlists"
curl -s -X POST "$BASE_URL/playlists" \
  -H "Content-Type: application/json" \
  -d '{"name": "Playlist Atualizada"}' \
  | python3 -m json.tool
echo ""
echo ""

# Test 11: Delete Playlist
echo "Test 11: Delete Playlist"
echo "DELETE $BASE_URL/playlists/$PLAYLIST_ID"
curl -s -X DELETE "$BASE_URL/playlists/$PLAYLIST_ID" -w "\nHTTP Status: %{http_code}\n"
echo ""
echo ""

# Test 12: Try to get deleted playlist (should fail)
echo "Test 12: Try to get deleted playlist (should return 404)"
echo "GET $BASE_URL/playlists/$PLAYLIST_ID"
curl -s "$BASE_URL/playlists/$PLAYLIST_ID" | python3 -m json.tool
echo ""
echo ""

echo "=========================================="
echo "Tests completed!"
echo "=========================================="
