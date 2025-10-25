#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
TEST_FILE="test-versioned-file.txt"
TEST_KEY="documents/$TEST_FILE"
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Testing Object Versioning${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

step1_upload_v1() {
    echo -e "${BLUE}Step 1: Uploading version 1...${NC}"
    echo "This is version 1 - $(date)" > "$TEST_FILE"

    aws s3 cp "$TEST_FILE" "s3://$BUCKET_NAME/$TEST_KEY" \
        --region "$AWS_REGION" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Version 1 uploaded${NC}"
        rm "$TEST_FILE"
        return 0
    else
        echo -e "${RED}✗ Failed to upload version 1${NC}"
        return 1
    fi
}

step2_upload_v2() {
    echo -e "${BLUE}Step 2: Uploading version 2 (same key)...${NC}"
    sleep 2
    echo "This is version 2 - UPDATED - $(date)" > "$TEST_FILE"

    aws s3 cp "$TEST_FILE" "s3://$BUCKET_NAME/$TEST_KEY" \
        --region "$AWS_REGION" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Version 2 uploaded${NC}"
        rm "$TEST_FILE"
        return 0
    else
        echo -e "${RED}✗ Failed to upload version 2${NC}"
        return 1
    fi
}

step3_upload_v3() {
    echo -e "${BLUE}Step 3: Uploading version 3 (same key)...${NC}"
    sleep 2
    echo "This is version 3 - FINAL VERSION - $(date)" > "$TEST_FILE"

    aws s3 cp "$TEST_FILE" "s3://$BUCKET_NAME/$TEST_KEY" \
        --region "$AWS_REGION" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Version 3 uploaded${NC}"
        rm "$TEST_FILE"
        return 0
    else
        echo -e "${RED}✗ Failed to upload version 3${NC}"
        return 1
    fi
}

step4_list_versions() {
    echo -e "${BLUE}Step 4: Listing all versions...${NC}"
    ./list-versions.sh "$BUCKET_NAME" "$TEST_KEY"
}

step5_delete_and_show_marker() {
    echo -e "${BLUE}Step 5: Deleting object (creates delete marker)...${NC}"

    aws s3 rm "s3://$BUCKET_NAME/$TEST_KEY" \
        --region "$AWS_REGION" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Object deleted (delete marker created)${NC}"
        echo ""
        echo -e "${YELLOW}Listing versions including delete marker:${NC}"
        ./list-versions.sh "$BUCKET_NAME" "$TEST_KEY"
        return 0
    else
        echo -e "${RED}✗ Failed to delete object${NC}"
        return 1
    fi
}

cleanup() {
    echo ""
    echo -e "${BLUE}Cleanup: Removing all versions...${NC}"

    # Get all version IDs
    VERSIONS=$(aws s3api list-object-versions \
        --bucket "$BUCKET_NAME" \
        --prefix "$TEST_KEY" \
        --region "$AWS_REGION" \
        --query 'Versions[].VersionId' \
        --output text)

    # Delete all versions
    for VERSION in $VERSIONS; do
        aws s3api delete-object \
            --bucket "$BUCKET_NAME" \
            --key "$TEST_KEY" \
            --version-id "$VERSION" \
            --region "$AWS_REGION" > /dev/null 2>&1
    done

    # Delete delete markers
    DELETE_MARKERS=$(aws s3api list-object-versions \
        --bucket "$BUCKET_NAME" \
        --prefix "$TEST_KEY" \
        --region "$AWS_REGION" \
        --query 'DeleteMarkers[].VersionId' \
        --output text)

    for MARKER in $DELETE_MARKERS; do
        aws s3api delete-object \
            --bucket "$BUCKET_NAME" \
            --key "$TEST_KEY" \
            --version-id "$MARKER" \
            --region "$AWS_REGION" > /dev/null 2>&1
    done

    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

main() {
    print_header

    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name is required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name>${NC}"
        echo -e "${YELLOW}Example: $0 versioned-bucket-enoch-v117${NC}"
        exit 1
    fi

    BUCKET_NAME="$1"

    step1_upload_v1 || exit 1
    echo ""
    step2_upload_v2 || exit 1
    echo ""
    step3_upload_v3 || exit 1
    echo ""
    step4_list_versions
    echo ""
    step5_delete_and_show_marker
    echo ""

    read -p "Do you want to cleanup test files? (y/n): " CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        cleanup
    fi

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Versioning test complete${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"

