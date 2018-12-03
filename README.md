# terraform-aws-mfa
This guide will show the steps required to use Terraform with AWS MFA enabled.

## Requirements:
- A properly configured AWS client
- Terraform installed 

## Context
AWS supports two types of authentication:

### Console
- Human based. 
- MFA enabled for account login.
- User provides login and password at the login screen and enters the temporary MFA token from a previously configured device.

### API 
- Human or machine based. 
- MFA policies associated to specific API endpoints.
- Each request must include a AWS SECRET ID, AWS_SECRET and SESSION_TOKEN. These are temporary and can be obtained by first issuing a "get_session_token" command or reaching the equivalent API endpoint.
- Terraform is able to read these from environment variables, from hardcoded terraform variables, or retrieve them from Hashicorp Vault.

## API authentication

First, you need to create a policy in AWS protecting specific resources behind MFA

1. Create group "RequireMFA"
2. Associate "Require_MFA_EC2_Write" and "Require_MFA_IAM_Write" policies. As the names alude, these policies will require MFA authentication for write operations involving EC2 and IAM resources, anything else can be managed using regular API keys (AWS_SECRET and AWS_SECRET_ID)
3. Without adding your user to this group, try executing:
```
aws ec2 create-key-pair --key-name stenio-test --dry-run
# An error occurred (DryRunOperation) when calling the CreateKeyPair operation: Request would have succeeded, but DryRun flag is set.
```
4. Now add your user to this group, and the error message changes:
```
# Update YOUR_USER_NAME with your username
aws iam add-user-to-group --group-name RequireMFA --user-name YOUR_USER_NAME
aws ec2 create-key-pair --key-name stenio-test --dry-run
# An error occurred (UnauthorizedOperation) when calling the CreateKeyPair operation: You are not authorized to perform this operation.
```
5. To create temporary credentials using MFA, update the file getawscreds.sh with MFA_ID and execute:
```
# Update MFA_TOKEN with the temporary token issued by the MFA device associated with the account
eval $(getawscreds.sh MFA_TOKEN)
#
# This will update your env vars with creds that are good for 12 hours by default, this can be as short as 15 minutes, or up to 36 hours max
``` 
6. Now you will get again:
```
aws ec2 create-key-pair --key-name stenio-test --dry-run
# An error occurred (DryRunOperation) when calling the CreateKeyPair operation: Request would have succeeded, but DryRun flag is set.
```
7. If you want to return everything to original state, execute:
```
aws iam remove-user-from-group --group-name RequireMFA --user-name YOUR_USER_NAME
```

## Terraform Open Source
In the above example we used AWS cli commands. The same behavior can be expected when executing Terraform, since it can leverage the AWS environment variables for the AWS provider, as described here: https://www.terraform.io/docs/providers/aws/#environment-variables 

## Terraform Enterprise
The above will also work with Terraform Enterprise. However since TFE allows you to store state remotely and to use the concept of Workspaces to better control your deployment, you can explicitly update the remote TFE variables:

1. Add your AWS user to the MFA group:
```
aws iam add-user-to-group --group-name RequireMFA --user-name YOUR_USER_NAME
```
2. Execute the script providing the temporary token from MFA device:
```
eval $(getawscreds.sh MFA_TOKEN)
``` 
3. Upload the temporary credentials to TFE:
```
eval $(tfe_pushvars.sh ORG WORKSPACE)
```
4. Terraform Enterprise runs in this workspace can now be executed. For additional information on leveraging the TFE provider for remote execution, check https://www.terraform.io/docs/backends/types/terraform-enterprise.html

## Vault integration
### Vault as a virtual MFA device
The above workflow requires and additional, out of band manual step of entering the temporary token before retrieving the credentials. This is great for human-based workflows and you can leverage a tool such as Jenkins to have some degree of automation.

However with Hashicorp Vault, instead of leveraging a virtual MFA device that needs to be trigered by a human, you can automatically generate the temporary token - Vault will behave as the virtual MFA device. You can then use one of the machine authentication methods available to Vault (Cloud based, AppRole, etc) to have a CICD pipeline automate the MFA workflow without human intervation while still maintaining high level of security.

Additional information: https://www.vaultproject.io/docs/secrets/totp/index.html

### AWS Secrets Engine for Temporary Credentials
One of the challenges of the above workflow is that each API needs to be protected explicitly. An alternative secure workflow available to Vault is the AWS dynamic secret engine - Vault can create temporary AWS IAM credentials, and manage its lifecycle as an in-band process. This can be further integrated with Terraform by leveraging the Vault provider. This Producer/Consumer workflow is described here: https://www.hashicorp.com/resources/using-dynamic-secrets-in-terraform
