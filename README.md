# Homeassistant Alexa connection via AWS Lambda Functions and Cloudflare Zero Trust Tunnel

This Terraform code lets you deploy all necessary resources to use Amazon Alexa as voice control for your Homeassistant instance.

It differs slightly from the official documentation to make your public endpoint more secure by adding authorization requirements to the requests made by the AWS Lambda Function, however the functionality is the same.

The code for the Lambda functions is copied from [here](https://gist.github.com/dkaser/bcfc82c4f84ef02c81c218f36afdca01). I also wrote a [comment](https://gist.github.com/dkaser/bcfc82c4f84ef02c81c218f36afdca01?permalink_comment_id=5256238#gistcomment-5256238) there on how to set this up manually, but thought why not automate it, since cloud providers are built for automation and it is less prone to errors.

#### Table of contents

* [Usage](#usage)
    * [Download](#download)
    * [Preparation](#preparation)
        * [Cloudflare API Token](#cloudflare-api-token)
        * [AWS Access Key](#aws-access-key)
    * [Further Configuration](#further-configuration)
    * [Deployment](#deployment)
* [Alexa Skill Configuration](#alexa-skill-configuration)
* [Additional Notes](#additional-notes)
    * [Further Customization](#further-customization)
        * [Cloudflare](#cloudflare)
        * [AWS IAM](#aws-iam)
        * [AWS Lambda Functions](#aws-lambda-functions)
* [Notes On Terraform](#notes-on-terraform)

## Usage

### Download

Clone the repo to a location of your choice.

### Preparation

First you'll have to [install Terraform](https://developer.hashicorp.com/terraform/install). Terraform is an infrastructure as code tool used to create all necessary resources in AWS and Cloudflare to get you up and running.

The second step is to create an API token for Cloudflare, as well as the access key for AWS.

#### Cloudflare API Token

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

#### AWS Access Key

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

### Further Configuration

Fill in the remaining variables in [terraform.tfvars](terraform.tfvars). A short summary is provided in the file for each variable, as well as some example values, so it should be clear what each variable should be.

### Deployment

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

## Alexa Skill Configuration

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

## Additional Notes

The public endpoint that will be created for Cloudflare will have two access policies. One that is used by your Lambda functions and one meant for accessing the instance in a browser. The browser access will be secured by a OTP, which is sent by mail. You can restrict the web access to your instance to specific mail addresses and/or countries by specifying them in the respective variables in [terraform.tfvars](terraform.tfvars).

Your public endpoint will always be `homeassistant.your.domain`.

The access for your Lambda functions will always be restricted to the region you deploy the functions in. Additionally this access is restricted to services that know your service token, which is also created automatically. To make it more secure, this access token is not part of any output, so it is only known to Terraform and your Lambda function. However if you need it later on, you can get the value from the app configuration in the AWS console. It is stored in `AWS Systems Manager > Parameter Store`.

By default the service token is only valid for one year, so you will have to rotate that token when it expires.

### Further Customization

You can further customize the deployment by editing the `homeassistant` Terraform module in [tf_modules/homeassistant](tf_modules/homeassistant/). Please note that I won't provide any support for editing the module, or any of the submodules.
However here's an overview over the most notable hardcoded values in the `homeassistant` Terraform module:

#### Cloudflare

You can find all hardcoded values in [main.tf](tf_modules/homeassistant/main.tf).

The submodule `cloudflare` supports more than just OTP as an Identity provider. I have also tested it with Microsoft Entra ID, so you might want to set this up. Check [idp.tf](tf_modules/submodules/cloudflare/idp.tf) and [variables.tf](tf_modules/submodules/cloudflare/variables.tf) in the `cloudflare` submodule for further information.

You can add more tunnel endpoints by expanding the variable `tunnel_config` in [main.tf](tf_modules/homeassistant/main.tf). Check [variables.tf](tf_modules/submodules/cloudflare/variables.tf), [tunnel.tf](tf_modules/submodules/cloudflare/tunnel.tf) and [access.tf](tf_modules/submodules/cloudflare/access.tf) in the `cloudflare` submodule for further information.

#### AWS IAM

This is hardcoded completely, since it only provides an IAM role to execute Lambda functions, read SSM parameters and write logs to Cloud Watch. You could alter the permissions, however it shouldn't be necessary.

#### AWS Lambda Functions

The modules `connector` and `wrapper` both use the submodule `lambda`. Due to the app config only being needed once, it is omitted in the `wrapper` module. Other than that both modules are nearly identical.

The only change you might want to make is the `handler` variable when you update one of the lambda source archives and don't use `main.py` as the file which contains your lambda function. In that case change the value to `<filename>.<function_name>`. To change the source archive for the lambda functions, simply place a zip archive named `lambda.zip` in a folder of your choice and change `source_dir` in [locals.tf](locals.tf) to the path of the new folder.

## Notes On Terraform

Terraform writes a state file to keep track of your current infrastructure. If you just want to use it to deploy it initially and want to manage it manually later on, then you don't have to care about the state file.
However if you intend to continue managing the resources via Terraform, make sure to keep all files, especially the state file, secure. A good practise for that is to store it in a cloud storage like an AWS S3 bucket.

Due to the state being read on execution, it could be that Terraform complains about existing resources in your Cloudflare account. To resolve that you'll have to import the existing resources into your Terraform state and write some code to define those resources.
Luckily Cloudflare provides a tool that can do this for you, so you won't need much experience with Terraform to use it: [Cloudflare Terraforming](https://github.com/cloudflare/cf-terraforming)

But be aware, Terraform will detect any manual changes you made to your resources and will revert them if you run the `terraform apply` command again in the future, so make sure to either only update your managed resources via Terraform, or implement your manual changes into Terraform before applying the config again.
