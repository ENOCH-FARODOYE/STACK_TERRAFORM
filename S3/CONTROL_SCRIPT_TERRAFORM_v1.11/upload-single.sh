#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
FILE_PATH=""
S3_KEY=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  S3 Single File Upload${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

validate_file_exists() {
    echo -e "${YELLOW}Validating source file...${NC}"
    if [ -f "$FILE_PATH" ]; then
        FILE_SIZE=$(stat -c%s "$FILE_PATH" 2>/dev/null || stat -f%z "$FILE_PATH" 2>/dev/null)
        echo -e "${GREEN}✓ File exists: $FILE_PATH${NC}"
        echo -e "${GREEN}  File size: $FILE_SIZE bytes${NC}"
        return 0
    else
        echo -e "${RED}✗ File not found: $FILE_PATH${NC}"
        return 1
    fi
}

validate_bucket_exists() {
    echo -e "${YELLOW}Validating bucket...${NC}"
    if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" 2>/dev/null; then
        echo -e "${GREEN}✓ Bucket exists: $BUCKET_NAME${NC}"
        return 0
    else
        echo -e "${RED}✗ Bucket not found: $BUCKET_NAME${NC}"
        return 1
    fi
}

upload_file() {
    echo -e "${YELLOW}Uploading file to S3...${NC}"
    START_TIME=$(date +%s)
    aws s3 cp "$FILE_PATH" "s3://$BUCKET_NAME/$S3_KEY" --region "$AWS_REGION"
    if [ $? -eq 0 ]; then
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        echo -e "${GREEN}✓ Upload completed in ${DURATION}s${NC}"
        return 0
    else
        echo -e "${RED}✗ Upload failed${NC}"
        return 1
    fi
}

verify_upload() {
    echo -e "${YELLOW}Verifying upload...${NC}"
    OBJECT_INFO=$(aws s3api head-object --bucket "$BUCKET_NAME" --key "$S3_KEY" --region "$AWS_REGION" 2>&1)
    if [ $? -eq 0 ]; then
        UPLOADED_SIZE=$(echo "$OBJECT_INFO" | jq -r '.ContentLength' 2>/dev/null)
        ETAG=$(echo "$OBJECT_INFO" | jq -r '.ETag' 2>/dev/null)
        echo -e "${GREEN}✓ File verified in S3${NC}"
        echo -e "${GREEN}  S3 Key: $S3_KEY${NC}"
        echo -e "${GREEN}  Size: $UPLOADED_SIZE bytes${NC}"
        echo -e "${GREEN}  ETag: $ETAG${NC}"
        return 0
    else
        echo -e "${RED}✗ Verification failed${NC}"
        return 1
    fi
}

main() {
    print_header
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <file-path> <s3-key>${NC}"
        exit 1
    fi
    BUCKET_NAME="$1"
    FILE_PATH="$2"
    S3_KEY="$3"
    validate_file_exists || exit 1
    echo ""
    validate_bucket_exists || exit 1
    echo ""
    upload_file || exit 1
    echo ""
    verify_upload || exit 1
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Upload completed successfully${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
