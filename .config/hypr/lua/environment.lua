-- Arch Variables
hl.env("XDG_MENU_PREFIX", "arch-")

-- Cursor. Имя темы из пакета rose-pine-cursor.
hl.env("XCURSOR_THEME", "BreezeX-RosePine-Linux")
hl.env("XCURSOR_SIZE", "24")

-- GTK. Пакет rose-pine-gtk-theme-full кладёт тему в каталог rose-pine-moon-gtk,
-- а иконки в rose-pine-moon-icons. Короткое имя rose-pine-moon ничего не находит.
hl.env("GTK_THEME", "rose-pine-moon-gtk")

-- Wayland first. Звёздочка в GDK_BACKEND ломает выбор бэкенда, её нет.
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
-- Иконки и диалоги берёт qt6ct, цвета Qt рисует Kvantum (rose-pine-moon-iris).
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
-- LibreOffice иначе рисует своим стилем, мимо GTK-темы.
hl.env("SAL_USE_VCLPLUGIN", "gtk3")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- NVIDIA первая, встроенная Radeon вторая. iGPU не выключается:
-- она остаётся в списке, просто не главная.
-- Симлинки создаёт setup.sh: /etc/udev/rules.d/99-nvidia-dgpu.rules
-- Не ставь DRI_PRIME: он выбирает 780M.
hl.env("AQ_DRM_DEVICES", "/dev/dri/nvidia-dgpu:/dev/dri/amd-igpu")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("AQ_FORCE_LINEAR_BLIT", "0")

-- Steam/Proton наследуют это из сессии, не из ярлыка.
-- Фильтр по имени не даёт DXVK и VKD3D взять 780M, пока она видна.
-- Не ставим __NV_PRIME_RENDER_OFFLOAD и __VK_LAYER_NV_optimus:
-- карта уже первая в AQ_DRM_DEVICES, offload тут лишний и ломает часть игр.
-- Не ставим VK_DRIVER_FILES: он указывает только на 64-битный ICD и роняет 32-битный Proton.
hl.env("DXVK_FILTER_DEVICE_NAME", "NVIDIA")
hl.env("VKD3D_FILTER_DEVICE_NAME", "NVIDIA")
