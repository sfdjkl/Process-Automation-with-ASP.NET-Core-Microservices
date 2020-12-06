$count = 0
do {
    $started = $true
    $services = @('http://20.73.107.66/', 'http://20.71.84.199:5001/health', 'http://20.71.83.238:5002/carads/categories', 'http://20.71.85.79:5003/statistics')

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
