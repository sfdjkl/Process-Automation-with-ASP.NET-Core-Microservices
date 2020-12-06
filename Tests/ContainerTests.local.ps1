$count = 0
do {
    $started = $true
    $services = @('http://localhost', 'http://localhost:5001/health', 'http://localhost:5002/carads/categories', 'http://localhost:5003/statistics')

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
