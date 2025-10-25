#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Testing Folder Operations${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

step1_create_folders() {
    echo -e "${BLUE}Step 1: Creating folder structure...${NC}"
    
    ./create-folder.sh "$BUCKET_NAME" "documents/"
    ./create-folder.sh "$BUCKET_NAME" "documents/reports/"
    ./create-folder.sh "$BUCKET_NAME" "documents/reports/2024/"
    ./create-folder.sh "$BUCKET_NAME" "images/"
    ./create-folder.sh "$BUCKET_NAME" "videos/"
    
    echo -e "${GREEN}✓ Folder structure created${NC}"
}

step2_list_folders() {
    echo ""
    echo -e "${BLUE}Step 2: Listing folders...${NC}"
    ./list-folders.sh "$BUCKET_NAME"
}

step3_upload_files() {
    echo ""
    echo -e "${BLUE}Step 3: Uploading test files to folders...${NC}"
    
    echo "Test file for documents" > test-doc.txt
    aws s3 cp test-doc.txt "s3://$BUCKET_NAME/documents/test-doc.txt" --region "$AWS_REGION" > /dev/null 2>&1
    
    echo "Test report for 2024" > test-report.txt
    aws s3 cp test-report.txt "s3://$BUCKET_NAME/documents/reports/2024/test-report.txt" --region "$AWS_REGION" > /dev/null 2>&1
    
    rm test-doc.txt test-report.txt
    
    echo -e "${GREEN}✓ Test files uploaded${NC}"
}

step4_verify_structure() {
    echo ""
    echo -e "${BLUE}Step 4: Verifying folder structure...${NC}"
    echo ""
    
    echo -e "${GREEN}Root folders:${NC}"
    ./list-folders.sh "$BUCKET_NAME"
    
    echo ""
    echo -e "${GREEN}Documents subfolders:${NC}"
    ./list-folders.sh "$BUCKET_NAME" "documents/"
}

cleanup() {
    echo ""
    echo -e "${BLUE}Cleanup: Removing test folders...${NC}"
    
    read -p "Do you want to cleanup test folders? (y/n): " CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        aws s3 rm "s3://$BUCKET_NAME/documents/" --recursive --region "$AWS_REGION" > /dev/null 2>&1
        aws s3 rm "s3://$BUCKET_NAME/images/" --recursive --region "$AWS_REGION" > /dev/null 2>&1
        aws s3 rm "s3://$BUCKET_NAME/videos/" --recursive --region "$AWS_REGION" > /dev/null 2>&1
        echo -e "${GREEN}✓ Cleanup complete${NC}"
    fi
}

main() {
    print_header
    
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name is required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name>${NC}"
        echo -e "${YELLOW}Example: $0 my-bucket${NC}"
        exit 1
    fi
    
    BUCKET_NAME="$1"
    
    step1_create_folders
    step2_list_folders
    step3_upload_files
    step4_verify_structure
    cleanup
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Folder operations test complete${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"

