$count = 0
do {
    $started = $true
    $services = @('http://20.49.211.87/', 'http://20.49.208.245:5001/health', 'http://20.49.212.212:5002/carads/categories', 'http://20.49.214.115:5003/statistics')

    Foreach($svc in $services)
    {
        $testStart = Invoke-WebRequest -Uri ${svc} -UseBasicParsing

        if ($testStart.statuscode -ne '200') {
            $started = $false
        } else {
            Start-Sleep -Seconds 1
        }
    }
} until ($started -or ($count -eq 3))

if (!$started) {
    exit 1
}
