add-type -AssemblyName System.Web.Extensions
$JSON = new-object Web.Script.Serialization.JavaScriptSerializer

$containers = docker ps -a --format '{{.Names}}'
foreach ($container in $containers) {
    $portBindings = docker inspect --format='{{json .HostConfig.PortBindings}}' $container
    $portBindings = $JSON.DeserializeObject($portBindings)
    foreach ($ports in $portBindings) {
        foreach ($portFull in $ports.keys) {
            $hostPort = $ports[$portFull].HostPort
            echo $hostPort
        }
    }
}