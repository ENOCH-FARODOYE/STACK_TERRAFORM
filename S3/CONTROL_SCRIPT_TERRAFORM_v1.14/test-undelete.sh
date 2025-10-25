#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
TEST_FILE="test-undelete-file.txt"
TEST_KEY="test/$TEST_FILE"
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  S3 Undelete Testing${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

step1_create_file() {
    echo -e "${BLUE}Step 1: Creating test file...${NC}"
    echo "This is a test file for undelete functionality - $(date)" > "$TEST_FILE"
    aws s3 cp "$TEST_FILE" "s3://$BUCKET_NAME/$TEST_KEY" --region "$AWS_REGION" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Test file uploaded: $TEST_KEY${NC}"
        rm "$TEST_FILE"
        return 0
    else
        echo -e "${RED}✗ Failed to upload test file${NC}"
        return 1
    fi
}

step2_verify_exists() {
    echo -e "${BLUE}Step 2: Verifying file exists...${NC}"
    aws s3api head-object --bucket "$BUCKET_NAME" --key "$TEST_KEY" --region "$AWS_REGION" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ File exists and is accessible${NC}"
        return 0
    else
        echo -e "${RED}✗ File not found${NC}"
        return 1
    fi
}

step3_delete_file() {
    echo -e "${BLUE}Step 3: Deleting the file...${NC}"
    aws s3 rm "s3://$BUCKET_NAME/$TEST_KEY" --region "$AWS_REGION" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ File deleted${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to delete file${NC}"
        return 1
    fi
}

step4_verify_deleted() {
    echo -e "${BLUE}Step 4: Verifying file is deleted...${NC}"
    aws s3api head-object --bucket "$BUCKET_NAME" --key "$TEST_KEY" --region "$AWS_REGION" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${GREEN}✓ File is deleted (not accessible)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ File still accessible${NC}"
        return 1
    fi
}

step5_list_versions() {
    echo -e "${BLUE}Step 5: Listing versions (should show delete marker)...${NC}"
    ./list-versions.sh "$BUCKET_NAME" "$TEST_KEY"
}

step6_undelete() {
    echo -e "${BLUE}Step 6: Undeleting the file...${NC}"
    ./undelete-object.sh "$BUCKET_NAME" "$TEST_KEY"
}

step7_verify_restored() {
    echo -e "${BLUE}Step 7: Verifying file is restored...${NC}"
    aws s3api head-object --bucket "$BUCKET_NAME" --key "$TEST_KEY" --region "$AWS_REGION" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ File is restored and accessible!${NC}"
        return 0
    else
        echo -e "${RED}✗ File not accessible after restoration${NC}"
        return 1
    fi
}

cleanup() {
    echo -e "${BLUE}Cleanup: Removing test file...${NC}"
    aws s3 rm "s3://$BUCKET_NAME/$TEST_KEY" --region "$AWS_REGION" > /dev/null 2>&1
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

main() {
    print_header
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name is required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name>${NC}"
        echo -e "${YELLOW}Example: $0 undelete-storage-enoch-v114${NC}"
        exit 1
    fi
    BUCKET_NAME="$1"

    step1_create_file || exit 1
    echo ""
    step2_verify_exists || exit 1
    echo ""
    step3_delete_file || exit 1
    echo ""
    step4_verify_deleted || exit 1
    echo ""
    step5_list_versions
    echo ""
    step6_undelete || exit 1
    echo ""
    step7_verify_restored || exit 1
    echo ""
    cleanup
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Undelete test completed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
