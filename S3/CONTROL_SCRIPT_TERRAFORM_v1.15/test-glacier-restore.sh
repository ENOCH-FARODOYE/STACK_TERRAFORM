#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
TEST_FILE="test-glacier-file.txt"
TEST_KEY="archive/$TEST_FILE"
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Glacier Restore Testing${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

step1_create_file() {
    echo -e "${BLUE}Step 1: Creating test file...${NC}"
    echo "This is a test file for Glacier restore - $(date)" > "$TEST_FILE"
    aws s3 cp "$TEST_FILE" "s3://$BUCKET_NAME/$TEST_KEY" \
        --storage-class GLACIER \
        --region "$AWS_REGION" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Test file uploaded to Glacier: $TEST_KEY${NC}"
        rm "$TEST_FILE"
        return 0
    else
        echo -e "${RED}✗ Failed to upload test file${NC}"
        return 1
    fi
}

step2_verify_glacier() {
    echo -e "${BLUE}Step 2: Verifying object is in Glacier...${NC}"
    STORAGE_CLASS=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$TEST_KEY" \
        --region "$AWS_REGION" \
        --query 'StorageClass' \
        --output text 2>&1)
    if [ "$STORAGE_CLASS" == "GLACIER" ]; then
        echo -e "${GREEN}✓ Object is in GLACIER storage class${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Object storage class: $STORAGE_CLASS${NC}"
        return 1
    fi
}

step3_initiate_restore() {
    echo -e "${BLUE}Step 3: Initiating restore...${NC}"
    ./restore-glacier.sh "$BUCKET_NAME" "$TEST_KEY" 3 Expedited
}

step4_check_status() {
    echo -e "${BLUE}Step 4: Checking restore status...${NC}"
    ./check-restore-status.sh "$BUCKET_NAME" "$TEST_KEY"
}

cleanup() {
    echo ""
    echo -e "${BLUE}Cleanup: Removing test file...${NC}"
    aws s3 rm "s3://$BUCKET_NAME/$TEST_KEY" --region "$AWS_REGION" > /dev/null 2>&1
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

main() {
    print_header

    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name is required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name>${NC}"
        echo -e "${YELLOW}Example: $0 glacier-storage-enoch-v115${NC}"
        exit 1
    fi

    BUCKET_NAME="$1"

    step1_create_file || exit 1
    echo ""
    step2_verify_glacier || exit 1
    echo ""
    step3_initiate_restore || exit 1
    echo ""
    echo -e "${YELLOW}⏳ Note: Restore takes 1-5 minutes for Expedited tier${NC}"
    echo -e "${YELLOW}   You can check status with:${NC}"
    echo -e "${YELLOW}   ./check-restore-status.sh $BUCKET_NAME $TEST_KEY${NC}"
    echo ""
    step4_check_status
    echo ""
    echo -e "${YELLOW}Do you want to cleanup now? (y/n)${NC}"
    read -r CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        cleanup
    else
        echo -e "${YELLOW}Skipping cleanup - you can manually delete the test file later${NC}"
    fi

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Glacier restore test completed${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
