### Your Cloudflare DNS zone. For example: example.com
cloudflare_zone         = ""
### The ID of your Cloudflare DNS zone
cloudflare_zone_id      = ""
### The ID of your Cloudflare account
cloudflare_account_id   = ""
### The API token for your Cloudflare account
cloudflare_api_token    = ""
### The access key for your AWS account
aws_access_key          = ""
### The secret for your AWS account
aws_secret_key          = ""
### The AWS region you want to deploy the lambda function in
aws_region              = "us-east-1"
### The URL (or IP) used to access Homeassistant on your local network
#!  Must include the port and the protocol ('http(s)://<IP|URL>:PORT')
homeassistant_local_url = "http://homeassistant.local:8123"
### A list of countries you want to restrict the access to
#!  Use 2 character country codes only
#!  Separate entries with a comma
#!  Leave empty to allow access from all countries (Empty means [], so delete the quotes too!)
allowed_countries       = ["US"]
### A list of mail addresses you want to restrict access to
#!  Separate entries with a comma
#!  Leave empty to allow access with all mail addresses (Empty means [], so delete the quotes too!)
allowed_mails           = ["mail.example.com"]
### The name of the lambda function in the AWS console
function_name           = "hoameassistant-alexa"
### The token of the alexa skill you have created
alexa_skill_token       = ""
### The long lived access token generated in your homeassistant instance
ha_access_token         = ""
### Random value
#!  Must be set as 'Your Secret' under the 'Account Linking' section in the alexa skill as well
wrapper_secret          = ""
