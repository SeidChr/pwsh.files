function Get-Directory {
    param([string] $Path)
    # path is fully qualified or relative
    $parentPath = Split-Path $Path -Parent
    $leaf = Split-Path $Path -Leaf
    
    $parent = if ($parentPath) { 
        Get-Directory -Path $parentPath 
    } else { 
        Get-Location 
    }

    if (-not (Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Path $parent -Name $leaf -Confirm
    }

    if (Test-Path -Path $Path) {
        Resolve-Path -Path $Path
    }
}

function Initialize-NodeEnvironment {
    param(
        $Path,
        [string] $Version
    )
    # create $root folder with $path
    if (-Not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path (Split-Path $Path -Parent) -Name (Split-Path $Path -Leaf)
    }

    # check if node $version zip is available at {local node repository}
    # if not: download from website
    $archive = Get-NodeArchive -Version $version

    # unzip node into folder with path "$root/node/$version"
    Expand-Archive -Path $archive.FullName -DestinationPath (Join-Path $Path "node" $Version)

    # create a "project" folder "$root/project" which will be the git folder
    # create a "user" folder "$root/user" which will be the user-home folder for that project
    # optional: checkout existing repository
    # create $root/project/.vscode/psprofile.ps1 as $projectProfile
    # add to [project-profile]
    #  - user-home redirection $env:HOMEPATH = "$root/user"
    #  - node-path entry Add-Path "$root/node/$version"
}

function Get-NodeArchive {
    param([string] $Version)
    # !archive locally available
    # ? download archive
    #
    # return archive
}