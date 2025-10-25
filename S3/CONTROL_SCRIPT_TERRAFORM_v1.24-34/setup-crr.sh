#!/bin/bash

# Story 27: Setup Cross-Region Replication (Windows-compatible)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SOURCE_BUCKET=""
DEST_BUCKET=""
ROLE_ARN=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Setup Cross-Region Replication${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

setup_replication() {
    echo -e "${YELLOW}Setting up replication from $SOURCE_BUCKET to $DEST_BUCKET...${NC}"
    
    # Create config file in current directory (Windows-compatible)
    CONFIG_FILE="replication-config-temp.json"
    
    cat > "$CONFIG_FILE" <<EOF
{
  "Role": "$ROLE_ARN",
  "Rules": [
    {
      "Status": "Enabled",
      "Priority": 1,
      "DeleteMarkerReplication": { "Status": "Enabled" },
      "Filter": { "Prefix": "" },
      "Destination": {
        "Bucket": "arn:aws:s3:::$DEST_BUCKET",
        "ReplicationTime": {
          "Status": "Enabled",
          "Time": { "Minutes": 15 }
        },
        "Metrics": {
          "Status": "Enabled",
          "EventThreshold": { "Minutes": 15 }
        }
      }
    }
  ]
}
EOF
    
    aws s3api put-bucket-replication \
        --bucket "$SOURCE_BUCKET" \
        --replication-configuration "file://$CONFIG_FILE" \
        --region "$AWS_REGION"
    
    EXIT_CODE=$?
    
    # Clean up config file
    rm -f "$CONFIG_FILE"
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}✓ Replication configured successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to configure replication${NC}"
        return 1
    fi
}

main() {
    print_header
    
    if [ $# -lt 3 ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo -e "${YELLOW}Usage: $0 <source-bucket> <dest-bucket> <role-arn>${NC}"
        echo -e "${YELLOW}Example: $0 my-source my-dest arn:aws:iam::123:role/replication${NC}"
        exit 1
    fi
    
    SOURCE_BUCKET="$1"
    DEST_BUCKET="$2"
    ROLE_ARN="$3"
    
    setup_replication
}

main "$@"
