#!/bin/sh
# authors: plumei.zhang@gmail.com
### Expect argument to be provided with the stack name
STACK_NAME=$1
REGION=$2

### Check if stack exists yet
aws cloudformation describe-stacks --stack-name ${STACK_NAME} > /dev/null 2>&1 || exit 0
### Initiate drift detection
DRIFT_DETECTION_ID=$(aws cloudformation detect-stack-drift --region $REGION --stack-name ${STACK_NAME} --query StackDriftDetectionId --output text)
### Wait for detection to complete
echo -n "Waiting for drift detection to complete..."
while true; do
    DETECTION_STATUS=$(aws cloudformation describe-stack-drift-detection-status --region $REGION --stack-drift-detection-id ${DRIFT_DETECTION_ID} --query DetectionStatus --output text) 
    if [ "DETECTION_IN_PROGRESS" = "${DETECTION_STATUS}" ]; then 
        echo -n "."
        sleep 1 
    elif [ "DETECTION_FAILED" = "${DETECTION_STATUS}" ]; then 
        DETECTION_STATUS_REASON=$(aws cloudformation describe-stack-drift-detection-status --region $REGION --stack-drift-detection-id ${DRIFT_DETECTION_ID} --query DetectionStatusReason --output text)
        STACK_DRIFT_STATUS=$(aws cloudformation describe-stack-drift-detection-status --region $REGION --stack-drift-detection-id ${DRIFT_DETECTION_ID} --query StackDriftStatus --output text) 
        echo ${STACK_DRIFT_STATUS}
        echo "WARNING: ${DETECTION_STATUS_REASON}"
        break
    else
        STACK_DRIFT_STATUS=$(aws cloudformation describe-stack-drift-detection-status --region $REGION --stack-drift-detection-id ${DRIFT_DETECTION_ID} --query StackDriftStatus --output text) 
        echo ${STACK_DRIFT_STATUS}
        break
    fi
done

### Describe the drift details
if [ "DRIFTED" = "${STACK_DRIFT_STATUS}" ]; then
    aws cloudformation describe-stack-resource-drifts \
        --stack-name ${STACK_NAME} \
        --query 'StackResourceDrifts[?StackResourceDriftStatus!=`IN_SYNC`].{Type:ResourceType, Resource:LogicalResourceId, Status:StackResourceDriftStatus, Diff:PropertyDifferences}' >&2
    exit 1
fi
