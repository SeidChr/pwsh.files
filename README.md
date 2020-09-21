# Intro

This repository contains my personal powershell profile. I try to keep the methods as independent as possible, but there may be certain system dependencies here and there.
If you try to use the methods -as is-, and experience problems, feel free to make a pullrequest. No special rules apply.

However, i'd suggest you make a fork for your own use.

# Setup

There is an install-script in the setup folder. The script is designed, so that it will be downloaded and executed with a single commandline.
The script contains hardcoded references to this very repository, and will check out all the files from here.

You need to adapt the `install.ps1` file after forking this repository into your account.

The install-script expects git to be available on your system, to check out the referenced repository into your user-home.

The Profile-functions expect Visual Studio Code to be available in order to open and edit the profile (Edit-Profile).

# Profile

To access the profile, which is a powershell script that is executed on EVERY start of a powershell process in your user-space, you just need to open the file, which is referenced in the $profile variable, in the editor.

For example type `code $profile` to open the profile in visual studio code.

If you open the profile after installing, you will find a reference to the `profile.ps1` file on your system:

```
. ~/.pwsh/profile.ps1
```

If you have never opened your `$profile`, you may have to create the actual file first, as `$profile` just contains the path.

`New-Item -Path $profile -ItemType File` should do the trick.

This file will then load all the other files, which are checked out at the same loction by the install script.

## profile.ps1

This file is the entrypoint of this repository. It dot-sources all required files and also makes some adjustments:

- Add `.` to the END of the path. So you wont have to type .\ before each and every command. 
- Activate the menu-complete:  
![Menu-Autocomplete](/assets/menu-autocomplete.jpg)


# Prompt

I have modified the command prompt quite a bit, to match my requirements.

It should look like this:

![Command-Prompt](/assets/prompt.jpg)

The whole command-prompt has 2 lines. the above line will contain the Path to the current working directory. When the path is inside of the current user-home, the user-home path will be replaced by `~\`

The second line just has a `$` sign and a space, so there is enough space for very long powershell commands, when you need it :)

The whole prompt can be modified in the `prompt.ps1`

# Commands / Functions

## automation.ps1
Experimental windows automation functions. Not usefull atm.
## docker.ps1
### Test-DockerAvailable
Executing a docker command and checks the result for errors, which occure when the docker-service is not running.
### Start-Docker4Windows
Checks for a running instance of docker using `Test-DockerAvailable`, and spins up docker4win if it cannot find one.
Waits until the instance is available.
### Start-Docker
Forwarding to Start-Docker4Windows when running windows. Expecting the process to be already available on linux. So nothing has to be started.
### Get-DockerShell
Shortcut to execute a `docker run -it --rm ...` command, to quickly get a disposable container shell.
You can pass parameters for image, entrypoint and a mapped folder.


## git.ps1
### Add-GitHooks
Function to create git-hooks which in turn reference alredy existing powershell git hooks.
These powershell hooks are then being executed when you run git-actions.

Please check the source for further details.

## path.ps1
### Get-Path
Returns all path-entries, whith endin slashes (`.Trim("/").Trim("\")`) and empty entries removed.

### Repair-Path
Will just overwrite the current `$env:PATH` variable with the filtered entries from `Get-Path`

### Add-Path

Adding entries to the path environment variable
```
Add-Path "."
Add-Path "." -resolve -prefix
```

- `-resolve` will resolve the given path into a non-relative path before adding.
- `-prefix` will add the path to beginning of the path variable

PS: Do not add "." to the beginning of your Path! Otherwise local scripts will be always resoved and executed before normal commands, which brings a security risk.

## profile.ps1
### Update-Profile
Updates your local profile folder with the latest version from git (`git pull`)
### Open-Profile
Opens up vs-code to edit or view the profile-files from this repository.

## utility.ps1

Functions which do not fit into one of the other files.
### Get-LastWriteTime
Retrieves the most recent write-time in a folder (checks every file recursively)

### Write-JobOutput
Taks a list of jobs and a list of colors, and prints the output of each job using the colors (job1 = color 1, job2 = color 2 ect.)

See how it looks at `Start-Parallel` below.

### Start-Parallel
Starts multiple script-blocks in parallel using jobs. Giving you a nice console output for each script / job.

`ctrl+c` to end the jobs.

#### Ping-Sample:
code below...
![Start-Parallel](/assets/start-parallel.jpg)

```
Start-Parallel `
    { load -url "https://google.de" }, `
    { load -url "https://google.com" } `
    -InitializationScript `
    { 
        function load { 
            param ($url) 
            $progresspreference = "SilentlyContinue"; 
            do { 
                $url + " " + (measure-command { Invoke-WebRequest $url }).TotalMilliseconds;
                sleep 1 
            } while ($true)
        }
    }
```

Can be used to parallelize build processes and other processes which rely on console output.

### Start-Elevated
To be called from commandline. Starts a fresh powershell instance with elevated rights.
### Restart-Elevated
To be called from the beginning of a scriptfile that requires elevated rights. Will start the scriptfile with elevated rights.
### Confirm-Windows
Make sure we a running in the windows context (for elevation). Will throw an error in any other environment.