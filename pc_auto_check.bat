:: PC setting crawling
:: ----------- [LIST] ----------
:: 1. whoami
:: 2. ipconfig
:: 3. net share
:: 4. net user
:: 5. NTP 세팅 변경 [x.x.x.x]
:: 6. windows update 목록
:: 7. 설치된 프로그램 목록
:: 8. secpol.msc > 계정 정책 > 암호 정책 
::    - 최소 암호 사용 기간
::    - 최대 암호 사용 기간
::    - 최소 암호 길이
::    - 패스워드 복잡도 만족 유무
::    - 최근 암호 기억
::    - 해독 가능한 암호화 저장 유무

@echo off

:: 생성되는 결과파일 이름을 특정 경로에 있는 파일명으로 지정(사용자 PC 식별 위함)
for /f "tokens=*" %%a in ('dir /b "C:\Users\x\x\x"') do set asdf=%%a.txt

echo ##############################################[whoami] config result############################################## > %asdf%.txt
whoami >> %asdf%.txt

echo ##############################################[ipconfig] config result############################################## > %asdf%.txt
ipconfig >> %asdf%.txt

echo ##############################################[net share] config result############################################## > %asdf%.txt
net share >> %asdf%.txt

echo ##############################################[net user ~~] config result############################################## > %asdf%.txt
for /f "tokens=2 delims=^\" %%a in ('whoami') do set pc_name=%%a
net user %pc_name >> %asdf%.txt

echo ##############################################[NTP CHECK]############################################## > %asdf%.txt
net start w32time

:: 재부팅 시 w32time(ntp service) 자동 시작되도록 등록
sc config w32time start=auto

:: x.x.x.x을 ntp 서버로 변경
w32tm /config /manualpeerlist:x.x.x.x,0x9 /syncfromflags:manual /reliable:yes /update

::NTP 관련 레지스트리값 parameter 설정
red add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\SErvices\W32Time\TimeProviders\NtpClient" /v "Enabled" /t REG_DWORD \d 1 \f
red add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\SErvices\W32Time\TimeProviders\NtpServer" /v "Enabled" /t REG_DWORD \d 1 \f
red add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\SErvices\W32Time\Config" /v "AnnounceFlags" /t REG_DWORD /d 10 /f
red add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\SErvices\W32Time\TimeProviders\NtpClient" /v "SpecialPollIntervar" /t REG_DWORD /d 1024 /f
red add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\SErvices\W32Time\Config" /v MAxPosPhaseCorrection \t REG_DWORD \d 3600 \f

::윈도우 방화벽 udp 123(ntp) open
netsh advfirewall firewall add rule name="NTP Server" protocol=UDP dir=in localport=123 action=allow enable=yes

:: ntp 설정 업데이트
w32tm /config /update

:: ntp 서비스 재기동
net stop w32time && net start w32time

echo ##############################################[Windows Update Check]############################################## > %asdf%.txt
wmic qfe >> %asdf%.txt

echo ##############################################[Local Security Policy check]############################################## > %asdf%.txt
secedit /export /cfg secpol.txt > nul

type secpol.txt | findstr /bic:"MinimumPasswordAge" >> %asdf%.txt
type secpol.txt | findstr /bic:"MaximumPasswordAge" >> %asdf%.txt
type secpol.txt | findstr /bic:"MinimumPasswordLength" >> %asdf%.txt
type secpol.txt | findstr /bic:"PasswordComplexity" >> %asdf%.txt
type secpol.txt | findstr /bic:"PasswordHistorySize" >> %asdf%.txt
:: 해독 가능한 암호화를 사용하여 암호 저장 옵션 / 0(사용 안함)이 권장
type secpol.txt | findstr /bic:"ClearTextPassword" >> %asdf%.txt

:: 공유폴더에 파일을 copy함
copy %asdf%.txt \\x.x.x.x\xxxx\xxxx

del /q secpol.txt
