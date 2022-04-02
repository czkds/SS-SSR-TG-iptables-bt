#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH


sh_ver="2.0.9"




#0升级脚本
Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/DD.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法链接到 Github !" && exit 0
	wget -N --no-check-certificate "https://raw.githubusercontent.com/veip007/hj/master/hj.sh" && chmod +x hj.sh
	echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !(注意：因为更新方式为直接覆盖当前运行的脚本，所以可能下面会提示一些报错，无视即可)" && exit 0
}
 #1安装BBR 锐速
bbr_ruisu(){
	bash <(curl -s -L https://raw.githubusercontent.com/veip007/Linux-NetSpeed/master/tcp.sh)
}
#2一键提升VPS速度
tools(){
	wget -N --no-check-certificate https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/tools.sh && chmod +x tools.sh && bash tools.sh
}
#3Cloudflare WARP 一键配置
warp.sh(){
	bash <(curl -fsSL git.io/warp.sh) menu
}
#4安装SSR多用户版
Install_ssr(){
	bash <(curl -s -L https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/ssr.sh)
}
#5安装ssrmu（arm）
ssrmu(){
        bash <(curl -s -L https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/ssrmu.sh)
}
#6安装V2ary_233一键
Install_V2ray(){
	bash <(curl -s -L https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/V2Ray.sh)
}
#7安装Tg专用代理（Go版）
Tg_socks(){
	bash <(curl -s -L https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/mtproxy_go.sh)
}
#8安装TG专用代理（中文版）
mtproxy(){
        wget -N --no-check-certificate https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/mtproxy.sh && chmod +x mtproxy.sh && bash mtproxy.sh
}
#9安装Goflyway
Install_goflyway(){
	bash <(curl -s -L https://git.io/goflyway.sh && chmod +x goflyway.sh)
}
#10小鸡性能测试
View_superbench(){
	bash <(curl -s -L https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/superbench.sh)
}

#11回程线路测试
View_huicheng(){
	wget -N --no-check-certificate https://raw.githubusercontent.com/veip007/huicheng/master/huicheng && chmod +x huicheng
}
#12安装云监控探针
Install_status(){
	wget -N --no-check-certificate https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/status.sh && chmod +x status.sh && bash status.sh
}
#13一键DD包（OD源）
DD_OD(){
	bash <(curl -s -L https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/dd-od.sh)
}
#14一键DD包（GD源）
DD_GD(){
	bash <(curl -s -L https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/dd-gd.sh)
}
#15一键开启默认bbr
open_bbr(){
	modprobe tcp_bbr && echo "tcp_bbr" | tee --append /etc/modules-load.d/modules.conf && echo "net.core.default_qdisc=fq" | tee --append /etc/sysctl.conf && echo "net.ipv4.tcp_congestion_control=bbr" | tee --append /etc/sysctl.conf && sysctl -p && sysctl net.ipv4.tcp_available_congestion_control && sysctl net.ipv4.tcp_congestion_control && lsmod | grep bbr
}
#16八合一共存脚本+伪装站点
install(){
	wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/install.sh" && chmod 700 /root/install.sh && /root/install.sh
}
# 17Netflix解锁检测
netflix(){
        bash <(curl -sSL "https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/netflix.sh")	
}
#18CF自动优选
cf(){
bash <(curl -sSL "https://proxy.freecdn.workers.dev/?url=https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/cf.sh")	
}
#19VPS一键3网测速脚本
superspeed(){
	bash <(curl -s -L https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/superspeed.sh)
}
#20FRP内网穿刺
install-frps(){
        wget -N --no-check-certificate https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/frps/install-frps.sh -O ./install-frps.sh && chmod 700 ./install-frps.sh && bash install-frps.sh install
}
#21Docker-Compose安装
DockerInstallation(){
       bash <(curl -sSL https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/DockerInstallation.sh)
}
#22X-ui面板，证书一键安装
x-uiyijian(){
       bash <(curl -Ls https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/x-uiyijian.sh)
}
#23闲蛋探针+中转一键搭建
xiandan(){
       bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/xiandan/xiandan.sh')
}
#24宝塔面板一键搭建
install_panel(){
       curl -sSO http://download.bt.cn/install/install_panel.sh && bash install_panel.sh
}
#25流媒体检测
liumeiti(){
       bash <(curl -L -s https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/liumeiti.sh)
}
#26NPS穿透一键安装
nps(){
       bash -c "$(curl -fsSL https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/nps.sh)"
}
#27portainer中文版一键安装
x86(){
       bash <(curl -L -s https://raw.githubusercontent.com/czkds/SS-SSR-TG-iptables-bt/main/sh/x86.sh)
}
#28L2TP一键安装
L2TP(){
      bash <(curl -s -L git.io/JPjuV)
} 
action=$1
if [[ "${action}" == "monitor" ]]; then
	crontab_monitor_goflyway
else
echo && echo -e " 


  
+-------------------------------------------------------------+
|                        大灰狼专用                             | 
|                     小鸡一键管理脚本                          |                   
|                     一键在手小鸡无忧                          |
|                          使用教程                             |
|    https://github.com/czkds/SS-SSR-TG-iptables-bt      |                     
+-------------------------------------------------------------+
 ${Green_font_prefix}0.${Font_color_suffix}  升级脚本
 ${Green_font_prefix}1.${Font_color_suffix}  加速系列：Bbr系列、锐速
 ${Green_font_prefix}2.${Font_color_suffix}  一键提升VPS速度
 ${Green_font_prefix}3.${Font_color_suffix}  Cloudflare WARP 一键配置
 ${Green_font_prefix}4.${Font_color_suffix}  安装SSR多用户版
 ${Green_font_prefix}5.${Font_color_suffix}  安装ssrmu脚本(arm)
 ${Green_font_prefix}6.${Font_color_suffix}  安装V2ary_233一键
 ${Green_font_prefix}7.${Font_color_suffix}  TG专用代理（Go版）
 ${Green_font_prefix}8.${Font_color_suffix}  TG专用代理（中文版）
 ${Green_font_prefix}9.${Font_color_suffix}  安装Goflyway
 ${Green_font_prefix}10.${Font_color_suffix} 小鸡性能测试
 ${Green_font_prefix}11.${Font_color_suffix} 回程线路测试:命令:./huicheng 您的IP
 ${Green_font_prefix}12.${Font_color_suffix} 云监控探针
 ${Green_font_prefix}13.${Font_color_suffix} 傻瓜式一键DD包（OD源）
 ${Green_font_prefix}14.${Font_color_suffix} 傻瓜式一键DD包（GD源）
 ${Green_font_prefix}15.${Font_color_suffix} 一键开启默认bbr  
 ${Green_font_prefix}16.${Font_color_suffix} 八合一共存脚本+伪装站点
 ${Green_font_prefix}17.${Font_color_suffix} Netflix解锁检测
 ${Green_font_prefix}18.${Font_color_suffix} CF自动优选
 ${Green_font_prefix}19.${Font_color_suffix} VPS一键3网测速脚本
 ${Green_font_prefix}20.${Font_color_suffix} frp一键内网穿刺
 ${Green_font_prefix}21.${Font_color_suffix} Docker-Compose安装
 ${Green_font_prefix}22.${Font_color_suffix} 支持多协议多用户的X-ui面板+证书一键安装
 ${Green_font_prefix}23.${Font_color_suffix} 闲蛋探针+中转一键搭建
 ${Green_font_prefix}24.${Font_color_suffix} 宝塔面板一键搭建
 ${Green_font_prefix}25.${Font_color_suffix} 流媒体检测
 ${Green_font_prefix}26.${Font_color_suffix} NPS穿透一键安装
 ${Green_font_prefix}27.${Font_color_suffix} portainer可视化容器中文版一键安装
 ${Green_font_prefix}28.${Font_color_suffix} L2TP一键安装
  " && echo
  
fi
echo
read -e -p " 请输入数字 [0-28]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	bbr_ruisu
	;;
	2)
	tools
	;;
	3)
	warp.sh
	;;
	4)
	Install_ssr
	;;
	5)
	ssrmu
	;;
	6)
	Install_V2ray
	;;
	7)
	Tg_socks
	;;
	8)
	mtproxy
	;;
	9)
	Install_goflyway
	;;
	10)
	View_superbench
	;;
	11)
	View_huicheng
	;;
	12)
	Install_status
	;;
	13)
	DD_OD
	;;
	14)
	DD_GD
	;;
	15)
	open_bbr
	;;
	16)
	install
	;;
	17)
	netflix	
	;;
	18)
	cf	
	;;
	19)
        superspeed	
	;;
	20)
	install-frps
	;;
	21)
	DockerInstallation
	;;
	22)
	x-uiyijian
	;;
	23)
	xiandan
	;;
        24)
	install_panel
	;;
        25)
	liumeiti
	;;
	26)
	nps
	;;
	27)
	x86
	;;
	28)
	L2TP
	;;
	*)
	echo "请输入正确数字 [0-28]"
	;;
esac
  
  
  
  









