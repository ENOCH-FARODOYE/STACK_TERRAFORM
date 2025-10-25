#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
OBJECT_KEY=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  S3 Object Versions Listing${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

check_versioning_enabled() {
    echo -e "${YELLOW}Checking if versioning is enabled...${NC}"

    VERSIONING_STATUS=$(aws s3api get-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION" \
        --query 'Status' \
        --output text 2>&1)

    if [ "$VERSIONING_STATUS" == "Enabled" ]; then
        echo -e "${GREEN}✓ Versioning is enabled${NC}"
        return 0
    else
        echo -e "${RED}✗ Versioning is not enabled (Status: $VERSIONING_STATUS)${NC}"
        return 1
    fi
}

list_object_versions() {
    echo -e "${YELLOW}Listing versions for: $OBJECT_KEY${NC}"
    echo ""

    VERSIONS=$(aws s3api list-object-versions \
        --bucket "$BUCKET_NAME" \
        --prefix "$OBJECT_KEY" \
        --region "$AWS_REGION" 2>&1)

    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Failed to list versions${NC}"
        return 1
    fi

    # Parse and display versions
    echo -e "${GREEN}Object Versions:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"

    echo "$VERSIONS" | jq -r '.Versions[] | "\(.LastModified) | \(.VersionId) | \(.Size) bytes | Latest: \(.IsLatest)"' 2>/dev/null | \
    while IFS='|' read -r modified version_id size latest; do
        if [[ "$latest" == *"true"* ]]; then
            echo -e "${GREEN}✓ $modified |$version_id |$size | CURRENT${NC}"
        else
            echo -e "${YELLOW}  $modified |$version_id |$size${NC}"
        fi
    done

    # Check for delete markers
    DELETE_MARKERS=$(echo "$VERSIONS" | jq -r '.DeleteMarkers[]? | "\(.LastModified) | \(.VersionId) | DELETE MARKER"' 2>/dev/null)

    if [ ! -z "$DELETE_MARKERS" ]; then
        echo ""
        echo -e "${RED}Delete Markers:${NC}"
        echo -e "${BLUE}----------------------------------------${NC}"
        echo "$DELETE_MARKERS" | while IFS='|' read -r modified version_id marker; do
            echo -e "${RED}✗ $modified |$version_id |$marker${NC}"
        done
    fi

    echo -e "${BLUE}----------------------------------------${NC}"
}

count_versions() {
    VERSIONS_COUNT=$(aws s3api list-object-versions \
        --bucket "$BUCKET_NAME" \
        --prefix "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'length(Versions)' \
        --output text 2>&1)

    DELETE_MARKERS_COUNT=$(aws s3api list-object-versions \
        --bucket "$BUCKET_NAME" \
        --prefix "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'length(DeleteMarkers)' \
        --output text 2>&1)

    echo ""
    echo -e "${GREEN}Total Versions: $VERSIONS_COUNT${NC}"
    echo -e "${RED}Total Delete Markers: ${DELETE_MARKERS_COUNT:-0}${NC}"
}

main() {
    print_header

    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <object-key>${NC}"
        echo -e "${YELLOW}Example: $0 versioned-bucket-enoch-v117 documents/file.txt${NC}"
        exit 1
    fi

    BUCKET_NAME="$1"
    OBJECT_KEY="$2"

    check_versioning_enabled || exit 1
    echo ""
    list_object_versions || exit 1
    count_versions

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Version listing complete${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
