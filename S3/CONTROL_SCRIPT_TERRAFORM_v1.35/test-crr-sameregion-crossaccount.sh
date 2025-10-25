#!/bin/bash

# Test Same-Region Cross-Account Replication

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SOURCE_BUCKET=""
DEST_BUCKET=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Test Same-Region Cross-Account CRR${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

upload_test_file() {
    echo -e "${BLUE}Step 1: Creating and uploading test file to source...${NC}"
    
    TEST_FILE="sameregion-crossaccount-test-$(date +%s).txt"
    echo "Same-Region Cross-Account Replication Test - $(date)" > "$TEST_FILE"
    echo "Source Account: 978820380225" >> "$TEST_FILE"
    echo "Destination Account: 411955586173" >> "$TEST_FILE"
    echo "Both buckets in: us-east-1" >> "$TEST_FILE"
    echo "Benefits: Lower cost, faster replication, account isolation" >> "$TEST_FILE"
    
    aws s3 cp "$TEST_FILE" "s3://$SOURCE_BUCKET/$TEST_FILE" --region "$AWS_REGION"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Test file uploaded to source bucket${NC}"
        echo -e "${BLUE}File: $TEST_FILE${NC}"
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
    echo -e "${YELLOW}Note: Same-region replication is typically faster than cross-region${NC}"
    
    for i in {30..1}; do
        echo -ne "${YELLOW}  Time remaining: ${i}s\r${NC}"
        sleep 1
    done
    echo ""
}

check_destination() {
    echo ""
    echo -e "${BLUE}Step 3: Verifying replication...${NC}"
    echo ""
    echo -e "${YELLOW}To verify in destination account (411955586173):${NC}"
    echo ""
    echo -e "${YELLOW}Option 1 - AWS Console:${NC}"
    echo -e "  1. Login to AWS Console (account 411955586173)"
    echo -e "  2. Go to S3 → $DEST_BUCKET"
    echo -e "  3. Look for file: $TEST_FILE"
    echo -e "  4. Check object ownership (should be account 411955586173)"
    echo ""
    echo -e "${YELLOW}Option 2 - AWS CLI (with destination credentials):${NC}"
    echo -e "  aws s3 ls s3://$DEST_BUCKET/ \\"
    echo -e "    --profile destination-account \\"
    echo -e "    --region $AWS_REGION"
    echo ""
    echo -e "${GREEN}Expected ReplicationStatus values:${NC}"
    echo -e "  - PENDING: Replication queued"
    echo -e "  - COMPLETED: Successfully replicated"
    echo -e "  - FAILED: Replication failed"
}

main() {
    print_header
    
    if [ $# -lt 2 ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo ""
        echo -e "${YELLOW}Usage:${NC}"
        echo -e "  $0 <source-bucket> <dest-bucket>"
        echo ""
        echo -e "${YELLOW}Example:${NC}"
        echo -e "  $0 advanced-bucket-enoch-v125 replica-bucket-enoch-v125-sameregion"
        exit 1
    fi
    
    SOURCE_BUCKET="$1"
    DEST_BUCKET="$2"
    
    upload_test_file || exit 1
    wait_for_replication
    check_destination
    
    echo ""
    echo -e "${GREEN}Test initiated!${NC}"
    echo -e "${YELLOW}Check destination bucket to confirm replication.${NC}"
}

main "$@"
