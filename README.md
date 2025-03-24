# major_info_automation

# linux_1_7_13_20_24_34.sh
# windows_1_4_55_60_69_38.bat
주요정보통신기반시설 기술적 취약점 분석 평가 방법 상세 가이드를 기반으로 몇 가지 항목에 한해 취약점진단 자동화를 구현하였습니다.
점검 대상은 Windows Server 2012 R2와 CentOS 7 입니다.
두 코드 모두 관리자 권한에서 실행해야 하며, Windows의 경우 'C:\Windows\System32' 경로에 bat 파일을 위치시킨 뒤 실행해야 합니다.

# pc_auto_check.bat
윈도우 환경에서 보안 설정(패스워드 규칙, 변경주기 등)을 확인하는 스크립트입니다.
스크립트 구동 시 텍스트 파일을 도출합니다.

# merge.py
pc_auto_check.bat의 결과물을 엑셀에 정리해주는 파이썬 프로그램입니다.
