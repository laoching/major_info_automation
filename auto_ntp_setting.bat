:: ������ NTP ���� ���� 'w32time'

:: w32time ����
net start w32time

:: w32time ����ý� �ڵ� ���۵Ƿη� ���
sc config w32time start=auto

:: NTP ���� ��� �� ���� ������Ʈ
w32tm /config /manualpeerlist:[ntp server], 0x9 /syncfromflags:manual /reliable:yes /update

::NTP ���� ������Ʈ���� parameter ����
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentConrolSet\Services\W32Time\TimeProviders\NtpClient" /v "Enabled" /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentConrolSet\Services\W32Time\TimeProviders\NtpServer" /v "Enabled" /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentConrolSet\Services\W32Time\Config" /v "AnnouunceFlags" /t REG_DWORD /d 10 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentConrolSet\Services\W32Time\TimeProviders\NtpClient" /v "SpecialPollInterval" /t REG_DWORD /d 1024 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentConrolSet\Services\W32Time\Config" /v MaxPosPhaseCorrection /t REG_DWORD /d 3600 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentConrolSet\Services\W32Time\Config" /v MaxNegPhaseCorrection /t REG_DWORD /d 3600 /f

:: ������ ��ȭ�� udp 123 open ����
netsh advfirewall firewall add rule name="LCNTPServer" protocol=UDP dir=in localport=123 action=allow enable=yes

:: NTP ���ü��� ������Ʈ
w32tm /config /update

:: NTP �ð� ��������ȭ
w32tm /resync /rediscover

:: NTP ���� ��⵿
Net strop w32time && net start w32time