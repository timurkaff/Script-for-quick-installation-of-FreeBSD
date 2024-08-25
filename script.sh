#!/bin/sh

echo "Starting FreeBSD automated setup..."

# Проверка на права root
if [ "$(id -u)" -ne 0 ]; then
    echo "Пожалуйста, запустите скрипт от имени root."
    exit 1
fi

# Обновление системы и установка базовых утилит
echo "Updating FreeBSD packages..."
pkg update && pkg upgrade -y

# Установка Xorg
echo "Installing Xorg..."
pkg install -y xorg

# Выбор установки на физическую или виртуальную машину
echo "Are you installing on a physical machine or a virtual machine?"
echo "1) Physical Machine (with NVIDIA GPU)"
echo "2) Virtual Machine (e.g., VirtualBox)"
echo "Enter the number of your choice:"

read machine_choice

# Установка соответствующих драйверов
if [ "$machine_choice" -eq 1 ]; then
    echo "Detecting and installing NVIDIA driver..."
    pkg install -y nvidia-driver nvidia-settings nvidia-xconfig
    echo 'nvidia_load="YES"' >> /boot/loader.conf
    nvidia-xconfig
elif [ "$machine_choice" -eq 2 ]; then
    echo "Installing VirtualBox guest additions..."
    pkg install -y virtualbox-ose-additions
    sysrc vboxguest_enable="YES"
    sysrc vboxservice_enable="YES"
    echo "VirtualBox guest additions installed."
else
    echo "Invalid choice. Exiting setup."
    exit 1
fi

# Функция для установки графической оболочки
install_desktop_env() {
    case $1 in
        1)
            echo "Installing KDE Plasma..."
            pkg install -y kde5 sddm
            sysrc sddm_enable="YES"
            sysrc dbus_enable="YES"
            echo "exec ck-launch-session startplasma-x11" > ~/.xinitrc
            ;;
        2)
            echo "Installing GNOME..."
            pkg install -y gnome gdm
            sysrc gdm_enable="YES"
            sysrc dbus_enable="YES"
            echo "exec gnome-session" > ~/.xinitrc
            ;;
        3)
            echo "Installing XFCE..."
            pkg install -y xfce xfce4-goodies slim
            sysrc slim_enable="YES"
            sysrc dbus_enable="YES"
            echo "exec startxfce4" > ~/.xinitrc
            ;;
        4)
            echo "Installing Mate..."
            pkg install -y mate slim
            sysrc slim_enable="YES"
            sysrc dbus_enable="YES"
            echo "exec mate-session" > ~/.xinitrc
            ;;
        5)
            echo "Installing LXDE..."
            pkg install -y lxde slim
            sysrc slim_enable="YES"
            sysrc dbus_enable="YES"
            echo "exec startlxde" > ~/.xinitrc
            ;;
        *)
            echo "Invalid option. No desktop environment will be installed."
            ;;
    esac
}

# Выбор графической оболочки для установки
echo "Select a Desktop Environment to install:"
echo "1) KDE Plasma"
echo "2) GNOME"
echo "3) XFCE"
echo "4) Mate"
echo "5) LXDE"
echo "Enter the number of your choice:"

read de_choice

# Установка выбранной графической оболочки
install_desktop_env $de_choice

# Добавление монтирования /proc в /etc/fstab, если запись не существует
if ! grep -q '^proc[[:space:]]' /etc/fstab; then
    echo "proc /proc procfs rw 0 0" >> /etc/fstab
fi

# Включение необходимых сервисов
if [ $de_choice -ge 1 ] && [ $de_choice -le 5 ]; then
    echo "Enabling necessary services..."
    sysrc dbus_enable="YES"
    sysrc hald_enable="YES"
fi

echo "FreeBSD setup is complete. Please reboot your system to start using your selected desktop environment."
