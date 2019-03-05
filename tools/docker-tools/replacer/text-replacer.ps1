$basefile = $args[0]
$endfile = $args[1]
$old = $args[2]
$new = $args[3]

if ($basefile -ne $endfile){
    New-Item -ItemType File -Path $endfile -Force | Out-Null
    copy-item $basefile $endfile -Recurse -Force | Out-Null
}

if ($old -AND $new){
    (Get-Content $endfile) |
    Foreach-Object {$_.replace("$old", $new)} |
    Set-Content $endfile
}
