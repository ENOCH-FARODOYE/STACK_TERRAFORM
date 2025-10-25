
```bash
#!/bin/bash

# Story 33: Set ACL Permissions

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
ACL_TYPE="private"
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Set Bucket ACL${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

set_acl() {
    echo -e "${YELLOW}Setting ACL to: $ACL_TYPE${NC}"
    
    aws s3api put-bucket-acl \
        --bucket "$BUCKET_NAME" \
        --acl "$ACL_TYPE" \
        --region "$AWS_REGION"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ ACL set successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to set ACL${NC}"
        return 1
    fi
}

display_acl_info() {
    echo ""
    echo -e "${BLUE}ACL Types:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${GREEN}private${NC} - Owner gets FULL_CONTROL (default)"
    echo -e "${GREEN}public-read${NC} - Owner gets FULL_CONTROL, AllUsers get READ"
    echo -e "${GREEN}public-read-write${NC} - Owner gets FULL_CONTROL, AllUsers get READ and WRITE"
    echo -e "${GREEN}authenticated-read${NC} - Owner gets FULL_CONTROL, AuthenticatedUsers get READ"
    echo -e "${BLUE}----------------------------------------${NC}"
}

main() {
    print_header
    
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name> [acl-type]${NC}"
        display_acl_info
        echo -e "${YELLOW}Example: $0 my-bucket private${NC}"
        exit 1
    fi
    
    BUCKET_NAME="$1"
    ACL_TYPE="${2:-private}"
    
    set_acl
}

main "$@"
```

