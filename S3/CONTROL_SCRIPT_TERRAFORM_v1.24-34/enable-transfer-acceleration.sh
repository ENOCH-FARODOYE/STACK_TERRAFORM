
```bash
#!/bin/bash

# Story 35: Enable Transfer Acceleration

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BUCKET_NAME=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  S3 Transfer Acceleration${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

enable_acceleration() {
    echo -e "${YELLOW}Enabling Transfer Acceleration...${NC}"
    
    aws s3api put-bucket-accelerate-configuration \
        --bucket "$BUCKET_NAME" \
        --accelerate-configuration Status=Enabled \
        --region "$AWS_REGION"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Transfer Acceleration enabled${NC}"
        echo ""
        echo -e "${GREEN}Accelerated endpoint:${NC}"
        echo -e "${BLUE}$BUCKET_NAME.s3-accelerate.amazonaws.com${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to enable acceleration${NC}"
        echo -e "${YELLOW}Note: Bucket name cannot contain periods (.)${NC}"
        return 1
    fi
}

display_info() {
    echo ""
    echo -e "${BLUE}Transfer Acceleration Info:${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${GREEN}Benefits:${NC}"
    echo -e "  • Faster uploads over long distances"
    echo -e "  • Uses CloudFront edge locations"
    echo -e "  • Optimizes TCP protocol"
    echo ""
    echo -e "${YELLOW}Usage Examples:${NC}"
    echo -e "  # AWS CLI:"
    echo -e "  aws s3 cp file.txt s3://$BUCKET_NAME/ --endpoint-url https://s3-accelerate.amazonaws.com"
    echo ""
    echo -e "  # Python boto3:"
    echo -e "  s3 = boto3.client('s3', config=Config(s3={'use_accelerate_endpoint': True}))"
    echo -e "${BLUE}----------------------------------------${NC}"
}

main() {
    print_header
    
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Bucket name required${NC}"
        echo -e "${YELLOW}Usage: $0 <bucket-name>${NC}"
        exit 1
    fi
    
    BUCKET_NAME="$1"
    
    enable_acceleration || exit 1
    display_info
}

main "$@"
```

