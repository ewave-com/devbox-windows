param ([String] $PortsFile)

add-type -AssemblyName System.Web.Extensions
$JSON = new-object Web.Script.Serialization.JavaScriptSerializer

$mapping = @{}
$PortsFileContents = Get-Content $PortsFile
foreach ($row in $PortsFileContents) {
    $containerNameVariable, $port, $p3, $dynamicPortVariableName, $p5 = $row.Split("|")
    IF (!$mapping[$containerNameVariable]) {
        $mapping[$containerNameVariable] = @{}
    }
    $mapping[$containerNameVariable][$port] = $dynamicPortVariableName
}

foreach ($typeToName in $Args) {
    $delimiterIndex = $typeToName.IndexOf(":");
    $containerNameVariable = $typeToName.Substring(0, $delimiterIndex)
    $containerName = $typeToName.Substring($delimiterIndex + 1)
    $containerName = docker ps -a --filter="name=$containerName" --format="{{.Names}}"
    if ($containerName) {
        $portBindings = docker inspect --format='{{json .HostConfig.PortBindings}}' $containerName
        $portBindings = $JSON.DeserializeObject($portBindings)
        foreach ($ports in $portBindings) {
            foreach ($portFull in $ports.keys) {
                $port = $portFull.Substring(0, $portFull.IndexOf("/"))
                $hostPort = $ports[$portFull].HostPort
                if ($mapping[$containerNameVariable][$port]) {
                    $dynamicPortVariableName = $mapping[$containerNameVariable][$port]
                    echo "$dynamicPortVariableName=$hostPort";
                }
            }
        }
    }
}
