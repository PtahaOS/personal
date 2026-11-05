-- Arch Variables
hl.env("XDG_MENU_PREFIX", "arch-")

-- Cursor. Имя темы из пакета rose-pine-cursor.
hl.env("XCURSOR_THEME", "BreezeX-RosePine-Linux")
hl.env("XCURSOR_SIZE", "24")

-- Wayland first. Звёздочка в GDK_BACKEND ломает выбор бэкенда, её нет.
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
-- qt5ct не красит Qt6. Стоят оба пакета, тема берётся из qt6ct.
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Весь рендер на NVIDIA. iGPU в список не входит.
-- Симлинк создаёт setup.sh: /etc/udev/rules.d/99-nvidia-dgpu.rules
-- Если после перезагрузки экран ноутбука чёрный, матрица подключена к AMD,
-- а не к NVIDIA. Тогда единственный рабочий вариант без BIOS:
--   hl.env("AQ_DRM_DEVICES", "/dev/dri/nvidia-dgpu:/dev/dri/amd-igpu")
-- Полностью выключить встроенную графику: AsusMuxDgpu (system/supergfxd.conf)
-- или Discrete в BIOS. Не ставь DRI_PRIME: он выбирает Radeon 780M.
hl.env("AQ_DRM_DEVICES", "/dev/dri/nvidia-dgpu")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("AQ_FORCE_LINEAR_BLIT", "0")

-- Steam/Proton. Эти переменные наследуются всей сессией, не только ярлыком Steam.
-- Фильтр по имени устройства не даёт DXVK и VKD3D взять 780M, пока она ещё видна.
-- Не ставим __NV_PRIME_RENDER_OFFLOAD и __VK_LAYER_NV_optimus:
-- после MUX, когда iGPU пропала, offload-переменные ломают игры.
-- Не ставим VK_DRIVER_FILES: он указывает только на 64-битный ICD и роняет 32-битный Proton.
hl.env("DXVK_FILTER_DEVICE_NAME", "NVIDIA")
hl.env("VKD3D_FILTER_DEVICE_NAME", "NVIDIA")
