$from_path=$args[0]
$to_path=$args[1]

echo $from_path
echo $to_path
if(Test-Path -Path $from_path ){
    Move-Item -Force $from_path $to_path
}
