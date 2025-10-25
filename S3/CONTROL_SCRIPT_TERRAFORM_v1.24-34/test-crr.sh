#!/bin/bash

# Story 27: Test Cross-Region Replication

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SOURCE_BUCKET=""
DEST_BUCKET=""
AWS_REGION="us-east-1"
DEST_REGION="us-west-2"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Test Cross-Region Replication${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

upload_test_file() {
    echo -e "${BLUE}Step 1: Creating and uploading test file...${NC}"
    
    TEST_FILE="crr-test-$(date +%s).txt"
    echo "CRR Test File - $(date)" > "$TEST_FILE"
    
    aws s3 cp "$TEST_FILE" "s3://$SOURCE_BUCKET/$TEST_FILE" --region "$AWS_REGION"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Test file uploaded to source bucket${NC}"
        rm "$TEST_FILE"
        return 0
    else
        echo -e "${RED}✗ Failed to upload test file${NC}"
        return 1
    fi
}

wait_for_replication() {
    echo ""
    echo -e "${BLUE}Step 2: Waiting for replication (15-30 seconds)...${NC}"
    sleep 30
}

check_replication() {
    echo ""
    echo -e "${BLUE}Step 3: Checking destination bucket...${NC}"
    
    DEST_CHECK=$(aws s3 ls "s3://$DEST_BUCKET/$TEST_FILE" --region "$DEST_REGION" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ File successfully replicated to destination!${NC}"
        echo "$DEST_CHECK"
        return 0
    else
        echo -e "${YELLOW}⚠ File not yet replicated (may need more time)${NC}"
        return 1
    fi
}

main() {
    print_header
    
    if [ $# -lt 2 ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <source-bucket> <dest-bucket>${NC}"
        exit 1
    fi
    
    SOURCE_BUCKET="$1"
    DEST_BUCKET="$2"
    
    upload_test_file || exit 1
    wait_for_replication
    check_replication
}

main "$@"
