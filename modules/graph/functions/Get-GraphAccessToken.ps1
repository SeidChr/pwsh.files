param (
    [Parameter(Mandatory)]
    [guid] $TenantId,
    [Parameter(Mandatory)]
    [guid] $ClientId,
    [Parameter(Mandatory)]
    [string] $ClientSecret,
    [Parameter(ParameterSetName = 'WindowsNet', Mandatory)]
    [switch] $WindowsNet,
    [Parameter(ParameterSetName = 'MicrosoftCom', Mandatory)]
    [switch] $MicrosoftCom,
    [Parameter(ParameterSetName = 'CustomScope', Mandatory)]
    [string] $Scope
)

switch ($PSCmdlet.ParameterSetName) {
    'WindowsNet' {
        $Scope = 'https://graph.windows.net/.default'
    }
    'MicrosoftCom' {
        $Scope = 'https://graph.microsoft.com/.default'
    }
}

$params = @{
    'Uri'         = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    'Method'      = 'Post'
    'Body'        = @{
        'tenant'        = $TenantId
        'client_id'     = $ClientId
        'scope'         = $Scope
        'client_secret' = $ClientSecret
        'grant_type'    = 'client_credentials'
    }
    'ContentType' = 'application/x-www-form-urlencoded'
}

Invoke-RestMethod @params