$variable_to_return=$args[0]
$file_to_write=$args[1]


if(!(Test-Path -Path projects )){
    New-Item -ItemType Directory -Path projects
}
$directories = Get-ChildItem -Directory projects

function Show-Menu($Folders)
{
    $Title = 'Select the project'

    Write-Host ""
    Write-Host "== $Title =="
    Write-Host ""
    for ($i=0; $i -lt $Folders.Count; $i++) {
        $name = $Folders[$i].Name;
        Write-Host "$i. $name"
    }
    Write-Host "q: Exit"

    Write-Host ""
    $selection = Read-Host "Please make a selection"
    if ($selection -eq 'q') {
        return '';
    }

    $selectedProject = $directories[$selection]
    return $selectedProject
}

$project = Show-Menu -Folders $directories

if ($project -eq "q") {
    exit
}

if ($project -eq "") {
    Write-Host "Wrong choice. Try again."
}

$outValue = "$variable_to_return=$project"
Set-Content -Path $file_to_write -Value $outValue

Write-Host ""
Write-Host ""