#!/bin/bash

# Same-Region Cross-Account S3 Replication Setup Script

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SOURCE_BUCKET=""
DEST_BUCKET=""
DEST_ACCOUNT=""
ROLE_ARN=""
AWS_REGION="us-east-1"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Same-Region Cross-Account Replication Setup${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

setup_sameregion_crossaccount_replication() {
    echo -e "${YELLOW}Configuring same-region cross-account replication...${NC}"
    echo -e "${BLUE}Source Bucket: ${NC}$SOURCE_BUCKET (Account 978820380225, us-east-1)"
    echo -e "${BLUE}Destination Bucket: ${NC}$DEST_BUCKET (Account $DEST_ACCOUNT, us-east-1)"
    echo -e "${BLUE}IAM Role: ${NC}$ROLE_ARN"
    echo ""
    
    CONFIG_FILE="replication-sameregion-crossaccount-config.json"
    
    cat > "$CONFIG_FILE" <<EOF
{
  "Role": "$ROLE_ARN",
  "Rules": [
    {
      "Status": "Enabled",
      "Priority": 2,
      "DeleteMarkerReplication": { 
        "Status": "Enabled" 
      },
      "Filter": { 
        "Prefix": "" 
      },
      "Destination": {
        "Bucket": "arn:aws:s3:::$DEST_BUCKET",
        "Account": "$DEST_ACCOUNT",
        "ReplicationTime": {
          "Status": "Enabled",
          "Time": { 
            "Minutes": 15 
          }
        },
        "Metrics": {
          "Status": "Enabled",
          "EventThreshold": { 
            "Minutes": 15 
          }
        },
        "AccessControlTranslation": {
          "Owner": "Destination"
        }
      }
    }
  ]
}
EOF
    
    echo -e "${YELLOW}Applying replication configuration...${NC}"
    
    aws s3api put-bucket-replication \
        --bucket "$SOURCE_BUCKET" \
        --replication-configuration "file://$CONFIG_FILE" \
        --region "$AWS_REGION"
    
    EXIT_CODE=$?
    
    rm -f "$CONFIG_FILE"
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Same-region cross-account replication configured successfully!${NC}"
        echo ""
        echo -e "${GREEN}Summary:${NC}"
        echo -e "  Source: s3://$SOURCE_BUCKET (us-east-1)"
        echo -e "  Destination: s3://$DEST_BUCKET (us-east-1)"
        echo -e "  Account: $DEST_ACCOUNT"
        echo -e "  Replication Time: 15 minutes"
        echo -e "  Type: Same-Region Cross-Account"
        echo -e "  Priority: 2"
        return 0
    else
        echo ""
        echo -e "${RED}✗ Failed to configure same-region cross-account replication${NC}"
        echo -e "${YELLOW}Check:${NC}"
        echo -e "  1. Destination bucket exists in us-east-1"
        echo -e "  2. Destination bucket has versioning enabled"
        echo -e "  3. Destination bucket policy allows source account"
        echo -e "  4. IAM role has correct permissions"
        return 1
    fi
}

main() {
    print_header
    
    if [ $# -lt 4 ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        echo ""
        echo -e "${YELLOW}Usage:${NC}"
        echo -e "  $0 <source-bucket> <dest-bucket> <dest-account-id> <role-arn>"
        echo ""
        echo -e "${YELLOW}Example:${NC}"
        echo -e "  $0 advanced-bucket-enoch-v125 \\"
        echo -e "     replica-bucket-enoch-v125-sameregion \\"
        echo -e "     411955586173 \\"
        echo -e "     arn:aws:iam::978820380225:role/s3-replication-role-enoch-v125-sameregion-crossaccount"
        exit 1
    fi
    
    SOURCE_BUCKET="$1"
    DEST_BUCKET="$2"
    DEST_ACCOUNT="$3"
    ROLE_ARN="$4"
    
    setup_sameregion_crossaccount_replication
}

main "$@"

