#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

BUCKET_NAME="$1"
S3_KEY="$2"
AWS_REGION="us-east-1"
DRY_RUN=${3:-true}   # default dry-run mode
LOG_FILE="logs/deleted_objects.log"

mkdir -p logs

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  S3 Single Object Deletion v1.13${NC}"
    echo -e "${BLUE}========================================${NC}"
}

validate_object_exists() {
    echo -e "${YELLOW}Checking if object exists...${NC}"
    aws s3api head-object --bucket "$BUCKET_NAME" --key "$S3_KEY" --region "$AWS_REGION" >/dev/null 2>&1 || { echo -e "${RED}Object not found${NC}"; exit 1; }
}

confirm_delete() {
    echo -e "${YELLOW}Ready to delete s3://$BUCKET_NAME/$S3_KEY${NC}"
    read -p "Are you sure? [y/N]: " CONFIRM
    [[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo -e "${RED}Deletion canceled${NC}"; exit 0; }
}

delete_object() {
    if [ "$DRY_RUN" == true ]; then
        echo -e "${YELLOW}[Dry-Run] Would delete: s3://$BUCKET_NAME/$S3_KEY${NC}"
    else
        aws s3 rm "s3://$BUCKET_NAME/$S3_KEY" --region "$AWS_REGION" && echo "$S3_KEY deleted on $(date)" >> "$LOG_FILE"
        echo -e "${GREEN}✓ Deleted s3://$BUCKET_NAME/$S3_KEY${NC}"
    fi
}

main() {
    [ $# -lt 2 ] && { echo -e "${RED}Usage: $0 <bucket-name> <s3-key> [dry-run=true/false]${NC}"; exit 1; }
    print_header
    validate_object_exists
    confirm_delete
    delete_object
}

main "$@"

