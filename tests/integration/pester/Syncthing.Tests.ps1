Describe 'The syncthing application' {
    Context 'is installed' {
        It 'with binaries in /usr/bin/syncthing' {
            '/usr/bin/syncthing' | Should Exist
        }

        It 'with default configuration in /etc/syncthing/config.xml' {
            '/etc/syncthing/config.xml' | Should Exist
        }
    }

    Context 'has been daemonized' {
        $serviceConfigurationPath = '/lib/systemd/system/syncthing.service'
        if (-not (Test-Path $serviceConfigurationPath))
        {
            It 'has a systemd configuration' {
               $false | Should Be $true
            }
        }

        $expectedContent = @'
# If you modify this, please also make sure to edit init.sh

[Unit]
Description=Syncthing - Open Source Continuous File Synchronization
Documentation=https://github.com/syncthing/syncthing
After=multi-user.target

[Service]
User=syncthing
Group=syncthing
ExecStart=/usr/bin/syncthing -no-browser -no-restart -logflags=0 -home=/etc/syncthing
KillMode=mixed
Restart=on-failure

[Install]
WantedBy=multi-user.target
Alias=syncthing.service

'@
        $serviceFileContent = Get-Content $serviceConfigurationPath | Out-String
        $systemctlOutput = & systemctl status syncthing
        It 'with a systemd service' {
            $serviceFileContent | Should Be ($expectedContent -replace "`r", "")

            $systemctlOutput | Should Not Be $null
            $systemctlOutput.GetType().FullName | Should Be 'System.Object[]'
            $systemctlOutput.Length | Should BeGreaterThan 3
            $systemctlOutput[0] | Should Match 'syncthing.service - Syncthing - Open Source Continuous File Synchronization'
        }

        It 'that is enabled' {
            $systemctlOutput[1] | Should Match 'Loaded:\sloaded\s\(.*;\senabled;.*\)'

        }

        It 'and is running' {
            $systemctlOutput[2] | Should Match 'Active:\sactive\s\(running\).*'
        }
    }

    Context 'can be contacted' {
        try
        {
            $response = Invoke-WebRequest -Uri "http://localhost:8384/rest/system/ping" -Method Post -Headers $headers -UseBasicParsing
        }
        catch
        {
            # Because powershell sucks it throws if the response code isn't a 200 one ...
            $response = $_.Exception.Response
        }

        It 'responds to HTTP calls' {
            $response.StatusCode | Should Be 204
        }
    }
}
