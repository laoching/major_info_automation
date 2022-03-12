@echo off
setlocal 
chcp 437>nul
set RESULT_FILE=result.txt

echo. W-01 START
echo ========================================== > %RESULT_FILE%
echo [W-01 Administrator 계정명 변경] >> %RESULT_FILE%
set count=0

secedit /export /cfg secpolicy_tmp.txt > nul
type secpolicy_tmp.txt | findstr /bic:"NewAdministratorName" > adminname.txt
for /f "tokens=3" %%a in (adminname.txt) do set ADMIN=%%a

net user %ADMIN% | find /i "Account Active" > status.txt 

type status.txt >> %RESULT_FILE%
for /f "tokens=3" %%a in (status.txt) do set STAT=%%a
if "%STAT%" == "Yes" (
	echo administrator account active >> %RESULT_FILE%
	set /a count+=1
) else (
	echo administrator account non active >> %RESULT_FILE%
)

type secpolicy_tmp.txt | findstr /bic:"EnableAdminAccount" > account.txt
type account.txt >> %RESULT_FILE%
for /f "tokens=1,2 delims==" %%a in (account.txt) do set CONF=%%b
if %CONF% equ 1 (
	echo administrator account active >> %RESULT_FILE%
	set /a count+=1
) else (
	echo administrator account non active >> %RESULT_FILE%
)

if %count% geq 1 (
	if "%ADMIN%" == ""Administrator"" (
		echo %ADMIN% >> %RESULT_FILE%
		echo [W-01] 취약 >> %RESULT_FILE%
	) else (
		echo %ADMIN% >> %RESULT_FILE%
		echo [W-01] 양호 >> %RESULT_FILE%
	)
	goto :END1
) else (
	goto :END
)
:END
echo [W-01] 양호 >> %RESULT_FILE%
:END1
echo. W-01 STOP
echo.
echo. W-04 START
echo ========================================== >> %RESULT_FILE%
echo [ W-04 계정 잠금 임계값 설정 ] >> %RESULT_FILE%
secedit /export /cfg secpolicy_tmp.txt > nul
type secpolicy_tmp.txt | findstr /bic:"LockoutBadCount" > lockout.txt
type lockout.txt >> %RESULT_FILE%
for /f "tokens=1,2 delims==" %%a in (lockout.txt) do set CONF=%%b
if %CONF% LEQ 5 (
	if %CONF% NEQ 0 (
		echo [W-04] 양호 >> %RESULT_FILE%
		echo >> %RESULT_FILE%
	) else (
		echo [W-04] 취약 >> %RESULT_FILE%
		echo >> %RESULT_FILE%
	)
) else (
	echo [W-04] 취약 >> %RESULT_FILE%
	echo >> %RESULT_FILE%
)
echo. W-04 END
echo.
echo. W-55 START
echo ========================================== >> %RESULT_FILE%
echo [W-55 최근 암호 기억] >> %RESULT_FILE%
secedit /export /cfg secpolicy_tmp.txt > nul
type secpolicy_tmp.txt | findstr /bic:"PasswordHistorySize" > history.txt
type history.txt >> %RESULT_FILE%
for /f "tokens=1,2 delims==" %%a in (history.txt) do set CONF=%%b
if %CONF% geq 4 (
	echo [W-55] 양호 >> %RESULT_FILE%
)	else (
	echo [W-55] 취약 >> %RESULT_FILE%
)
echo. W-55 END
echo.
echo. W-60 START
echo ========================================== >> %RESULT_FILE%
echo [W-60 SNMP 서비스 구동 점검] >> %RESULT_FILE%
net start | find /i "SNMP" > nul
if "%errorlevel%" == "1" (
	echo SNMP Service Disable >> %RESULT_FILE%
	echo [W-60] 양호 >> %RESULT_FILE%
) else (
	echo SNMP Service Enable >> %RESULT_FILE%
	echo [W-60] 취약 >> %RESULT_FILE%
)

echo. W-60 END
echo.
echo. W-69 START
echo ========================================== >> %RESULT_FILE%
echo [W-69 정책에 따른 시스템 로깅 설정] >> %RESULT_FILE%
set vulcount69=0
secedit /export /cfg secpolicy_tmp.txt > nul
echo - 감사 정책 전체 설정 >> %RESULT_FILE%
type secpolicy_tmp.txt | findstr /bic:"AuditObjectAccess" >> %RESULT_FILE%
type secpolicy_tmp.txt | findstr /bic:"AuditAccountManage" >> %RESULT_FILE%
type secpolicy_tmp.txt | findstr /bic:"AuditAccountLogon" >> %RESULT_FILE%
type secpolicy_tmp.txt | findstr /bic:"AuditPrivilegeUse" >> %RESULT_FILE%
type secpolicy_tmp.txt | findstr /bic:"AuditDsAccess" >> %RESULT_FILE%
type secpolicy_tmp.txt | findstr /bic:"AuditLogonEvents" >> %RESULT_FILE%
type secpolicy_tmp.txt | findstr /bic:"AuditSystemEvents" >> %RESULT_FILE%
type secpolicy_tmp.txt | findstr /bic:"AuditPolicyChange" >> %RESULT_FILE%
type secpolicy_tmp.txt | findstr /bic:"AuditProcessTracking" >> %RESULT_FILE%

for /f "tokens=1,2 delims==" %%a in ('"type secpolicy_tmp.txt | findstr /bic:"AuditAccountManage""') do set CONF=%%b
if %CONF% EQU 1 (
	set /A vulcount69+=1
)

for /f "tokens=1,2 delims==" %%a in ('"type secpolicy_tmp.txt | findstr /bic:"AuditAccountLogon""') do set CONF=%%b
if %CONF% EQU 1 (
	set /A vulcount69+=1
)

for /f "tokens=1,2 delims==" %%a in ('"type secpolicy_tmp.txt | findstr /bic:"AuditDSAccess""') do set CONF=%%b
if %CONF% EQU 1 (
	set /A vulcount69+=1
)

for /f "tokens=1,2 delims==" %%a in ('"type secpolicy_tmp.txt | findstr /bic:"AuditLogonEvents""') do set CONF=%%b
if %CONF% EQU 3 (
	set /A vulcount69+=1
)

for /f "tokens=1,2 delims==" %%a in ('"type secpolicy_tmp.txt | findstr /bic:"AuditSystemEvents""') do set CONF=%%b
if %CONF% EQU 3 (
	set /A vulcount69+=1
)

for /f "tokens=1,2 delims==" %%a in ('"type secpolicy_tmp.txt | findstr /bic:"AuditPolicyChange""') do set CONF=%%b
if %CONF% EQU 1 (
	set /A vulcount69+=1
)

if %vulcount69% EQU 6 (
	echo [W-69] 양호 >> %RESULT_FILE%
) else (
	echo [W-69] 취약 >> %RESULT_FILE%
)
echo. W-69 END
echo.
echo. W-38 START
echo ========================================== >> %RESULT_FILE%
echo [W-38 화면보호기 설정] >> %RESULT_FILE%
set vulcount38=0

reg query "HKEY_CURRENT_USER\Control Panel\Desktop" | find "ScreenSaveActive" > active.txt
type active.txt >> %RESULT_FILE%
for /f "tokens=3" %%a in (active.txt) do set ACTCONF=%%a
if "%ACTCONF%" == "1" (
	set /a vulcount38=%vulcount38%+1
)
reg query "HKEY_CURRENT_USER\Control Panel\Desktop" | find "ScreenSaverIsSecure" > secure.txt
type secure.txt >> %RESULT_FILE%
for /f "tokens=3" %%a in (secure.txt) do set SECCONF=%%a
if "%SECCONF%" == "1" (
	set /a vulcount38=%vulcount38%+1
)
reg query "HKEY_CURRENT_USER\Control Panel\Desktop" | find "ScreenSaveTimeOut" > timeout.txt
type timeout.txt >> %RESULT_FILE%
for /f "tokens=3" %%a in (timeout.txt) do set TIMECONF=%%a
if "%TIMECONF%" LEQ "600" (
	set /a vulcount38=%vulcount38%+1
)

if "%vulcount38%" EQU "3" (
	echo [W-38] 양호 >> %RESULT_FILE%
) else (
	echo [W-38] 취약 >> %RESULT_FILE%
)

echo. W-38 END
echo ========================================== >> %RESULT_FILE%
del /q secpolicy_tmp.txt
del /q account.txt
del /q status.txt
del /q adminname.txt
del /q lockout.txt
del /q history.txt