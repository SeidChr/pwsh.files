param([pscredential] $Credential, [switch] $Digest)

if (!$Credential) {
    $Credential = Get-Credential
}

$nwCred = $Credential.GetNetworkCredential()
$username = [System.Web.HttpUtility]::UrlEncode($nwCred.UserName.ToLower())
$password = [System.Web.HttpUtility]::UrlEncode($nwCred.Password)

if ($Digest) {
    $digestValue = Invoke-RestMethod -Uri "https://eapi.pcloud.com/getdigest" |ForEach-Object digest
    $passwordDigest = Get-Sha1Hash -Text:($password + (Get-Sha1Hash -Text:$username) + $digestValue)
    Invoke-RestMethod "https://eapi.pcloud.com/userinfo?getauth=1&logout=1&username=$username&passworddigest=$passwordDigest&digest=$digestValue"
} else {
    Invoke-RestMethod "https://eapi.pcloud.com/userinfo?getauth=1&logout=1&username=$username&password$password"
}