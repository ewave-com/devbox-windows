$project = $args[0]
$upMode = $args[1]

$folderPath = $MyInvocation.MyCommand.Path + "\..\..\..\projects\" + $project + "\docker-up"
Get-ChildItem $folderPath -Filter *.yml |
Foreach-Object {
    $fileName =  $_.Name
    echo ================================================
    echo "[UP: Container]"
    echo "$fileName"
    echo ================================================
    Push-Location $folderPath
    $command = "docker-compose --log-level ERROR -f " + $fileName + " " + $upMode
    Invoke-Expression $command
}