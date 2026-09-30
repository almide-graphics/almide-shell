# Hyprland in a container: its DRM backend on the host's vkms device
# (/dev/dri/card0, a virtual display — no GPU) with Mesa's software renderer,
# seatd for the session, grim to capture, wtype for a virtual keyboard, and
# the Rust toolchain a native Almide build needs; Quickshell for the QML
# baseline, and tesseract to read what a bar shows.
FROM debian:sid
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    hyprland grim wtype seatd udev pipewire pipewire-bin wireplumber dbus dbus-user-session procps libnotify-bin libglib2.0-bin mesa-utils libgl1-mesa-dri libegl-mesa0 libgbm1 \
    ca-certificates curl git build-essential pkg-config fonts-noto-cjk fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    quickshell qt6-wayland qml6-module-qtquick-layouts qml6-module-qtquick-window upower tesseract-ocr imagemagick wayvnc novnc websockify foot jq \
    && rm -rf /var/lib/apt/lists/*
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain 1.94.0
ENV PATH=/root/.cargo/bin:$PATH
# A cursor theme, for the pointer the compositor draws over a window.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends adwaita-icon-theme \
    && rm -rf /var/lib/apt/lists/*
# An input method — fcitx5 with Mozc — for Japanese over text-input-v3.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends fcitx5 fcitx5-mozc \
    && rm -rf /var/lib/apt/lists/*
RUN useradd -m -G video,render,input u
