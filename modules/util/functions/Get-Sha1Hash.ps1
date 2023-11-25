param([string] $Text)
[byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($Text)
$sha1 = [System.Security.Cryptography.SHA1CryptoServiceProvider]::new()
[System.Convert]::ToHexString($sha1.ComputeHash($buffer)).ToLowerInvariant()
