# https://gist.github.com/joegasper/3fafa5750261d96d5e6edf112414ae18

# Updated ConvertFrom-DN to support container objects

function ConvertFrom-DN {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [ValidateNotNullOrEmpty()]
        [string[]]$DistinguishedName
    )
    process {
        foreach ($DN in $DistinguishedName) {
            Write-Verbose $DN
            $CanonNameSlug = ''
            $DC = ''
            foreach ( $item in ($DN.replace('\,', '~').split(','))) {
                if ( $item -notmatch 'DC=') {
                    $CanonNameSlug = $item.Substring(3) + '/' + $CanonNameSlug
                }
                else {
                    $DC += $item.Replace('DC=', ''); $DC += '.'
                }
            }
            $CanonicalName = $DC.Trim('.') + '/' + $CanonNameSlug.Replace('~', '\,').Trim('/')
            [PSCustomObject]@{
                'CanonicalName' = $CanonicalName;
            }
        }
    }
}

function ConvertFrom-CanonicalUser {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$CanonicalName
    )
    process {
        $obj = $CanonicalName.Split('/')
        [string]$DN = 'CN=' + $obj[$obj.count - 1]
        for ($i = $obj.count - 2; $i -ge 1; $i--) { $DN += ',OU=' + $obj[$i] }
        $obj[0].split('.') | ForEach-Object { $DN += ',DC=' + $_ }
        return $DN
    }
}

function ConvertFrom-CanonicalOU {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$CanonicalName
    )
    process {
        $obj = $CanonicalName.Split('/')
        [string]$DN = 'OU=' + $obj[$obj.count - 1]
        for ($i = $obj.count - 2; $i -ge 1; $i--) { $DN += ',OU=' + $obj[$i] }
        $obj[0].split('.') | ForEach-Object { $DN += ',DC=' + $_ }
        return $DN
    }
}
