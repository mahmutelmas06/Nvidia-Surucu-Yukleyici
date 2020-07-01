#!/bin/bash 

#==============================================================================
# -------------------  PARDUS EKRAN KARTI YÜKLEYİCİ----------------------------
#  Yazar         : MAHMUT ELMAS
#  İletişim      : mahmutelmas06@gmail.com
#  Sürüm         : 0.2
#  Bağımlıkıklar : zenity apt wget
#  Lisans        : MIT - 
#  Bilgi         : Nvidia Detect paketi baz alınarak oluşturulmuştur
#
#==============================================================================


#==============================================================================  Yönetici hakları kontrolü

xhost +
clear

if [[ "$EUID" != "0" ]]; then
	notify-send -t 2000 -i /usr/share/icons/gnome/32x32/status/info.png "Yönetici olarak çalıştırın ya da root şifrenizi girin."
	echo -e "\nBu betik Yönetici Hakları ile çalıştırılmalıdır. Lütfen Şifrenizi giriniz...\n"
	sudo "bash" "$0" "$@" ; exit 0
else
	echo "Yönetici hakları doğrulandı..."
fi


NEYUKLU=$(dpkg -l | grep -E '^ii' | awk '{print $2}' | tail -n+5)				 # Yüklü tüm paketlerin listesi


#==============================================================================  Zenity kontrolü

if [[ -z "$(grep -F ' zenity ' <<< ${NEYUKLU[@]})" ]]; then

  echo "# Zenity bulunamadı ve yükleniyor..."
  apt-get install -y zenity
  
fi


#==============================================================================  Başka bir yükleyici çalışıyor mu kontrol et

checkPackageManager() {

if [[ "$(pidof synaptic)" ]] || 
   [[ $(pidof apt | wc -w) != "0" || $(pidof apt-get | wc -w) != "0" ]]; then

   zenity --question --cancel-label="İptal Et" --ok-label="Devam Et" --title="Başka bir paket yöneticisi çalışıyor" \
          --width="360" --height="120" --window-icon="warning" --icon-name="gtk-dialog-warning" \
          --text="\nŞu anda başka bir paket yöneticisinin çalıştığı tespit edildi!!! \
Devam etmeden önce diğer yükleyiciler sonlandırılacaktır.\n\nDevam etmek istiyor musunuz?" 2>/dev/null

  if [[ "$?" != "0" ]]; then ${opt_procedure[@]}
  else
    killall -9 synaptic
    killall -9 apt
    killall -9 apt-get
    killall -9 gdebi
    killall -9 pdebi
    killall -9 deepin-deb-installer
    sleep 1
  fi
fi
}

opt_procedure="exit 0" ; checkPackageManager

#==============================================================================  İnternet bağlantısı kontrolü

echo -e "GET http://google.com HTTP/1.0\n\n" | nc google.com 80 > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "İnternet bağlantısı doğrulandı..."
else
    zenity --width 320 --error --title "İnternet Bağlantısı algılanmadı" --text "Bu uygulama internet bağlantısı gerektirir. \nİnternete bağlandıktan sonra tekrar çalıştırın."; exit 1
fi

#==============================================================================

( 	  # Zenity yükleme göstergesi başlangıç

echo "# Öyükleme işlemi başlatılıyor." ; sleep 2	

# Yüklemeye hazırlık aşamaları
							 

echo "# Varsa APT sorunları çözülüyor..." ; sleep 2	

rm /var/lib/apt/lists/lock
rm /var/cache/apt/archives/lock
dpkg --configure -a
apt-get install -fy
apt-get update -y



echo "# Sistemin 32 Bit desteği denetleniyor..." ; sleep 2	

dpkg --add-architecture i386 
apt-get -y install linux-headers-$(uname -r)


if [ "$1" = "-h" -o "$1" = "--help" ]; then
	echo "Usage: nvidia-detect [PCIID]..."
	echo "       Reports the Debian packages supporting the NVIDIA GPU that is"
	echo "       installed on the local system (or given as a PCIID parameter)."
	exit 0
fi


#============================================================================== Nvidia Detect paketi ile sürücüleri belirle

# last time the PCI IDs were updated
LATEST="418.113"
PACKAGE=

NV_DETECT()
{

NVGA=$1
IDLISTDIR=./share/nvidia
local VERSIONS

if grep -q -i $NVGA $IDLISTDIR/nvidia-legacy-71xx.ids 2>/dev/null
then
	VERSIONS[71]=71.86
fi

if grep -q -i $NVGA $IDLISTDIR/nvidia-legacy-96xx.ids 2>/dev/null
then
	VERSIONS[96]=96.43
fi

if grep -q -i $NVGA $IDLISTDIR/nvidia-legacy-173xx.ids 2>/dev/null
then
	VERSIONS[173]=173.14
fi

if grep -q -i $NVGA $IDLISTDIR/nvidia-legacy-304xx.ids 2>/dev/null
then
	VERSIONS[304]=304.123
fi

if grep -q -i $NVGA $IDLISTDIR/nvidia-legacy-340xx.ids 2>/dev/null
then
	VERSIONS[340]=340.76
fi

if grep -q -i $NVGA $IDLISTDIR/nvidia-legacy-390xx.ids 2>/dev/null
then
	VERSIONS[390]=390.87
fi

if grep -q -i $NVGA $IDLISTDIR/nvidia-legacy-390xx-amd64.ids 2>/dev/null
then
	VERSIONS[391]=390.87
fi

if grep -q -i $NVGA $IDLISTDIR/nvidia-418.ids 2>/dev/null
then
	VERSIONS[418]=418.74
fi

if grep -q -i $NVGA $IDLISTDIR/nvidia-tesla-418.ids 2>/dev/null
then
	VERSIONS[419]=418.87.01
fi

if grep -q -i $NVGA $IDLISTDIR/nvidia.ids 2>/dev/null
then
	# 999 means current
	VERSIONS[999]=$LATEST
fi


if [[ ${#VERSIONS[*]} == 0 ]]; then
	echo "Uh oh. Your card is not supported by any driver version up to $LATEST."
	return
fi
		if [[ -n ${VERSIONS[999]} ]]; then
			if [[ -n ${VERSIONS[390]} ]]; then
					echo "Your card is supported by all driver versions."
			else
				echo "Your card is supported by the default drivers."
			fi
			PACKAGE="nvidia-driver"
		elif [[ -n ${VERSIONS[390]} ]]; then
			PACKAGE="nvidia-legacy-390xx-driver"
		elif [[ -n ${VERSIONS[391]} ]]; then
			PACKAGE="nvidia-legacy-390xx-driver:amd64"
		elif [[ -n ${VERSIONS[419]} ]]; then
			PACKAGE="nvidia-tesla-418-driver"
		elif [[ -n ${VERSIONS[340]} ]]; then
			PACKAGE="nvidia-legacy-304xx-driver"
		elif [[ -n ${VERSIONS[304]} ]]; then
			PACKAGE="nvidia-legacy-304xx-driver"
		elif [[ -n ${VERSIONS[173]} ]]; then
			echo "Uh oh. Your card is only supported by the 173.14 legacy drivers series, which is not in any current Debian suite."
		elif [[ -n ${VERSIONS[96]} ]]; then
			echo "Uh oh. Your card is only supported by the 96.43 legacy drivers series, which is not in any current Debian suite."
		elif [[ -n ${VERSIONS[71]} ]]; then
			echo "Uh oh. Your card is only supported by the 71.86 legacy drivers series, which is not in any current Debian suite."
		else
			echo "Oops. Internal error 11 ($NVGA)"
		fi
		if [ -n "$PACKAGE" ] && [ "$PACKAGE" != "nvidia-tesla-418-driver" ] && [[ -n ${VERSIONS[419]} ]]; then
			echo "Your card is also supported by the Tesla 418 drivers series."
		fi


if [ -n "$PACKAGE" ]; then
	echo "Kartınızla uyumlu sürücü paketi:"
	echo "$PACKAGE" | tee ./cihaz.txt
	chmod 777 ./cihaz.txt
fi

}


if [ -z "$1" ]; then

	if ! (lspci --version) > /dev/null 2>&1; then
		echo "ERROR: The 'lspci' command was not found. Please install the 'pciutils' package." >&2
		exit 1
	fi

	NV_DEVICES=$(lspci -mn | awk '{ gsub("\"",""); if (($2 ~ "030[0-2]") && ($3 == "10de" || $3 == "12d2")) { print $1 } }')

	if [ -z "$NV_DEVICES" ]; then
		echo "No NVIDIA GPU detected."
		exit 0
	fi

	echo "Bulunan Nvidia Ekran Kartınız:"
	for d in $NV_DEVICES ; do
		lspci -nn -s $d
	done

	for d in $NV_DEVICES ; do
		echo -e "\n$(lspci -s $d | awk -F: '{print $3}') model ekran kartınız sınanıyor..."
		NV_DETECT "$(lspci -mn -s "$d" | awk '{ gsub("\"",""); print $3 $4 }')"
	done

else

	for id in "$@" ; do
		PCIID=$(echo "$id" | sed -rn 's/^(10de)?:?([0-9a-fA-F]{4})$/10de\2/ip')
		if [ -z "$PCIID" ]; then
			echo "Error parsing PCI ID '$id'."
			exit 1
		fi

		echo "Checking driver support for PCI ID [$(echo $PCIID | sed -r 's/(....)(....)/\1:\2/')]"
		NV_DETECT "$PCIID"
	done

fi



) |
zenity 	--progress \
		--title="Yükleme hazırlanıyor..." \
		--text="Yükleme başlatılıyor." \
		--percentage=0 \
		--width 400 \
		--pulsate \
		--auto-close


cihazz="$(awk '{print $1}' ./cihaz.txt)"

#====================================================================================================================================================

(
echo "Kullanıcı Seçimi bekleniyor..." ; sleep 2  		# Zenity yükleme göstergesi başlangıç
action=$(zenity --list --radiolist \
	--height 300 --width 800 \
	--title "Nvidia Sürücü Yükleme Yazılımı" \
	--column "Seçim" 		 --column "Yapılacak işlem" 												--column "Açıklama" \
			  FALSE 				  "Tek ekran kartlı bilgisayar" 								 			 " Sisteminiz tek ekran kartlıysa bu seçeneği seçin" \
			  FALSE 				  "Çift ekran kartlı bilgisayar" 				 							 " Sisteminizde iki ekran kartı varsa bu seçeneği seçin. (Örnek Nvidia+Intel)" \
			  FALSE 				  "Nvidia sürücülerini kaldır" 				 								 " Yüklenen Nvidia sürücülerini kaldır ve Nouveau sürücüsüne dön" \
			  FALSE 				  "Kerneli güncelle" 														 " Linux çekirdeğini son sürüme güncelle. Dikkat!! Sisteme zarar verebilir" \
			  FALSE 				  "Kernel güncellemesini kaldır" 										 	 " Yüklediğiniz kernel sorunlara sebep olduysa kaldırabilirsiniz" \
	--separator=":")
	

if [ -z "$action" ] ; then
   echo "Seçim yapılmadı"
   exit 1
fi



IFS=":" ; for word in $action ; do   		#  Zenity checklist için çoklu seçim komutu başlat
case $word in 

#==============================================================================


"Tek"*)        
echo "# Ekran kartınız yükleniyor.Yükleme tamamlanana kadar pencereyi kapatmayınız..." ; sleep 2

apt-get purge -y *nvidia*
rm -f /etc/X11/xorg.conf.d/20-nvidia.conf
rm -f /etc/X11/xorg.conf

apt-get update -y
apt-get install -y "${cihazz}"
apt-get install -y "${cihazz}"-libs-i386 nvidia-xconfig

#mkdir -p /etc/X11/xorg.conf.d
#echo -e 'Section "Device"\n\tIdentifier "My GPU"\n\tDriver "nvidia"\nEndSection' > /etc/X11/xorg.conf.d/20-nvidia.conf
sudo echo blacklist nouveau > /etc/modprobe.d/blacklist-nvidia-nouveau.conf
sudo echo options nouveau modeset=0 >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf

rm -f ./cihaz.txt
apt-get -y autoremove

;;
"Çift"*)  	
echo "# Ekran kartınız yükleniyor.Yükleme tamamlanana kadar pencereyi kapatmayınız..." ; sleep 2

_USERS="$(awk -F'[/:]' '{if ($3 >= 1000 && $3 != 65534) print $1}' /etc/passwd)" # Kullanıcı listesini al

sudo killall dpkg
apt-get purge -y *nvidia*
rm -f /etc/X11/xorg.conf.d/20-nvidia.conf
rm -f /etc/X11/xorg.conf

apt-get update -y
apt-get install -y x11-xserver-utils
apt-get install -y "${cihazz}"
apt-get install -y "${cihazz}""-libs-i386"
apt-get install -y bumblebee bumblebee-nvidia primus primus-nvidia primus-vk-nvidia primus-libs-ia32 nvidia-driver-libs-i386 libgl1-nvidia-glx:i386
systemctl restart bumblebeed

for u in ${_USERS} 
do
adduser ${u} bumblebee
done

#busidd="$(lspci | egrep 'VGA|3D')"

echo -e 'Section "Screen"\n\tIdentifier "Default Screen"\n\tDevice "DiscreteNvidia"\nEndSection' > /etc/bumblebee/xorg.conf.nvidia

rm -f ./cihaz.txt
apt-get -y autoremove

;;
"Nvidia"*)  
echo "# Nvidia sürücüleri kaldırılarak açık kaynak sürücülere dönülüyor." ; sleep 2

sudo killall dpkg
apt-get purge -y *nvidia*
apt-get purge -y *bumblebee*
rm /etc/X11/xorg.conf.d/20-nvidia.conf
rm -f /etc/X11/xorg.conf

apt-get -y autoremove

sudo apt-get install -y xserver-xorg-video-nouveau
#nvidia-xconfig --restore-original-backup
rm /etc/modprobe.d/blacklist-nvidia-nouveau.conf


;;
"Kerneli"*)  
echo "# Kernel güncelleniyor." ; sleep 2

echo "deb http://deb.debian.org/debian stretch-backports main" | tee -a /etc/apt/sources.list

cat <<EOF | sudo tee /etc/apt/sources.list.d/buster-backports.list
deb http://http.debian.net/debian buster-backports main contrib non-free
EOF

apt-get -y update

apt-get -t buster-backports install -y linux-image-5.5.0-0.bpo.2-amd64

apt-get install -y linux-headers-5.5.0-0.bpo.2-amd64

echo $(apt-cache policy linux-image-amd64)


;;
"Kernel"*)  
echo "# Son yüklediğiniz Kernel kaldırılıyor." ; sleep 2


apt-get purge -y linux-image-5.5.0-0.bpo.2-amd64

apt-get purge -y linux-headers-5.5.0-0.bpo.2-amd64

echo $(apt-cache policy linux-image-amd64)


;;    
esac
done   #  Zenity checklist için çoklu seçim komutu kapat


# # # # # # # # # # # # # # # # # # # # # # #  # # # # # # # # # # # # # # # # # # # # # # # 

rm -f ./cihaz.txt

# İşlem tamamlanmıştır

notify-send -t 2000 -i /usr/share/icons/gnome/32x32/status/info.png "İşlem Tamamlanmıştır"


)

(( $? != 0 )) && zenity --error --text="Hata! İşlem iptal edildi."

exit 0





