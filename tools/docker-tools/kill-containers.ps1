
$project_name=$args[0]
$project_name_pattern=$args[0] + "_*"
$db_container=$args[1]

function Show-Menu
{
    param (
        [string]$Title = 'Select Project Down Type'
    )
    Write-Host "================ $Title ================"

    Write-Host "1: Kill project containers."
    Write-Host "2: Stop project containers."
    Write-Host "q: exit."
}

 function Kill-Containers {

         echo "Killing $project_name containers"

         echo "Copying DB Files to host machine"
         $command = "docker cp " + $db_container + ":/var/lib/mysql projects/" + $project_name + "/sysdumps"
         Invoke-Expression $command
         docker stop $(docker ps --format "{{.ID}}" --filter "name=$project_name_pattern")
         docker rm -f $(docker ps -a --format "{{.ID}}" --filter "name=$project_name_pattern")
         $downFlag = 'DOWN_FLAG=kill'
#         Set-Content -Path 'sysdumps/down-flag.txt' -Value $downFlag

         echo Docker Prune
         $command = "docker volume prune --force"
         echo $command

         echo 'Containers have been killed.'
         echo ================================
 }

 function Stop-Containers {

         echo "Stopping $project_name containers"
         docker stop $(docker ps --format "{{.ID}}" --filter "name=$project_name_pattern")

         $downFlag = 'DOWN_FLAG=stop'
#         Set-Content -Path 'sysdumps/down-flag.txt' -Value $downFlag
         echo 'Containers have been stopped.'
         echo ================================
 }

 function Remove-Nginx-Configs {

         if ([System.IO.File]::Exists("configs/nginx-reversproxy/run/website-http-proxy-$project_name.conf")) {
            Remove-Item configs/nginx-reversproxy/run/website-http-proxy-$project_name.conf
         }
         if ([System.IO.File]::Exists("configs/nginx-reversproxy/run/website-https-proxy-$project_name.conf")) {
            Remove-Item configs/nginx-reversproxy/run/website-https-proxy-$project_name.conf
         }
 }

Show-Menu
$selection = Read-Host "Please make a selection"

switch ($selection)
 {
     '1' {

         Kill-Containers
         Remove-Nginx-Configs

         return
     } '2' {

         Stop-Containers
         remove-nginx-configs

         return
     } 'q' {
         'No action selected.'
         return
     }
 }


