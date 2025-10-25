#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
FILE_PATH=""
OBJECT_KEY=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Upload Object with Metadata${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

check_file_exists() {
    echo -e "${YELLOW}Checking if file exists...${NC}"
    
    if [ -f "$FILE_PATH" ]; then
        echo -e "${GREEN}✓ File exists: $FILE_PATH${NC}"
        FILE_SIZE=$(ls -lh "$FILE_PATH" | awk '{print $5}')
        echo -e "${GREEN}  File size: $FILE_SIZE${NC}"
        return 0
    else
        echo -e "${RED}✗ File does not exist: $FILE_PATH${NC}"
        return 1
    fi
}

upload_with_metadata() {
    echo ""
    echo -e "${YELLOW}Uploading file with metadata...${NC}"
    
    # Build metadata parameters
    METADATA_ARGS=""
    for META in "$@"; do
        IFS='=' read -r KEY VALUE <<< "$META"
        if [ ! -z "$KEY" ] && [ ! -z "$VALUE" ]; then
            # Remove x-amz-meta- prefix if provided
            KEY=${KEY#x-amz-meta-}
            METADATA_ARGS+="$KEY=$VALUE,"
        fi
    done
    
    # Remove trailing comma
    METADATA_ARGS=${METADATA_ARGS%,}
    
    echo -e "${YELLOW}Metadata: $METADATA_ARGS${NC}"
    echo ""
    
    aws s3 cp "$FILE_PATH" "s3://$BUCKET_NAME/$OBJECT_KEY" \
        --metadata "$METADATA_ARGS" \
        --region "$AWS_REGION" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ File uploaded with metadata${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to upload file${NC}"
        return 1
    fi
}

verify_upload() {
    echo -e "${YELLOW}Verifying upload and metadata...${NC}"
    
    METADATA=$(aws s3api head-object \
        --bucket "$BUCKET_NAME" \
        --key "$OBJECT_KEY" \
        --region "$AWS_REGION" \
        --query 'Metadata' \
        --output json 2>&1)
    
    echo -e "${GREEN}Object metadata:${NC}"
    echo "$METADATA" | jq -r 'to_entries[] | "  \(.key): \(.value)"'
}

main() {
    print_header
    
    if [ $# -lt 4 ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> <file-path> <object-key> <key1>=<value1> [key2=value2] ...${NC}"
        echo -e "${YELLOW}Example: $0 my-bucket /path/to/file.txt docs/file.txt author=John version=1.0${NC}"
        exit 1
    fi
    
    BUCKET_NAME="$1"
    FILE_PATH="$2"
    OBJECT_KEY="$3"
    shift 3
    
    check_file_exists || exit 1
    upload_with_metadata "$@" || exit 1
    echo ""
    verify_upload
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Upload with metadata complete${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main "$@"

