#!/bin/bash

# Test Cross-Account Replication

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SOURCE_BUCKET=""
DEST_BUCKET=""
DEST_PROFILE=""
AWS_REGION="us-east-1"
DEST_REGION="us-west-2"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Test Cross-Account Replication${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

upload_test_file() {
    echo -e "${BLUE}Step 1: Creating and uploading test file to source...${NC}"
    
    TEST_FILE="crossaccount-test-$(date +%s).txt"
    echo "Cross-Account Replication Test - $(date)" > "$TEST_FILE"
    echo "Source Account: 978820380225" >> "$TEST_FILE"
    echo "Destination Account: 411955586173" >> "$TEST_FILE"
    
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
    echo -e "${BLUE}Step 2: Waiting for replication (30 seconds)...${NC}"
    
    for i in {30..1}; do
        echo -ne "${YELLOW}  Time remaining: ${i}s\r${NC}"
        sleep 1
    done
    echo ""
}

check_destination() {
    echo ""
    echo -e "${BLUE}Step 3: Checking destination bucket...${NC}"
    
    if [ -n "$DEST_PROFILE" ]; then
        DEST_CHECK=$(aws s3 ls "s3://$DEST_BUCKET/$TEST_FILE" \
            --profile "$DEST_PROFILE" \
            --region "$DEST_REGION" 2>&1)
    else
        echo -e "${YELLOW}Note: Using default credentials for destination check${NC}"
        DEST_CHECK=$(aws s3 ls "s3://$DEST_BUCKET/$TEST_FILE" \
            --region "$DEST_REGION" 2>&1)
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ File successfully replicated to destination!${NC}"
        echo "$DEST_CHECK"
        return 0
    else
        echo -e "${YELLOW}⚠ File not yet replicated${NC}"
        echo -e "${YELLOW}  This can take up to 15 minutes for first replication${NC}"
        echo -e "${YELLOW}  Try checking again in a few minutes${NC}"
        return 1
    fi
}

main() {
    print_header
    
    if [ $# -lt 2 ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo ""
        echo -e "${YELLOW}Usage:${NC}"
        echo -e "  $0 <source-bucket> <dest-bucket> [dest-aws-profile]"
        echo ""
        echo -e "${YELLOW}Example:${NC}"
        echo -e "  $0 advanced-bucket-enoch-v125 replica-bucket-enoch-v125-crossaccount"
        echo -e "  $0 advanced-bucket-enoch-v125 replica-bucket-enoch-v125-crossaccount dest-account"
        exit 1
    fi
    
    SOURCE_BUCKET="$1"
    DEST_BUCKET="$2"
    DEST_PROFILE="${3:-}"
    
    upload_test_file || exit 1
    wait_for_replication
    check_destination
}

main "$@"

