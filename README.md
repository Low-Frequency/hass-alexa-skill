# Homeassistant Alexa connection via AWS Lambda Functions and Cloudflare Zero Trust Tunnel

This Terraform code lets you deploy all necessary resources to use Amazon Alexa as voice control for your Homeassistant instance.

It differs slightly from the official documentation to make your public endpoint more secure by adding authorization requirements to the requests made by the AWS Lambda Function, however the functionality is the same.

The code for the Lambda functions is copied from [here](https://gist.github.com/dkaser/bcfc82c4f84ef02c81c218f36afdca01). I also wrote a [comment](https://gist.github.com/dkaser/bcfc82c4f84ef02c81c218f36afdca01?permalink_comment_id=5256238#gistcomment-5256238) on how to set this up manually, but thought why not automate it, since cloud providers are built for automation.

# Usage

## Download

Download the repo to a location of your choice.

## Preparation

First you'll have to [install Terraform](https://developer.hashicorp.com/terraform/install). Terraform is an infrastructure as code tool used to create all necessary resources in AWS and Cloudflare to get you up and running.

The second step is to create an API token for Cloudflare, as well as the access key for AWS.

### Cloudflare API Token

In the Cloudflare dashboard go to your profile, select `API Tokens` and create a new token.

Select `Create Custom Token`, give it a name and set the following permissions:

| Scope   | Item                                                 | Permission |
|---------|------------------------------------------------------|------------|
| Account | Cloudflare Tunnel                                    | Edit       |
| Account | Access: Service Tokens                               | Edit       |
| Account | Access: Organizations, Identity Providers and Groups | Edit       |
| Account | Access: Apps and Policies                            | Edit       |
| Zone    | DNS                                                  | Edit       |

Confirm your selection, create the token and save it to the corresponding variable in [terraform.tfvars](terraform.tfvars).

Next click on your domain in the overview and copy your `Zone ID` and `Account ID` to the corresponding variables in [terraform.tfvars](terraform.tfvars). Fill out the variable `cloudflare_zone` with your domain.

### AWS Access Key

In the AWS console go to `IAM`, select `Users` and create a new user.

Username can be anything you like. I used `terraform` to indicate that this user is used to access AWS with Terraform. Don't check the box for giving the user access to the management console!

Click on `next` and assign a policy directly to the user. Search for `AdministratorAccess`, check the box next to it, click on `next` and then `create user`.

Select the newly created user, switch to the tab `Security credentials` and create an `Access key`. Select `Third party service`, confirm and create the access key.

In the next screen, you'll get presented your `access key` and `access secret`. Copy both of them and paste them into the corresponding variables in [terraform.tfvars](terraform.tfvars). After that set `aws_region` to a region close to you. The following regions are supported:

| Region    | Location                  |
|-----------|---------------------------|
| eu-west-1 | Europe (Ireland)          |
| us-west-2 | USA West (Oregon)         |
| us-east-1 | USA East (North-Virginia) |

## Further configuration

Fill in the remaining variables in [terraform.tfvars](terraform.tfvars). A short summary is provided in the file for each variable, as well as some example values, so it should be clear what each variable should be.

## Deployment

To deploy the full configuration, you'll have to open a command line, change the directory to the downloaded repository and execute the following commands:

```
terraform init
```

This initializes Terraform. It will download all necessary plugins to be able to create the resources for you.

```
terraform plan -out plan.tfplan
```

This checks your existing resources in Cloudflare and AWS. After checking it will create a plan on what to create or change and show it to you. The plan is saved as `plan.tfplan` in the current directory.

```
terraform apply -input=false plan.tfplan
```

This will automatically create the resources and configure them for you. All you have to do afterwards is configure the Alexa Skill based on the output of this command.

# Alexa Skill configuration

Terraform will give you information on how to configure your Alexa skill, as well as an instruction on how to install and set up `cloudflared` for your Cloudflare Zero Trust Tunnel. The output will look like this:

```
Outputs:
alexa_skill_configuration = {
  smart_home = {
    default_endpoint = "<THE ARN OF YOUR LAMBDA FUNCTION>"
  }
  account_linking = {
    web_authorization_url = "https://<YOUR CLOUDFLARE HA ENDPOINT>/auth/authorize"
    access_token_uri      = "<THE URL OF THE AUTHORIZATION LAMBDA FUNCTION>"
    client_id             = "https://pitangui.amazon.com/"
    your_secret           = "<THE SECRET YOU CHOSE>"
    authentication_scheme = "Credentials in request body"
    scope                 = "smart_home"
  }
}
cf_tunnel_install_commands = {
  download  = "curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
  install   = "sudo dpkg -i cloudflared.deb"
  configure = "sudo cloudflared service install <YOUR CF TUNNEL TOKEN>"
}
```

Configure the values shown in the output in your Alexa Skill under the respective sections, execute the three commands shown on the machine you want to use for `cloudflared` and you're almost done. All that is left is activating your Skill in the Alexa app on your phone.

# Additional Notes

The public endpoint that will be created for Cloudflare will have two access policies. One that is used by your Lambda functions and one meant for accessing the instance in a browser. The browser access will be secured by a OTP, which is sent by mail. You can restrict the web access to your instance to specific mail addresses and/or countries by specifying them in the respective variables in [terraform.tfvars](terraform.tfvars).

The access for your Lambda functions will always be restricted to the region you deploy the functions in. Additionally this access is restricted to services that know your service token, which is also created automatically. To make it more secure, this access token is not part of any output, so it is only known to Terraform and your Lambda function. However if you need it later on, you can get the value from the app configuration in the AWS console. It is stored in `AWS Systems Manager > Parameter Store`.

By default the service token is only valid for one year, so you will have to rotate that token when it expires.
