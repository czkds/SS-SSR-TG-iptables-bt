#!/bin/env bash
## Author: SuperManito
## Modified: 2021-09-09
## License: GPL-2.0
## Repository: https://github.com/SuperManito/LinuxMirrors
##             https://gitee.com/SuperManito/LinuxMirrors

function AuthorSignature() {
    if [ ${SYSTEM_FACTIONS} = ${SYSTEM_DEBIAN} ]; then
        apt-get install -y figlet toilet >/dev/null 2>&1
    elif [ ${SYSTEM_FACTIONS} = ${SYSTEM_REDHAT} ]; then
        yum install -y figlet toilet >/dev/null 2>&1
    fi
    if [ $? -eq 0 ]; then
        echo -e "\n$(toilet -f slant -F border --gay SuperManito)\n"
    else
        echo -e '\n\033[35m    _____                       __  ___            _ __       \033[0m'
        echo -e '\033[31m   / ___/__  ______  ___  _____/  |/  /___ _____  (_) /_____  \033[0m'
        echo -e '\033[33m   \__ \/ / / / __ \/ _ \/ ___/ /|_/ / __ `/ __ \/ / __/ __ \ \033[0m'
        echo -e '\033[32m  ___/ / /_/ / /_/ /  __/ /  / /  / / /_/ / / / / / /_/ /_/ / \033[0m'
        echo -e '\033[36m /____/\__,_/ .___/\___/_/  /_/  /_/\__,_/_/ /_/_/\__/\____/  \033[0m'
        echo -e '\033[34m           /_/                                                \033[0m\n'
    fi
}

## 定义系统判定变量
DebianRelease=lsb_release
Arch=$(uname -m)
SYSTEM_DEBIAN="Debian"
SYSTEM_UBUNTU="Ubuntu"
SYSTEM_KALI="Kali"
SYSTEM_REDHAT="RedHat"
SYSTEM_RHEL="RedHat"
SYSTEM_CENTOS="CentOS"
SYSTEM_FEDORA="Fedora"

## 定义目录和文件
LinuxRelease=/etc/os-release
RedHatRelease=/etc/redhat-release
DebianSourceList=/etc/apt/sources.list
DebianSourceListBackup=/etc/apt/sources.list.bak
DebianExtendListDir=/etc/apt/sources.list.d
DebianExtendListDirBackup=/etc/apt/sources.list.d.bak
RedHatReposDir=/etc/yum.repos.d
RedHatReposDirBackup=/etc/yum.repos.d.bak
SelinuxConfig=/etc/selinux/config

## 组合函数
function Combin_Function() {
    PermissionJudgment && clear
    EnvJudgment
    ChooseMirrors
    BackupMirrors
    RemoveOldMirrorsFiles
    ChangeMirrors
    UpgradeSoftware
    AuthorSignature
}

## 系统判定变量
function EnvJudgment() {
    ## 判定当前系统基于 Debian or RedHat
    if [ -f $RedHatRelease ]; then
        SYSTEM_FACTIONS=${SYSTEM_REDHAT}
    else
        SYSTEM_FACTIONS=${SYSTEM_DEBIAN}
    fi
    ## 定义系统名称
    SYSTEM_NAME=$(cat $LinuxRelease | grep -E "^NAME" | awk -F '\"' '{print$2}')
    ## 定义系统版本号
    SYSTEM_VERSION_NUMBER=$(cat $LinuxRelease | grep -E "VERSION_ID" | awk -F '\"' '{print$2}')
    ## 判定系统名称、版本、版本号
    case ${SYSTEM_FACTIONS} in
    Debian)
        SYSTEM_JUDGMENT=$(${DebianRelease} -is)
        SYSTEM_VERSION=$(${DebianRelease} -cs)
        ;;
    RedHat)
        SYSTEM_JUDGMENT=$(cat $RedHatRelease | sed 's/ //g' | cut -c1-6)
        if [[ ${SYSTEM_JUDGMENT} = ${SYSTEM_CENTOS} || ${SYSTEM_JUDGMENT} = ${SYSTEM_RHEL} ]]; then
            CENTOS_VERSION=$(echo ${SYSTEM_VERSION_NUMBER} | cut -c1)
        else
            CENTOS_VERSION=""
        fi
        ;;
    esac
    ## 判定系统处理器架构
    case $Arch in
    x86_64)
        SYSTEM_ARCH=x86_64
        ;;
    aarch64)
        SYSTEM_ARCH=ARM64
        ;;
    armv7l)
        SYSTEM_ARCH=ARMv7
        ;;
    armv6l)
        SYSTEM_ARCH=ARMv6
        ;;
    i686)
        SYSTEM_ARCH=x86_32
        ;;
    *)
        SYSTEM_ARCH=$Arch
        ;;
    esac
    ## 定义软件源分支名称
    if [ ${SYSTEM_JUDGMENT} = ${SYSTEM_UBUNTU} ]; then
        if [ ${Arch} = "x86_64" ] || [ ${Arch} = "*i?86*" ]; then
            SOURCE_BRANCH=${SYSTEM_JUDGMENT,,}
        else
            SOURCE_BRANCH=ubuntu-ports
        fi
    elif [ ${SYSTEM_JUDGMENT} = ${SYSTEM_RHEL} ]; then
        SOURCE_BRANCH="centos"
    else
        SOURCE_BRANCH=${SYSTEM_JUDGMENT,,}
    fi
    ## 定义软件源同步/更新文字
    case ${SYSTEM_FACTIONS} in
    Debian)
        SYNC_TXT="更新"
        ;;
    RedHat)
        SYNC_TXT="同步"
        ;;
    esac
}

## 环境判定：
function PermissionJudgment() {
    ## 权限判定：
    if [ $UID -ne 0 ]; then
        echo -e '\033[31m -------- Permission no enough, please use user ROOT! ------------ \033[0m'
        exit
    fi
}

## 关闭 防火墙 和 SELINUX
function TurnOffFirewall() {
    systemctl status firewalld | grep running -q
    if [ $? -eq 0 ]; then
        CHOICE_C=$(echo -e '\n\033[34m└ 是否关闭防火墙和 SELINUX [ Y/n ]：\033[0m')
        read -p "${CHOICE_C}" INPUT
        [ -z ${INPUT} ] && INPUT=Y
        case $INPUT in
        [Yy]*)
            systemctl disable --now firewalld >/dev/null 2>&1
            [ -s $SelinuxConfig ] && sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" $SelinuxConfig && setenforce 0 >/dev/null 2>&1
            ;;
        [Nn]*) ;;
        *)
            echo -e '\n\033[33m------------ 输入错误，默认不关闭 ------------\033[0m'
            ;;
        esac
    fi
}

## 备份原有源
function BackupMirrors() {
    if [ ${SYSTEM_FACTIONS} = ${SYSTEM_DEBIAN} ]; then
        ## 判断 /etc/apt/sources.list.d 目录下是否存在文件
        [ -d $DebianExtendListDir ] && ls $DebianExtendListDir | grep *.list -q
        VERIFICATION_FILES=$?
        ## 判断 /etc/apt/sources.list.d.bak 目录下是否存在文件
        [ -d $DebianExtendListDirBackup ] && ls $DebianExtendListDirBackup | grep *.list -q
        VERIFICATION_BACKUPFILES=$?
    elif [ ${SYSTEM_FACTIONS} = ${SYSTEM_REDHAT} ]; then
        ## 判断 /etc/yum.repos.d 目录下是否存在文件
        [ -d $RedHatReposDir ] && ls $RedHatReposDir | grep repo -q
        VERIFICATION_FILES=$?
        ## 判断 /etc/yum.repos.d.bak 目录下是否存在文件
        [ -d $RedHatReposDirBackup ] && ls $RedHatReposDirBackup | grep repo -q
        VERIFICATION_BACKUPFILES=$?
    fi

    if [ ${SYSTEM_FACTIONS} = ${SYSTEM_DEBIAN} ]; then
        ## /etc/apt/sources.list
        if [ -s $DebianSourceList ]; then
            if [ -s $DebianSourceListBackup ]; then
                CHOICE_BACKUP1=$(echo -e "\n\033[34m└ 检测到系统存在已备份的 list 源文件，是否覆盖备份 [ Y/n ]：\033[0m")
                read -p "${CHOICE_BACKUP1}" INPUT
                [ -z ${INPUT} ] && INPUT=Y
                case $INPUT in
                [Yy]*)
                    echo -e ''
                    cp -rf $DebianSourceList $DebianSourceListBackup >/dev/null 2>&1
                    ;;
                [Nn]*)
                    echo -e ''
                    ;;
                *)
                    echo -e '\n\033[33m------------ 输入错误，默认不覆盖 ------------\033[0m\n'
                    ;;
                esac
            else
                cp -rf $DebianSourceList $DebianSourceListBackup >/dev/null 2>&1
                echo -e "\n\033[34m└ 已备份原有 list 源文件至 $DebianSourceListBackup ... \033[0m\n"
                sleep 1s
            fi
        else
            [ -f $DebianSourceList ] || touch $DebianSourceList
            echo -e ''
        fi

        ## /etc/apt/sources.list.d
        if [ -d $DebianExtendListDir ] && [ ${VERIFICATION_FILES} -eq 0 ]; then
            if [ -d $DebianExtendListDirBackup ] && [ ${VERIFICATION_BACKUPFILES} -eq 0 ]; then
                CHOICE_BACKUP2=$(echo -e "\n\033[34m└ 检测到系统存在已备份的 list 第三方源文件，是否覆盖备份 [ Y/n ]：\033[0m")
                read -p "${CHOICE_BACKUP2}" INPUT
                [ -z ${INPUT} ] && INPUT=Y
                case $INPUT in
                [Yy]*)
                    cp -rf $DebianExtendListDir/* $DebianExtendListDirBackup >/dev/null 2>&1
                    ;;
                [Nn]*)
                    echo ''
                    ;;
                *)
                    echo -e '\n\033[33m------------ 输入错误，默认不覆盖 ------------\033[0m\n'
                    ;;
                esac
            else
                [ -d $DebianExtendListDirBackup ] || mkdir -p $DebianExtendListDirBackup
                cp -rf $DebianExtendListDir/* $DebianExtendListDirBackup >/dev/null 2>&1
                echo -e "\033[34m└ 已备份原有 list 第三方源文件至 $DebianExtendListDirBackup 目录... \033[0m\n"
                sleep 1s
            fi
        fi
    elif [ ${SYSTEM_FACTIONS} = ${SYSTEM_REDHAT} ]; then
        ## /etc/yum.repos.d
        if [ ${VERIFICATION_FILES} -eq 0 ]; then
            if [ -d $RedHatReposDirBackup ] && [ ${VERIFICATION_BACKUPFILES} -eq 0 ]; then
                CHOICE_BACKUP3=$(echo -e "\n\033[34m└ 检测到系统存在已备份的 repo 源文件，是否覆盖备份 [ Y/n ]：\033[0m")
                read -p "${CHOICE_BACKUP3}" INPUT
                [ -z ${INPUT} ] && INPUT=Y
                case $INPUT in
                [Yy]*)
                    cp -rf $RedHatReposDir/* $RedHatReposDirBackup >/dev/null 2>&1
                    echo -e ''
                    ;;
                [Nn]*) ;;
                *)
                    echo -e '\n\033[33m------------ 输入错误，默认不覆盖 ------------\033[0m\n'
                    ;;
                esac
            else
                [ -d $RedHatReposDirBackup ] || mkdir -p $RedHatReposDirBackup
                cp -rf $RedHatReposDir/* $RedHatReposDirBackup >/dev/null 2>&1
                echo -e "\n\033[34m└ 已备份原有 repo 源文件至 $RedHatReposDirBackup 目录... \033[0m\n"
                sleep 1s
            fi
        else
            [ -d $RedHatReposDir ] || mkdir -p $RedHatReposDir
        fi
    fi
}

## 删除原有源
function RemoveOldMirrorsFiles() {
    if [ ${SYSTEM_FACTIONS} = ${SYSTEM_DEBIAN} ]; then
        [ -f $DebianSourceList ] && sed -i '1,$d' $DebianSourceList
    elif [ ${SYSTEM_FACTIONS} = ${SYSTEM_REDHAT} ]; then
        if [ -d $RedHatReposDir ]; then
            if [ -f $RedHatReposDir/epel.repo ]; then
                ls $RedHatReposDir/ | egrep -v epel | xargs rm -rf
            else
                rm -rf $RedHatReposDir/*
            fi
        fi
    fi
}

## 更换国内源
function ChangeMirrors() {
    if [ ${SYSTEM_FACTIONS} = ${SYSTEM_DEBIAN} ]; then
        DebianMirrors
    elif [ ${SYSTEM_FACTIONS} = ${SYSTEM_REDHAT} ]; then
        RedHatMirrors
        yum clean all >/dev/null 2>&1
    fi
    echo -e "\033[32m------------ 开始${SYNC_TXT}软件源 ------------\033[0m\n"
    case ${SYSTEM_FACTIONS} in
    Debian)
        apt-get update
        ;;
    RedHat)
        yum makecache
        ;;
    esac
    VERIFICATION_SOURCESYNC=$?
    if [ ${VERIFICATION_SOURCESYNC} -eq 0 ]; then
        echo -e "\n\033[32m------------ ${SYNC_TXT}软件源结束 ------------\033[0m"
    else
        echo -e "\n\033[31m------------ 软件源${SYNC_TXT}失败，请重新执行脚本 ------------\033[0m\n\n如果仍然${SYNC_TXT}失败那么可能由以下原因导致\n1. 网络问题：例如网络异常、网络间歇式中断、由地区影响的网络因素等\n2. 软件源问题：所选镜像站正在维护或者不支持你的操作系统\n"
        exit
    fi
}

## 更新软件包
function UpgradeSoftware() {
    CHOICE_B=$(echo -e '\n\033[34m└ 是否更新软件包 [ Y/n ]：\033[0m')
    read -p "${CHOICE_B}" INPUT
    [ -z ${INPUT} ] && INPUT=Y
    case $INPUT in
    [Yy]*)
        echo -e ''
        case ${SYSTEM_FACTIONS} in
        Debian)
            apt-get upgrade -y
            ;;
        RedHat)
            yum update -y
            ;;
        esac
        CHOICE_C=$(echo -e '\n\033[34m└ 是否清理已下载的软件包缓存 [ Y/n ]：\033[0m')
        read -p "${CHOICE_C}" INPUT
        [ -z ${INPUT} ] && INPUT=Y
        case $INPUT in
        [Yy]*)
            if [ ${SYSTEM_FACTIONS} = ${SYSTEM_DEBIAN} ]; then
                apt-get autoremove -y >/dev/null 2>&1
                apt-get clean >/dev/null 2>&1
            elif [ ${SYSTEM_FACTIONS} = ${SYSTEM_REDHAT} ]; then
                yum autoremove -y >/dev/null 2>&1
                yum clean packages -y >/dev/null 2>&1
            fi

            echo -e '\n[OK] 清理完毕'
            ;;
        [Nn]*) ;;
        *)
            echo -e '\n\033[33m------------ 输入错误，默认不清理 ------------\033[0m'
            ;;
        esac
        ;;
    [Nn]*) ;;
    *)
        echo -e '\n\033[33m------------ 输入错误，默认不更新 ------------\033[0m'
        ;;
    esac
    echo -e '\n\033[32m------------ 软件源更换完毕 ------------\033[0m'
}

## 更换基于 Debian 系 Linux 发行版的国内源
function DebianMirrors() {
    ## 修改国内源
    if [ ${SYSTEM_JUDGMENT} = ${SYSTEM_UBUNTU} ]; then
        echo "## 默认注释了源码仓库，如有需要可自行取消注释" >>$DebianSourceList
        echo "deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION} main restricted universe multiverse" >>$DebianSourceList
        echo "# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION} main restricted universe multiverse" >>$DebianSourceList
        echo "deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-security main restricted universe multiverse" >>$DebianSourceList
        echo "# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-security main restricted universe multiverse" >>$DebianSourceList
        echo "deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-updates main restricted universe multiverse" >>$DebianSourceList
        echo "# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-updates main restricted universe multiverse" >>$DebianSourceList
        echo "deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-backports main restricted universe multiverse" >>$DebianSourceList
        echo "# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-backports main restricted universe multiverse" >>$DebianSourceList
        echo '' >>$DebianSourceList
        echo "## 预发布软件源，不建议启用" >>$DebianSourceList
        echo "# deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-proposed main restricted universe multiverse" >>$DebianSourceList
        echo "# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-proposed main restricted universe multiverse" >>$DebianSourceList
    elif [ ${SYSTEM_JUDGMENT} = ${SYSTEM_DEBIAN} ]; then
        echo "## 默认注释了源码仓库，如有需要可自行取消注释" >>$DebianSourceList
        echo "deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION} main contrib non-free" >>$DebianSourceList
        echo "# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION} main contrib non-free" >>$DebianSourceList
        echo "deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-updates main contrib non-free" >>$DebianSourceList
        echo "# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-updates main contrib non-free" >>$DebianSourceList
        echo "deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-backports main contrib non-free" >>$DebianSourceList
        echo "# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-backports main contrib non-free" >>$DebianSourceList
        echo '' >>$DebianSourceList
        echo "## 预发布软件源，不建议启用" >>$DebianSourceList
        echo "# deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH}-security ${SYSTEM_VERSION}/updates main contrib non-free" >>$DebianSourceList
        echo "# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH}-security ${SYSTEM_VERSION}/updates main contrib non-free" >>$DebianSourceList
    elif [ ${SYSTEM_JUDGMENT} = ${SYSTEM_KALI} ]; then
        echo "deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION} main non-free contrib" >>$DebianSourceList
        echo "deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION} main non-free contrib" >>$DebianSourceList
    fi
}

## 更换基于 RedHat 系 Linux 发行版的国内源
function RedHatMirrors() {
    ## 生成基于 RedHat 发行版和及其衍生发行版的官方 repo 源文件
    ## 由于 RedHat 系 Linux 源文件各不相同且不易判断，故通过在删除原有源后重新创建官方源的方式更换国内源
    cd $RedHatReposDir
    case ${SYSTEM_JUDGMENT} in
    RedHat | CentOS)
        CentOSReposCreate
        ;;
    Fedora)
        FedoraReposCreate
        ;;
    esac
    ## 修改国内源
    if [ ${SYSTEM_JUDGMENT} = ${SYSTEM_CENTOS} -o ${SYSTEM_JUDGMENT} = ${SYSTEM_RHEL} ]; then
        sed -i 's|^mirrorlist=|#mirrorlist=|g' $RedHatReposDir/${SYSTEM_CENTOS}-*
        [ ${CENTOS_VERSION} -eq "8" ] && sed -i 's|^#baseurl=http://mirror.centos.org/$contentdir|baseurl=http://mirror.centos.org/centos|g' $RedHatReposDir/${SYSTEM_CENTOS}-*
        sed -i "s|^#baseurl=http|baseurl=${WEB_PROTOCOL}|g" $RedHatReposDir/${SYSTEM_CENTOS}-*
        sed -i "s|mirror.centos.org|${SOURCE}|g" $RedHatReposDir/${SYSTEM_CENTOS}-*
        ## Red Hat Enterprise Linux 修改版本号
        [ ${SYSTEM_JUDGMENT} = ${SYSTEM_RHEL} ] && sed -i "s/\$releasever/${CENTOS_VERSION}/g" ${SYSTEM_CENTOS}-*
        ## 安装/更换基于 CentOS 的 EPEL 扩展国内源
        [ ${EPEL_INSTALL} = "True" ] && EPELMirrors
    elif [ ${SYSTEM_JUDGMENT} = ${SYSTEM_FEDORA} ]; then
        sed -i 's|^metalink=|#metalink=|g' \
            $RedHatReposDir/${SOURCE_BRANCH}.repo \
            $RedHatReposDir/${SOURCE_BRANCH}-updates.repo \
            $RedHatReposDir/${SOURCE_BRANCH}-modular.repo \
            $RedHatReposDir/${SOURCE_BRANCH}-updates-modular.repo \
            $RedHatReposDir/${SOURCE_BRANCH}-updates-testing.repo \
            $RedHatReposDir/${SOURCE_BRANCH}-updates-testing-modular.repo
        sed -i "s|^#baseurl=http|baseurl=${WEB_PROTOCOL}|g" $RedHatReposDir/fedora*
        sed -i "s|download.example/pub/fedora/linux|${SOURCE}/fedora|g" \
            $RedHatReposDir/fedora.repo \
            $RedHatReposDir/${SOURCE_BRANCH}-updates.repo \
            $RedHatReposDir/${SOURCE_BRANCH}-modular.repo \
            $RedHatReposDir/${SOURCE_BRANCH}-updates-modular.repo \
            $RedHatReposDir/${SOURCE_BRANCH}-updates-testing.repo \
            $RedHatReposDir/${SOURCE_BRANCH}-updates-testing-modular.repo
    fi
}

## 安装/更换基于 RHEL/CentOS 的 EPEL (Extra Packages for Enterprise Linux) 扩展国内源
function EPELMirrors() {
    ## 安装 EPEL 软件包
    if [ ${VERIFICATION_EPEL} -ne 0 ]; then
        echo -e '\033[32m------------ 安装 epel-release 软件包 ------------\033[0m\n'
        yum install -y https://mirrors.aliyun.com/epel/epel-release-latest-${CENTOS_VERSION}.noarch.rpm
    fi
    ## 删除原有 EPEL 扩展 repo 源文件
    [ ${VERIFICATION_EPELFILES} -eq 0 ] && rm -rf $RedHatReposDir/epel*
    [ ${VERIFICATION_EPELBACKUPFILES} -eq 0 ] && rm -rf $RedHatReposDirBackup/epel*
    ## 生成官方 EPEL 扩展 repo 源文件
    EPELReposCreate
    ## 更换国内源
    sed -i 's|^metalink=|#metalink=|g' $RedHatReposDir/epel*
    case ${CENTOS_VERSION} in
    8)
        sed -i "s|^#baseurl=https|baseurl=${WEB_PROTOCOL}|g" $RedHatReposDir/epel*
        ;;
    7)
        sed -i "s|^#baseurl=http|baseurl=${WEB_PROTOCOL}|g" $RedHatReposDir/epel*
        ;;
    esac
    sed -i "s|download.fedoraproject.org/pub|${SOURCE}|g" $RedHatReposDir/epel*
    rm -rf $RedHatReposDir/epel*rpmnew
    echo ''
}

## 选择国内源
function ChooseMirrors() {
    echo -e '+---------------------------------------------------+'
    echo -e '|                                                   |'
    echo -e '|   =============================================   |'
    echo -e '|                                                   |'
    echo -e '|       欢迎使用 Linux 一键更换国内软件源脚本       |'
    echo -e '|                                                   |'
    echo -e '|   =============================================   |'
    echo -e '|                                                   |'
    echo -e '+---------------------------------------------------+'
    echo -e ''
    echo -e '#####################################################'
    echo -e ''
    echo -e '            提供以下国内软件源可供选择：'
    echo -e ''
    echo -e '#####################################################'
    echo -e ''
    echo -e ' ❖   阿里云              1)'
    echo -e ' ❖   腾讯云              2)'
    echo -e ' ❖   华为云              3)'
    echo -e ' ❖   网易                4)'
    echo -e ' ❖   搜狐                5)'
    echo -e ' ❖   清华大学            6)'
    echo -e ' ❖   浙江大学            7)'
    echo -e ' ❖   重庆大学            8)'
    echo -e ' ❖   兰州大学            9)'
    echo -e ' ❖   上海交通大学       10)'
    echo -e ' ❖   中国科学技术大学   11)'
    echo -e ''
    echo -e '#####################################################'
    echo -e ''
    echo -e "            运行环境  ${SYSTEM_NAME} ${SYSTEM_VERSION_NUMBER} ${SYSTEM_ARCH}"
    echo -e "            系统时间  $(date "+%Y-%m-%d %H:%M:%S")"
    echo -e ''
    echo -e '#####################################################'
    CHOICE_A=$(echo -e '\n\033[34m└ 请选择并输入你想使用的软件源 [ 1-11 ]：\033[0m')
    read -p "${CHOICE_A}" INPUT
    case $INPUT in
    1)
        SOURCE="mirrors.aliyun.com"
        ;;
    2)
        SOURCE="mirrors.cloud.tencent.com"
        ;;
    3)
        SOURCE="repo.huaweicloud.com"
        ;;
    4)
        SOURCE="mirrors.163.com"
        ;;
    5)
        SOURCE="mirrors.sohu.com"
        ;;
    6)
        SOURCE="mirrors.tuna.tsinghua.edu.cn"
        ;;
    7)
        SOURCE="mirrors.zju.edu.cn"
        ;;
    8)
        SOURCE="mirrors.cqu.edu.cn"
        ;;
    9)
        SOURCE="mirror.lzu.edu.cn"
        ;;
    10)
        SOURCE="ftp.sjtu.edu.cn"
        ;;
    11)
        SOURCE="mirrors.ustc.edu.cn"
        ;;
    *)
        SOURCE="mirrors.aliyun.com"
        echo -e '\n\033[33m------------ 输入错误，将默认使用阿里云作为国内源 ------------\033[0m'
        sleep 1s
        ;;
    esac

    ## 更换基于 RHEL/CentOS 的 EPEL (Extra Packages for Enterprise Linux) 扩展国内源
    if [ ${SYSTEM_JUDGMENT} = ${SYSTEM_CENTOS} -o ${SYSTEM_JUDGMENT} = ${SYSTEM_RHEL} ]; then
        ## 判断是否已安装 EPEL 软件包
        rpm -qa | grep epel-release -q
        VERIFICATION_EPEL=$?
        ## 判断 /etc/yum.repos.d 目录下是否存在 epel 扩展 repo 源文件
        [ -d $RedHatReposDir ] && ls $RedHatReposDir | grep epel -q
        VERIFICATION_EPELFILES=$?
        ## 判断 /etc/yum.repos.d.bak 目录下是否存在 epel 扩展 repo 源文件
        [ -d $RedHatReposDirBackup ] && ls $RedHatReposDirBackup | grep epel -q
        VERIFICATION_EPELBACKUPFILES=$?

        if [ ${VERIFICATION_EPEL} -eq 0 ]; then
            CHOICE_D=$(echo -e '\n\033[34m└ 检测到系统已安装 EPEL 扩展源，是否替换/覆盖为国内源 [ Y/n ]：\033[0m')
        else
            CHOICE_D=$(echo -e '\n\033[34m└ 是否安装 EPEL 扩展源 [ Y/n ]：\033[0m')
        fi
        read -p "${CHOICE_D}" INPUT
        [ -z ${INPUT} ] && INPUT=Y
        case $INPUT in
        [Yy]*)
            EPEL_INSTALL="True"
            ;;
        [Nn]*)
            EPEL_INSTALL="False"
            ;;
        *)
            echo -e '\n\033[33m------------ 输入错误，默认不更换 ------------\033[0m'
            EPEL_INSTALL="False"
            ;;
        esac
    fi

    ## 选择同步软件源所使用的 WEB 协议（ HTTP：80 端口，HTTPS：443 端口）
    CHOICE_E=$(echo -e "\n\033[34m└ 软件源是否使用 HTTP 协议 [ Y/n ]：\033[0m")
    read -p "${CHOICE_E}" INPUT
    [ -z ${INPUT} ] && INPUT=Y
    case $INPUT in
    [Yy]*)
        WEB_PROTOCOL="http"
        ;;
    [Nn]*)
        WEB_PROTOCOL="https"
        ;;
    *)
        echo -e "\n\033[33m------------ 输入错误，默认使用 HTTPS 协议 ------------\033[0m"
        WEB_PROTOCOL="https"
        ;;
    esac

    ## 关闭 防火墙 和 SELINUX
    [ ${SYSTEM_FACTIONS} = ${SYSTEM_REDHAT} ] && TurnOffFirewall
}

## 生成 CentOS 官方 repo 源文件
function CentOSReposCreate() {
    if [ ${CENTOS_VERSION} -eq "8" ]; then
        CentOS8_RepoFiles='CentOS-Linux-AppStream.repo CentOS-Linux-BaseOS.repo CentOS-Linux-ContinuousRelease.repo CentOS-Linux-Debuginfo.repo CentOS-Linux-Devel.repo CentOS-Linux-Extras.repo CentOS-Linux-FastTrack.repo CentOS-Linux-HighAvailability.repo CentOS-Linux-Media.repo CentOS-Linux-Plus.repo CentOS-Linux-PowerTools.repo CentOS-Linux-Sources.repo'
        for REPOS in $CentOS8_RepoFiles; do
            touch $REPOS
        done
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-AppStream.repo <<\EOF
# CentOS-Linux-AppStream.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[appstream]
name=CentOS Linux $releasever - AppStream
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=AppStream&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/AppStream/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-BaseOS.repo <<\EOF
# CentOS-Linux-BaseOS.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[baseos]
name=CentOS Linux $releasever - BaseOS
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=BaseOS&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-ContinuousRelease.repo <<\EOF
# CentOS-Linux-ContinuousRelease.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.
#
# The Continuous Release (CR) repository contains packages for the next minor
# release of CentOS Linux.  This repository only has content in the time period
# between an upstream release and the official CentOS Linux release.  These
# packages have not been fully tested yet and should be considered beta
# quality.  They are made available for people willing to test and provide
# feedback for the next release.

[cr]
name=CentOS Linux $releasever - ContinuousRelease
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=cr&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/cr/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-Debuginfo.repo <<\EOF
# CentOS-Linux-Debuginfo.repo
#
# All debug packages are merged into a single repo, split by basearch, and are
# not signed.

[debuginfo]
name=CentOS Linux $releasever - Debuginfo
baseurl=http://debuginfo.centos.org/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-Devel.repo <<\EOF
# CentOS-Linux-Devel.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[devel]
name=CentOS Linux $releasever - Devel WARNING! FOR BUILDROOT USE ONLY!
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=Devel&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/Devel/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-Extras.repo <<\EOF
# CentOS-Linux-Extras.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[extras]
name=CentOS Linux $releasever - Extras
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/extras/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-FastTrack.repo <<\EOF
# CentOS-Linux-FastTrack.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[fasttrack]
name=CentOS Linux $releasever - FastTrack
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=fasttrack&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/fasttrack/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-HighAvailability.repo <<\EOF
# CentOS-Linux-HighAvailability.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[ha]
name=CentOS Linux $releasever - HighAvailability
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=HighAvailability&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/HighAvailability/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-Media.repo <<\EOF
# CentOS-Linux-Media.repo
#
# You can use this repo to install items directly off the installation media.
# Verify your mount point matches one of the below file:// paths.

[media-baseos]
name=CentOS Linux $releasever - Media - BaseOS
baseurl=file:///media/CentOS/BaseOS
        file:///media/cdrom/BaseOS
        file:///media/cdrecorder/BaseOS
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[media-appstream]
name=CentOS Linux $releasever - Media - AppStream
baseurl=file:///media/CentOS/AppStream
        file:///media/cdrom/AppStream
        file:///media/cdrecorder/AppStream
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-Plus.repo <<\EOF
# CentOS-Linux-Plus.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[plus]
name=CentOS Linux $releasever - Plus
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/centosplus/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-PowerTools.repo <<\EOF
# CentOS-Linux-PowerTools.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[powertools]
name=CentOS Linux $releasever - PowerTools
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=PowerTools&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/PowerTools/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-Sources.repo <<\EOF
# CentOS-Linux-Sources.repo


[baseos-source]
name=CentOS Linux $releasever - BaseOS - Source
baseurl=http://vault.centos.org/$contentdir/$releasever/BaseOS/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[appstream-source]
name=CentOS Linux $releasever - AppStream - Source
baseurl=http://vault.centos.org/$contentdir/$releasever/AppStream/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[extras-source]
name=CentOS Linux $releasever - Extras - Source
baseurl=http://vault.centos.org/$contentdir/$releasever/extras/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[plus-source]
name=CentOS Linux $releasever - Plus - Source
baseurl=http://vault.centos.org/$contentdir/$releasever/centosplus/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
    elif [ ${CENTOS_VERSION} -eq "7" ]; then
        CentOS7_RepoFiles='CentOS-Base.repo CentOS-CR.repo CentOS-Debuginfo.repo CentOS-fasttrack.repo CentOS-Media.repo CentOS-Sources.repo CentOS-Vault.repo'
        for REPOS in $CentOS7_RepoFiles; do
            touch $REPOS
        done
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Base.repo <<\EOF
# CentOS-Base.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the mirrorlist= does not work for you, as a fall back you can try the 
# remarked out baseurl= line instead.
#
#

[base]
name=CentOS-$releasever - Base
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates 
[updates]
name=CentOS-$releasever - Updates
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-CR.repo <<\EOF
# CentOS-CR.repo
#
# The Continuous Release ( CR )  repository contains rpms that are due in the next
# release for a specific CentOS Version ( eg. next release in CentOS-7 ); these rpms
# are far less tested, with no integration checking or update path testing having
# taken place. They are still built from the upstream sources, but might not map 
# to an exact upstream distro release.
#
# These packages are made available soon after they are built, for people willing 
# to test their environments, provide feedback on content for the next release, and
# for people looking for early-access to next release content.
#
# The CR repo is shipped in a disabled state by default; its important that users 
# understand the implications of turning this on. 
#
# NOTE: We do not use a mirrorlist for the CR repos, to ensure content is available
#       to everyone as soon as possible, and not need to wait for the external
#       mirror network to seed first. However, many local mirrors will carry CR repos
#       and if desired you can use one of these local mirrors by editing the baseurl
#       line in the repo config below.
#

[cr]
name=CentOS-$releasever - cr
baseurl=http://mirror.centos.org/centos/$releasever/cr/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=0
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Debuginfo.repo <<\EOF
# CentOS-Debug.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#

# All debug packages from all the various CentOS-7 releases
# are merged into a single repo, split by BaseArch
#
# Note: packages in the debuginfo repo are currently not signed
#

[base-debuginfo]
name=CentOS-7 - Debuginfo
baseurl=http://debuginfo.centos.org/7/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Debug-7
enabled=0
#
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-fasttrack.repo <<\EOF
[fasttrack]
name=CentOS-7 - fasttrack
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=fasttrack&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/fasttrack/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Media.repo <<\EOF
# CentOS-Media.repo
#
#  This repo can be used with mounted DVD media, verify the mount point for
#  CentOS-7.  You can use this repo and yum to install items directly off the
#  DVD ISO that we release.
#
# To use this repo, put in your DVD and use it with the other repos too:
#  yum --enablerepo=c7-media [command]
#  
# or for ONLY the media repo, do this:
#
#  yum --disablerepo=\* --enablerepo=c7-media [command]

[c7-media]
name=CentOS-$releasever - Media
baseurl=file:///media/CentOS/
        file:///media/cdrom/
        file:///media/cdrecorder/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Sources.repo <<\EOF
# CentOS-Sources.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the mirrorlist= does not work for you, as a fall back you can try the 
# remarked out baseurl= line instead.
#
#

[base-source]
name=CentOS-$releasever - Base Sources
baseurl=http://vault.centos.org/centos/$releasever/os/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates 
[updates-source]
name=CentOS-$releasever - Updates Sources
baseurl=http://vault.centos.org/centos/$releasever/updates/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras-source]
name=CentOS-$releasever - Extras Sources
baseurl=http://vault.centos.org/centos/$releasever/extras/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus-source]
name=CentOS-$releasever - Plus Sources
baseurl=http://vault.centos.org/centos/$releasever/centosplus/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
    fi
}

## 生成 Fedora 官方 repo 源文件
function FedoraReposCreate() {
    Fedora_RepoFiles='fedora-cisco-openh264.repo fedora.repo fedora-updates.repo fedora-modular.repo fedora-updates-modular.repo fedora-updates-testing.repo fedora-updates-testing-modular.repo'
    for REPOS in $Fedora_RepoFiles; do
        touch $REPOS
    done
    cat >$RedHatReposDir/${SOURCE_BRANCH}-cisco-openh264.repo <<\EOF
[fedora-cisco-openh264]
name=Fedora $releasever openh264 (From Cisco) - $basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-cisco-openh264-$releasever&arch=$basearch
type=rpm
enabled=1
metadata_expire=14d
repo_gpgcheck=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=True

[fedora-cisco-openh264-debuginfo]
name=Fedora $releasever openh264 (From Cisco) - $basearch - Debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-cisco-openh264-debug-$releasever&arch=$basearch
type=rpm
enabled=0
metadata_expire=14d
repo_gpgcheck=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=True
EOF
    cat >$RedHatReposDir/${SOURCE_BRANCH}.repo <<\EOF
[fedora]
name=Fedora $releasever - $basearch
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Everything/$basearch/os/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
enabled=1
countme=1
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-debuginfo]
name=Fedora $releasever - $basearch - Debug
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Everything/$basearch/debug/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-debug-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-source]
name=Fedora $releasever - Source
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Everything/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-source-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    cat >$RedHatReposDir/${SOURCE_BRANCH}-updates.repo <<\EOF
[updates]
name=Fedora $releasever - $basearch - Updates
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Everything/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch
enabled=1
countme=1
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-debuginfo]
name=Fedora $releasever - $basearch - Updates - Debug
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Everything/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-debug-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-source]
name=Fedora $releasever - Updates Source
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Everything/SRPMS/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-source-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    cat >$RedHatReposDir/${SOURCE_BRANCH}-modular.repo <<\EOF
[fedora-modular]
name=Fedora Modular $releasever - $basearch
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Modular/$basearch/os/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-modular-$releasever&arch=$basearch
enabled=1
countme=1
#metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-modular-debuginfo]
name=Fedora Modular $releasever - $basearch - Debug
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Modular/$basearch/debug/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-modular-debug-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-modular-source]
name=Fedora Modular $releasever - Source
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Modular/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-modular-source-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    cat >$RedHatReposDir/${SOURCE_BRANCH}-updates-modular.repo <<\EOF
[updates-modular]
name=Fedora Modular $releasever - $basearch - Updates
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-modular-f$releasever&arch=$basearch
enabled=1
countme=1
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-modular-debuginfo]
name=Fedora Modular $releasever - $basearch - Updates - Debug
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-modular-debug-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-modular-source]
name=Fedora Modular $releasever - Updates Source
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/SRPMS/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-modular-source-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    cat >$RedHatReposDir/${SOURCE_BRANCH}-updates-testing.repo <<\EOF
[updates-testing]
name=Fedora $releasever - $basearch - Test Updates
#baseurl=http://download.example/pub/fedora/linux/updates/testing/$releasever/Everything/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-f$releasever&arch=$basearch
enabled=0
countme=1
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-testing-debuginfo]
name=Fedora $releasever - $basearch - Test Updates Debug
#baseurl=http://download.example/pub/fedora/linux/updates/testing/$releasever/Everything/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-debug-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-testing-source]
name=Fedora $releasever - Test Updates Source
#baseurl=http://download.example/pub/fedora/linux/updates/testing/$releasever/Everything/SRPMS/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-source-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    cat >$RedHatReposDir/${SOURCE_BRANCH}-updates-testing-modular.repo <<\EOF
[updates-testing-modular]
name=Fedora Modular $releasever - $basearch - Test Updates
#baseurl=http://download.example/pub/fedora/linux/updates/testing/$releasever/Modular/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-modular-f$releasever&arch=$basearch
enabled=0
countme=1
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-testing-modular-debuginfo]
name=Fedora Modular $releasever - $basearch - Test Updates Debug
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-modular-debug-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-testing-modular-source]
name=Fedora Modular $releasever - Test Updates Source
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/SRPMS/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-modular-source-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
}

## 生成 EPEL 扩展 repo 官方源文件
function EPELReposCreate() {
    cd $RedHatReposDir
    if [ ${CENTOS_VERSION} -eq "8" ]; then
        EPEL8_RepoFiles='epel.repo epel-modular.repo epel-playground.repo epel-testing.repo epel-testing-modular.repo'
        for REPOS in $EPEL8_RepoFiles; do
            touch $REPOS
        done
        cat >$RedHatReposDir/epel.repo <<\EOF
[epel]
name=Extra Packages for Enterprise Linux $releasever - $basearch
#baseurl=https://download.fedoraproject.org/pub/epel/$releasever/Everything/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8

[epel-debuginfo]
name=Extra Packages for Enterprise Linux $releasever - $basearch - Debug
#baseurl=https://download.fedoraproject.org/pub/epel/$releasever/Everything/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux $releasever - $basearch - Source
#baseurl=https://download.fedoraproject.org/pub/epel/$releasever/Everything/SRPMS
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-source-$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1
EOF
        cat >$RedHatReposDir/epel-modular.repo <<\EOF
[epel-modular]
name=Extra Packages for Enterprise Linux Modular $releasever - $basearch
#baseurl=https://download.fedoraproject.org/pub/epel/$releasever/Modular/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-modular-$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8

[epel-modular-debuginfo]
name=Extra Packages for Enterprise Linux Modular $releasever - $basearch - Debug
#baseurl=https://download.fedoraproject.org/pub/epel/$releasever/Modular/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-modular-debug-$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1

[epel-modular-source]
name=Extra Packages for Enterprise Linux Modular $releasever - $basearch - Source
#baseurl=https://download.fedoraproject.org/pub/epel/$releasever/Modular/SRPMS
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-modular-source-$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1
EOF
        cat >$RedHatReposDir/epel-playground.repo <<\EOF
[epel-playground]
name=Extra Packages for Enterprise Linux $releasever - Playground - $basearch
#baseurl=https://download.fedoraproject.org/pub/epel/playground/$releasever/Everything/$basearch/os
metalink=https://mirrors.fedoraproject.org/metalink?repo=playground-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8

[epel-playground-debuginfo]
name=Extra Packages for Enterprise Linux $releasever - Playground - $basearch - Debug
#baseurl=https://download.fedoraproject.org/pub/epel/playground/$releasever/Everything/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=playground-debug-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1

[epel-playground-source]
name=Extra Packages for Enterprise Linux $releasever - Playground - $basearch - Source
#baseurl=https://download.fedoraproject.org/pub/epel/playground/$releasever/Everything/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=playground-source-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1
EOF
        cat >$RedHatReposDir/epel-testing.repo <<\EOF
[epel-testing]
name=Extra Packages for Enterprise Linux $releasever - Testing - $basearch
#baseurl=https://download.fedoraproject.org/pub/epel/testing/$releasever/Everything/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8

[epel-testing-debuginfo]
name=Extra Packages for Enterprise Linux $releasever - Testing - $basearch - Debug
#baseurl=https://download.fedoraproject.org/pub/epel/testing/$releasever/Everything/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-debug-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1

[epel-testing-source]
name=Extra Packages for Enterprise Linux $releasever - Testing - $basearch - Source
#baseurl=https://download.fedoraproject.org/pub/epel/testing/$releasever/Everything/SRPMS
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-source-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1
EOF
        cat >$RedHatReposDir/epel-testing-modular.repo <<\EOF
[epel-testing-modular]
name=Extra Packages for Enterprise Linux Modular $releasever - Testing - $basearch
#baseurl=https://download.fedoraproject.org/pub/epel/testing/$releasever/Modular/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-modular-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8

[epel-testing-modular-debuginfo]
name=Extra Packages for Enterprise Linux Modular $releasever - Testing - $basearch - Debug
#baseurl=https://download.fedoraproject.org/pub/epel/testing/$releasever/Modular/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-modular-debug-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1

[epel-testing-modular-source]
name=Extra Packages for Enterprise Linux Modular $releasever - Testing - $basearch - Source
#baseurl=https://download.fedoraproject.org/pub/epel/testing/$releasever/Modular/SRPMS
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-modular-source-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1
EOF
    elif [ ${CENTOS_VERSION} -eq "7" ]; then
        EPEL7_RepoFiles='epel.repo epel-testing.repo'
        for REPOS in $EPEL7_RepoFiles; do
            touch $REPOS
        done
        cat >$RedHatReposDir/epel.repo <<\EOF
[epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
#baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - $basearch - Debug
#baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux 7 - $basearch - Source
#baseurl=http://download.fedoraproject.org/pub/epel/7/SRPMS
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
EOF
        cat >$RedHatReposDir/epel-testing.repo <<\EOF
[epel-testing]
name=Extra Packages for Enterprise Linux 7 - Testing - $basearch
#baseurl=http://download.fedoraproject.org/pub/epel/testing/7/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-epel7&arch=$basearch
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[epel-testing-debuginfo]
name=Extra Packages for Enterprise Linux 7 - Testing - $basearch - Debug
#baseurl=http://download.fedoraproject.org/pub/epel/testing/7/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-debug-epel7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1

[epel-testing-source]
name=Extra Packages for Enterprise Linux 7 - Testing - $basearch - Source
#baseurl=http://download.fedoraproject.org/pub/epel/testing/7/SRPMS
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-source-epel7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
EOF
    fi
}

Combin_Function
