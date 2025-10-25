#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
FOLDER_PATH=""
S3_PREFIX=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  S3 Folder Upload (Recursive)${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

validate_folder_exists() {
    echo -e "${YELLOW}Validating source folder...${NC}"
    if [ -d "$FOLDER_PATH" ]; then
        FILE_COUNT=$(find "$FOLDER_PATH" -type f | wc -l)
        echo -e "${GREEN}✓ Folder exists: $FOLDER_PATH${NC}"
        echo -e "${GREEN}  Files to upload: $FILE_COUNT${NC}"
        return 0
    else
        echo -e "${RED}✗ Folder not found: $FOLDER_PATH${NC}"
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

upload_folder() {
    echo -e "${YELLOW}Uploading folder to S3...${NC}"
    echo ""
    START_TIME=$(date +%s)
    aws s3 sync "$FOLDER_PATH" "s3://$BUCKET_NAME/$S3_PREFIX" \
        --region "$AWS_REGION" \
        --exclude ".DS_Store" \
        --exclude "*.md"
    if [ $? -eq 0 ]; then
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        echo ""
        echo -e "${GREEN}✓ Upload completed in ${DURATION}s${NC}"
        return 0
    else
        echo -e "${RED}✗ Upload failed${NC}"
        return 1
    fi
}

list_uploaded_files() {
    echo -e "${YELLOW}Listing uploaded files...${NC}"
    echo ""
    aws s3 ls "s3://$BUCKET_NAME/$S3_PREFIX" --recursive --human-readable --region "$AWS_REGION"
    echo ""
    OBJECT_COUNT=$(aws s3 ls "s3://$BUCKET_NAME/$S3_PREFIX" --recursive --region "$AWS_REGION" | wc -l)
    echo -e "${GREEN}Total objects in S3: $OBJECT_COUNT${NC}"
}

main() {
    print_header
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <folder-path> [s3-prefix]${NC}"
        exit 1
    fi
    BUCKET_NAME="$1"
    FOLDER_PATH="$2"
    S3_PREFIX="${3:-}"
    validate_folder_exists || exit 1
    echo ""
    validate_bucket_exists || exit 1
    echo ""
    upload_folder || exit 1
    echo ""
    list_uploaded_files
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Folder upload completed${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"
