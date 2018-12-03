#!/bin/sh

# Created by Sean Carolan (https://github.com/scarolan)

## This script will get temporary session credentials when you inform the MFA token as a parameter
## Replace MFA_TOKEN, AWS_ACCOUNT_NUMBER and MFA_ID with your values

## Example use: $eval $(getawscreds.sh MFA_TOKEN)

TOKEN=$1
SERIAL="arn:aws:iam::AWS_ACCOUNT_ID:mfa/MFA_ID"
creds=$(aws sts get-session-token --serial-number $SERIAL --token-code $TOKEN | jq -r '.[] | [.SessionToken,.AccessKeyId,.SecretAccessKey] | @tsv')

#echo $creds

echo $creds | while read token accesskey secretkey; do
  echo "export AWS_ACCESS_KEY_ID=$accesskey"
  echo "export AWS_SECRET_ACCESS_KEY=$secretkey"
  echo "export AWS_SESSION_TOKEN=$token"
done