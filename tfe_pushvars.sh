#!/bin/sh

# Created by Sean Carolan (https://github.com/scarolan)

## This script will update a Terraform Enterprise Workspace with the temporary credentials retrieved after "getawscreds.sh" has been executed and temporary MFA token issued.
## Replace ORG and WORKSPACE with your values

## Example use: $eval $(tfe_pushvars.sh ORG WORKSPACE)

ORG=$1 
WORKSPACE=$2 
tfe pushvars -name $ORG/$WORKSPACE -overwrite "AWS_ACCESS_KEY_ID" -overwrite "AWS_SECRET_ACCESS_KEY" -overwrite "AWS_SESSION_TOKEN" -env-var "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" -senv-var "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" -senv-var "AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN" -env-var "CONFIRM_DESTROY=1" -env-var "TF_WARN_OUTPUT_ERRORS=1"
