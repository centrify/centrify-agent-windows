# the only input parameter is the ticket number
param
(
    $ticket
)

# retrieve credentials through Centrify Privileged Access Service (PAS)
try
{
    # need to import the module that implement the Get-CIPAccount cmdlet
    Import-Module Centrify.Cloud.PowerShell.psm1
    Import-Module Centrify.IdentityPlatform.Powershell.psm1

    $user = "serviceNowAccount"
    $account = Get-CIPAccount -accountName $user
    $password = $account.Password | ConvertTo-SecureString -AsPlainText -Force
    $credentials = New-Object System.Management.Automation.PsCredential($user, $password)
}
Catch
{
    # the returned error message would be displayed to end user as well as logged as the failure reason
    # alternately could also return $false to represent failure
    # generic failure message would be used instead
    $result = "Cannot retrieve credentials"
    $result
    Exit
}

# ServiceNow instance URL
$url = 'https://dev00000.service-now.com'

# number of tickets to retrieve
$numberOfTickets = 1

# use ticket number as filter for the query
# additional parameter is separated by ampersand (&)
$requirments = "number=$ticket&active=true"

# alternative method is to validate the ticket after retrieving its fields
# multiple fields are comma separated
$state = "state"
$fields = "$state,impact,opened_at"

$url = "$url/api/now/table/incident?sysparm_limit=$numberOfTickets&$requirments&sysparm_display_value=&sysparm_exclude_reference_link&sysparm_suppress_pagination_header&sysparm_fields=$fields"

# Invoke-RestMethod is only supported by PowerShell 3.0 and beyond
$response = Invoke-RestMethod $url -Method Get -ContentType 'application/json' -Credential $credentials

# ***************************************************** 
# PowerShell 2.0 Invoke-RestMethod replacement
# *****************************************************
#function ConvertFrom-Json20([object] $item){ 
#    Add-Type -assembly System.Web.Extensions
#    $ps_js = New-Object System.Web.Script.Serialization.JavascriptSerializer

#    return ,$ps_js.DeserializeObject($item)
#}

#$request = [System.Net.WebRequest]::Create($url)
#$request.Method = "GET"
#$request.ContentType = 'application/json'
#$request.Credentials = $credentials
#$stream = New-Object System.IO.StreamReader $request.GetResponse().GetResponseStream()
#$response = ConvertFrom-Json20($stream.ReadToEnd())

if ($response -eq $null -or $response.result -eq $null -or $response.result.count -eq 0)
{
    $result = "Ticket cannot be found"
    $result
    Exit
}

$ticket = $response.result[0]

# message output is ignored by the agent
# however, error message could be displayed in agent's trace log 
Write-Host 'The Ticket Status is:' $ticket.$state
Write-Host 'The Ticket opened at:' $ticket.opened_at

if($ticket.$state -eq 1 -or $ticket.$state -eq 2)
{
    # return $true for successful validation
    $true
}
else
{
    $result = "Invalid ticket"
    $result
}
