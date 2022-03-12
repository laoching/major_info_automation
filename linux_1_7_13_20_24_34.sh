#!/bin/sh

##### root account excute check
if [ "`id | grep \"uid=0\"`" = "" ]; then
    echo "";
    echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=";
    echo "";
    echo "This script must be run as root";
    echo "";
    echo "진단 스크립트는 루트 권한으로 실행해야 합니다.";
    echo "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=";i
    echo "";
    exit 1;
fi
lang_check=`locale -a 2>/dev/null | grep "en_US" | egrep -i "(utf8|utf-8)"`
if [ "$lang_check" = "" ]; then
    lang_check="C"
fi

LANG="$lang_check"
LC_ALL="$lang_check"
LANGUAGE="$lang_check"
export LANG
export LC_ALL
export LANGUAGE

if [ "`command -v netstat 2>/dev/null`" != "" ] || [ "`which netstat 2>/dev/null`" != "" ]; then
    port_cmd="netstat"
else
    port_cmd="ss"
fi

if [ "`command -v systemctl 2>/dev/null`" != "" ] || [ "`which systemctl 2>/dev/null`" != "" ]; then
    systemctl_cmd="systemctl"
fi

RESULT_FILE="result_collect_`date +\"%Y%m%d%H%M\"`.txt"
echo "[Start Script]"
echo "============================== Linux Security Check Script Start =====================" > $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
########################################
# - 주요 정보 통신 기반 시설 | 계정 관리 |U-01 root 계정 원격접속 제한
########################################
echo "[ U-01 ] : Check"
echo "======================= [ U-01 root 계정 원격접속 제한 START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1

echo "1. SSH" >> $RESULT_FILE 2>&1
echo "1-1. SSH Process Check" >> $RESULT_FILE 2>&1
get_ssh_ps=`ps -ef | grep -v "grep" | grep "sshd"`
if [ "$get_ssh_ps" != "" ]; then
    echo "$get_ssh_ps" >> $RESULT_FILE 2>&1
else
    echo "Not Found Process" >> $RESULT_FILE 2>&1
fi
echo "" >> $RESULT_FILE 2>&1

echo "1-2. SSH Service Check" >> $RESULT_FILE 2>&1
if [ "$systemctl_cmd" != "" ]; then
    get_ssh_service=`$systemctl_cmd list-units --type service | egrep '(ssh|sshd)\.service' | sed -e     's/^ *//g' -e 's/^ *//g' | tr -s "\t"`
    if [ "$get_ssh_service" != "" ]; then
        echo "$get_ssh_service" >> $RESULT_FILE 2>&1
    else
        echo "Not Found Service" >> $RESULT_FILE 2>&1
    fi
else
    echo "Not Found Systemctl Command" >> $RESULT_FILE 2>&1
fi
echo "1-3. SSH Port Check" >> $RESULT_FILE 2>&1
if [ "$port_cmd" != "" ]; then
    get_ssh_port=`$port_cmd -na | grep "tcp" | grep "LISTEN" | grep ':22[ \t]'`
    if [ "$get_ssh_port" != "" ]; then
        echo "$get_ssh_port" >> $RESULT_FILE 2>&1
    else
        echo "Not Found Port" >> $RESULT_FILE 2>&1
    fi
else
    echo "Not Found Port Command" >> $RESULT_FILE 2>&1
fi
if [ "$get_ssh_ps" != "" ] || [ "$get_ssh_service" != "" ] || [ "$get_ssh_port" != "" ]; then
    echo "" >> $RESULT_FILE 2>&1
    echo "1-4. SSH Configuration File Check" >> $RESULT_FILE 2>&1
    if [ -f "/etc/ssh/sshd_config" ]; then
        get_ssh_conf=`cat /etc/ssh/sshd_config | egrep -v '^#|^$' | grep "PermitRootLogin"`
        if [ "$get_ssh_conf" != "" ]; then
            echo "/etc/ssh/sshd_config : $get_ssh_conf" >> $RESULT_FILE 2>&1
            get_conf_check=`echo "$get_ssh_conf" | awk '{ print $2 }'`
            if [ "$get_conf_check" = "no" ]; then
                ssh_flag=1
            else
                ssh_flag=0
            fi
        else
            ssh_flag=1
            echo "/etc/ssh/sshd_config : Not Found PermitRootLogin Configuration" >> $RESULT_FILE 2>&    1
        fi
    else
        ssh_flag=2
        echo "Not Found SSH Configuration File" >> $RESULT_FILE 2>&1
    fi
    echo "" >> $RESULT_FILE 2>&1
else
    ssh_flag=1
fi
echo "2. Telnet" >> $RESULT_FILE 2>&1
echo "2-1. Telnet Process Check" >> $RESULT_FILE 2>&1
get_telnet_ps=`ps -ef | grep -v "grep" | grep "telnet"`
if [ "$get_telnet_ps" != "" ]; then
    echo "$get_telnet_ps" >> $RESULT_FILE 2>&1
else
    echo "Not Found Process" >> $RESULT_FILE 2>&1
fi
echo "" >> $RESULT_FILE 2>&1

echo "2-2. Telnet Service Check" >> $RESULT_FILE 2>&1
if [ "$systemctl_cmd" != "" ]; then
    get_telnet_service=`$systemctl_cmd list-units --type service | egrep '(telnet|telnetd)\.service'     | sed -e 's/^ *//g' -e 's/^    *//g' | tr -s " \t"`
    if [ "$get_telnet_service" != "" ]; then
        echo "$get_telnet_service" >> $RESULT_FILE 2>&1
    else
        echo "Not Found Service" >> $RESULT_FILE 2>&1
    fi
else
    echo "Not Found systemctl Command" >> $RESULT_FILE 2>&1
fi
echo "" >> $RESULT_FILE 2>&1

echo "2-3. Telnet Port Check" >> $RESULT_FILE 2>&1
if [ "$port_cmd" != "" ]; then
    get_telnet_port=`$port_cmd -na | grep "tcp" | grep "LISTEN" | grep ':23[ \t]'`
    if [ "$get_telnet_port" != "" ]; then
        echo "$get_telnet_port" >> $RESULT_FILE 2>&1
    else
        echo "Not Found Port" >> $RESULT_FILE 2>&1
    fi
else
    echo "Not Found Port Command" >> $RESULT_FILE 2>&1
fi
if [ "$get_telnet_ps" != "" ] || [ "$get_telnet_service" != "" ] || [ "$get_telnet_port" != "" ]; then
    telnet_flag=0
    echo "" >> $RESULT_FILE 2>&1
    echo "2.4 Telnet Configuration Check" >> $RESULT_FILE 2>&1
    if [ -f "/etc/pam.d/remote" ]; then
        pam_file="/etc/pam.d/remote"
    elif [ -f "/etc/pam.d/login" ]; then
        pam_file="/etc/pam.d/login"
    fi

    if [ "$pam_file" != "" ]; then
        echo "- $pam_file" >> $RESULT_FILE 2>&1
        get_conf=`cat $pam_file | egrep -v '^#|^$' | grep "pam_securetty.so"`
        if [ "$get_conf" != "" ]; then
            echo "$get_conf" >> $RESULT_FILE 2>&1
            if [ -f "/etc/securetty" ]; then
                echo "- /etc/securetty" >> $RESULT_FILE 2>&1
                echo "`cat /etc/securetty`" >> $RESULT_FILE 2>&1
                get_pts=`cat /etc/securetty | egrep -v '^#|^$' | grep "^[ \t]*pts"`
                if [ "$get_pts" = "" ]; then
                    telnet_flag=1
                fi
            else
                echo "Not Found Telnet tty Configuration File" >> $RESULT_FILE 2>&1
            fi
        else
            echo "$pam_file : Not Found pam_securetty.so Configuration" >> $RESULT_FILE 2>&1
        fi
    else
        telnet_flag=2
        echo "Not Found Telnet Pam Configuration File" >> $RESULT_FILE 2>&1
    fi
else
    telnet_flag=1
fi
if [ $ssh_flag -eq 1 ] && [ $telnet_flag -eq 1 ]; then
    echo "결과값 : 양호" >> $RESULT_FILE 2>&1
elif [ $ssh_flag -eq 0 ] || [ $telnet_flag -eq 0 ]; then
    echo "결과값 : 취약" >> $RESULT_FILE 2>&1
elif [ $ssh_flg -eq 2 ] || [ $telnet_flag -eq 2 ]; then
    echo "결과값 : 검토" >> $RESULT_FILE 2>&1
fi
echo "" >> $RESULT_FILE 2>&1
echo "======================== [ U-01 root 계정 원격접속 제한 END ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
echo "[ U-07 ] : Check"
echo "============= [ U-07 /etc/passwd 파일 소유자 및 권한 설정 START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
if [ -f "/etc/passwd" ]; then
    ls -l /etc/passwd >> $RESULT_FILE 2>&1
    permission_val=`stat -c '%a' /etc/passwd`
    owner_val=`stat -c '%U' /etc/passwd`
    owner_perm_val=`echo "$permission_val" | awk '{ print substr($0, 1, 1) }'`
    group_perm_val=`echo "$permission_val" | awk '{ print substr($0, 2, 1) }'`
    other_perm_val=`echo "$permission_val" | awk '{ print substr($0, 3, 1) }'`
    if [ "$owner_perm_val" -le 6 ] && [ "$group_perm_val" -le 4 ] && [ "$other_perm_val" -le 4 ] && [ "$owner_val" = "root" ]; then
        echo "결과값 : 양호" >> $RESULT_FILE 2>&1
    else
        echo "결과값 : 취약" >> $RESULT_FILE 2>&1
    fi
else
    echo "Not Found /etc/passwd file" >> $RESULT_FILE 2>&1
    echo "결과값 : 취약" >> $RESULT_FULE 2>&1
fi
echo "" >> $RESULT_FILE 2>&1
echo "==================== [ U-07 /etc/passwd 파일 소유자 및 권한 설정 END ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
echo "[ U-13 ] : Check"
echo "=============== [ U=13 SUID, SGID 설정 및 권한 설정 START ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
FILES="/sbin/dump /sbin/restore /sbin/unix_chkpwd /usr/bin/newgrp /usr/sbin/traceroute /usr/bin/at /usr/bin/lpq /usr/bin/lpq-lpd /usr/bin/lpr /usr/bin/lpr-lpd /usr/sbin/lpc /usr/sbin/lpc-lpd /usr/bin/lprm /u    sr/bin/lprm-lpd"
count=0
for file_chk in $FILES; do
    if [ -f "$file_chk" ]; then
        perm_chk=`ls -alL $file_chk | awk '{ print $1 }' | grep -i 's'`
        echo "`ls -al $file_chk`" >> $RESULT_FILE 2>&1
        if [ "$perm_chk" != "" ]; then
            count=`expr $count + 1`
        fi
    fi
done
echo "총 취약한 파일 갯수 : $count" >> $RESULT_FILE 2>&1
if [ $count -eq 0 ]; then
    echo "결과값 : 양호" >> $RESULT_FILE 2>&1
else
    echo "결과값 : 취약" >> $RESULT_FILE 2>&1
fi
echo "" >> $RESULT_FILE 2>&1
echo "===================== [ U-13 SUID, SGID 설정 및 권한 설정 END ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
echo "[ U-20 ] : Check"
echo "==================[ U-20 Anonymous FTP 비활성화 START ]" >> $RESULT_FILE 2>&1
FTP=1
vsFTP_flag=0

echo "FTP Process Check" >> $RESULT_FILE 2>&1
get_ps=`ps -ef | grep -v 'grep' | grep 'ftpd' | grep -v 'tftp'`
if [ "$get_ps" != "" ]; then
    echo "$get_ps" >> $RESULT_FILE 2>&1
    if [ "`echo \"$get_ps\" | grep 'vsftp'`" != "" ]; then
        vsftp_flag=1
    fi
else
    echo "Not Found Process" >> $RESULT_FILE 2>&1
fi
echo "" >> $RESULT_FILE 2>&1
echo "FTP Service Check" >> $RESULT_FILE 2>&1
if [ "$systemctl_cmd" != "" ]; then
    get_service=`$systemctl_cmd list-units --type service | grep 'ftpd\.service' | sed -e 's/^ *//g' -e 's/^    *//g' | tr -s " \t"`
    if [ "$get_service" != "" ]; then
        echo "$get_service" >> $RESULT_FILE 2>&1
    else
        echo "Not Found Service" >> $RESULT_FILE 2>&1
    fi
else
    echo "Not Found systemctl Command" >> $RESULT_FILE 2>&1
fi
echo "" >> $RESULT_FILE 2>&1

echo "FTP Port Check" >> $RESULT_FILE 2>&1
if [ "$port_cmd" != "" ]; then
    get_port=`$port_cmd -na | grep "tcp" | grep "LISTEN" | grep ':21[ \t]'`
    if [ "$get_port" != "" ]; then
        echo "$get_port" >> $RESULT_FILE 2>&1
    else
        echo "Not Found Port" >> $RESULT_FILE 2>&1
    fi
else
    echo "Not Found Port Command" >> $RESULT_FILE 2>&1
fi
echo "" >> $RESULT_FILE 2>&1
if [ "$get_ps" != "" ] || [ "$get_service" != "" ] || [ "$get_port" != "" ]; then
    if [ $vsftp_flgd -eq 0 ]; then
        if [ -f "/etc/passwd" ]; then
            user_chk=`cat /etc/passwd | grep ftp`
            if [ "$user_chk" != "" ]; then
                FTP=0
            fi
        fi
    else
        if [ -f "/etc/vsftpd/vsftpd.conf" ]; then
            conf_chk=`cat "/etc/vsftpd/vsfptd.conf" | grep -v '^#' | grep 'anonymous_enable'`
        elif [ -f "/etc/vsftpd.conf" ]; then
            conf_chk=`cat "/etc/vsftpd.conf" | grep -v '^#' | grep 'anonymous_enable'`
        fi
        if [ "$conf_chk" != "" ]; then
            conf_chk_tmp=`echo "$conf_chk" | awk -F"=" '{ print $2 }' | grep -i 'no'`
            if [ "$conf_chk_tmp" = "" ]; then
                FTP=0
            fi
        fi
    fi
fi
if [ $FTP -eq 1 ]; then
    echo "결과값 : 양호" >> $RESULT_FILE 2>&1
else
    echo "결과값 : 취약" >> $RESULT_FILE 2>&1
fi
echo "" >> $RESULT_FILE 2>&1
echo "=====================[U-20 Anonymous FTP 비활성화 END]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
echo "[ U-24 ] : Check"
echo "============= [ U -24 NFS 서비스 비활성화 START ]" >> $RESULT_FILE 2>&1

get_ps=`ps -ef | grep -v 'grep' | egrep '\[nfsd\]|\[lockd\]|\[statd\]'`
get_rpcinfo=`rpcinfo -p | egrep 'nfs|nlockmgr|status'`

if [ "$get_ps" = "" ]; then
    echo "Not Found NFS Process" >> $RESULT_FILE 2>&1
else
    echo "$get_ps" >> $RESULT_FILE 2>&1
fi

if [ "$get_rpcinfo" = "" ]; then
    echo "Not Found NFS rpcinfo" >> $RESULT_FILE 2>&1
else
    echo "$get_rpcinfo" >> $RESULT_FILE 2>&1
fi

if [ "$get_ps" != "" -o "$get_rpcinfo" != "" ]; then
    echo "결과값 : 취약" >> $RESULT_FILE 2>&1
else
    echo "결과값 : 양호" >> $RESULT_FILE 2>&1
fi

echo "" >> $RESULT_FILE 2>&1
echo "================== [ U-24 NFS 서비스 비활성화 END ]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
################################################################################################
# - 주요 정보 통신 기반 시설 | 서비스 관리 | U-34 DNS Zone Transfer 설정
################################################################################################
echo "[ U-34 ] : Check"
echo "====================== [U-34 DNS Zone Transfer 설정 START]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1
DNS=1
echo "DNS Process Check" >> $RESULT_FILE 2>&1
get_ps=`ps -ef | grep -v 'grep' | grep 'named'`
if [ "$get_ps" != "" ]; then
    echo "$get_ps" >> $RESULT_FILE 2>&1
else
    echo "Not Found DNS Process" >> $RESULT_FILE 2>&1
fi
echo "" >> $RESULT_FILE 2>&1

echo "DNS Service Check" >> $RESULT_FILE 2>&1
if [ "$systemctl_cmd" != "" ]; then
    get_service=`$systemctl_cmd list-units --type service | grep 'named\.service' | sed -e 's/^ *//g' -e 's/^   *//g' | tr -s " \t"`
    if [ "$get_service" != "" ]; then
        echo "$get_service" >> $RESULT_FILE 2>&1
    else
        echo "Not Found Service" >> $RESULT_FILE 2>&1
    fi
else
    echo "Not Found systemctl Command" >> $RESULT_FILE 2>&1
fi
echo "" >> $RESULT_FILE 2>&1

if [ "$get_ps" != "" ] || [ "$get_service" != "" ]; then
    echo "Allow-transfer Configuration Check" >> $RESULT_FILE 2>&1
    if [ -f "/etc/named.conf" ]; then
        first=`cat /etc/named.conf | sed -e 's/^ *//g' -e 's/^    *//g' | egrep -v '^$|^//|^#'`
        second=`echo "$first" | awk -F"\n" 'BEGIN{count=0} { for(i=1;i<=NF;i++) { if($i ~ /\/\*/) count=1; if(count == 0) print $i; if($i ~ /\*\//) count=0; }}'`
        result=`echo "$second" | awk 'BEGIN{count=0} { for(i=1;i<=NF;i++)  { if($i ~ /allow-transfer/) count=1; if(count==1) printf "%s ", $i; if(count==1 && $i ~ /}/) { count=0; printf "\n" }}}'`
        if [ "$result" != "" ]; then
            echo "$result" >> $RESULT_FILE 2>&1
        else
            echo "Not Found allow-transfer Configuration" >> $RESULT_FILE 2>&1
            DNS=0
        fi
        if [ "`echo \"$result\" | grep \"any;\"`" != "" ]; then
            DNS=0
        fi
    else
        echo "Not Found named.conf File" >> $RESULT_FILE 2>&1
    fi
fi

if [ $DNS -eq 1 ]; then
    echo "결과값 : 양호" >> $RESULT_FILE 2>&1
else
    echo "결과값 : 취약" >> $RESULT_FILE 2>&1
fi
echo "" >> $RESULT_FILE 2>&1
echo "====================== [U-34 DNS Zone Transfer 설정 END]" >> $RESULT_FILE 2>&1
echo "" >> $RESULT_FILE 2>&1