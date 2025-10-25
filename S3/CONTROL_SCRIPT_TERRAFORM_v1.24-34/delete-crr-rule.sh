```bash
#!/bin/bash

# Story 28: Delete CRR Rule

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Delete CRR Configuration${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

delete_replication() {
    echo -e "${YELLOW}Deleting replication configuration...${NC}"
    
    aws s3api delete-bucket-replication \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Replication configuration deleted${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to delete replication${NC}"
        return 1
    fi
}

main() {
    print_header
    
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name>${NC}"
        exit 1
    fi
    
    BUCKET_NAME="$1"
    
    read -p "Delete replication configuration? (y/n): " CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        delete_replication
    else
        echo -e "${YELLOW}Deletion cancelled${NC}"
    fi
}

main "$@"
```

