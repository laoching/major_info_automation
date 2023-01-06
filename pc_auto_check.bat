@echo off

whoami >> pc_check_result.txt

ipconfig >> pc_check_result.txt

net share >> pc_check_result.txt

for /f "tokens=2 delims=^\" %%a in ('whoami') do set pc_name=%%a
net user %pc_name >> pc_check_result.txt

net start w32time

w32tm /query /configuration >> pc_check_result.txt

wmic qfe >> pc_check_result.txt

secedit /export /cfg secpol.txt > nul

type secpol.txt | findstr /bic:"MinumumPasswordAge" >> pc_check_result.txt
type secpol.txt | findstr /bic:"MaximumPasswordAge" >> pc_check_result.txt
type secpol.txt | findstr /bic:"MinimumPasswordLength" >> pc_check_result.txt
type secpol.txt | findstr /bic:"PasswordComplexity" >> pc_check_result.txt
type secpol.txt | findstr /bic:"PasswordHistorySize" >> pc_check_result.txt
type secpol.txt | findstr /bic:"ClearTextPassword" >> pc_check_result.txt

del /q secpol.txt