# %PROJECT_NAME%
# Here you can add any operations for copying docker-compose or other files you want

$project = $args[0]

[string]$sourceDirectory  = $MyInvocation.MyCommand.Path + "\..\..\..\..\projects\" + $project + "\docker-custom\*"
[string]$destinationDirectory = $MyInvocation.MyCommand.Path + "\..\..\..\..\projects\" + $project + "\docker-up"

if([System.IO.File]::Exists($sourceDirectory)){
    Copy-item -Force -Recurse -Verbose $sourceDirectory -Destination $destinationDirectory
} else {
    echo "Custom docker-compose files are not detected ... Skipping this step ..."
}
