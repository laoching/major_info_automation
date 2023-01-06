:: 윈도우 NTP 관련 서비스 'w32time'

:: w32time 시작
net start w32time

:: w32time 재부팅시 자동 시작되로록 등록
sc config w32time start=auto

:: NTP 서버 등록 및 내용 업데이트
w32tm /config /manualpeerlist:[ntp server], 0x9 /syncfromflags:manual /reliable:yes /update

::NTP 관련 레지스트릭밧 parameter 설정
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentConrolSet\Services\W32Time\TimeProviders\NtpClient" /v "Enabled" /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentConrolSet\Services\W32Time\TimeProviders\NtpServer" /v "Enabled" /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentConrolSet\Services\W32Time\Config" /v "AnnouunceFlags" /t REG_DWORD /d 10 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentConrolSet\Services\W32Time\TimeProviders\NtpClient" /v "SpecialPollInterval" /t REG_DWORD /d 1024 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentConrolSet\Services\W32Time\Config" /v MaxPosPhaseCorrection /t REG_DWORD /d 3600 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentConrolSet\Services\W32Time\Config" /v MaxNegPhaseCorrection /t REG_DWORD /d 3600 /f

:: 윈도우 방화벽 udp 123 open 설정
netsh advfirewall firewall add rule name="LCNTPServer" protocol=UDP dir=in localport=123 action=allow enable=yes

:: NTP 관련설정 업데이트
w32tm /config /update

:: NTP 시간 강제동기화
w32tm /resync /rediscover

:: NTP 서비스 재기동
Net strop w32time && net start w32time