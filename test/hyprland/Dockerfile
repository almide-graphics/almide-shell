# Hyprland in a container: its DRM backend on the host's vkms device
# (/dev/dri/card0, a virtual display — no GPU) with Mesa's software renderer,
# seatd for the session, grim to capture, wtype for a virtual keyboard, and
# the Rust toolchain a native Almide build needs.
FROM debian:sid
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    hyprland grim wtype seatd udev pipewire pipewire-bin wireplumber dbus dbus-user-session procps libnotify-bin libglib2.0-bin mesa-utils libgl1-mesa-dri libegl-mesa0 libgbm1 \
    ca-certificates curl git build-essential pkg-config fonts-noto-cjk fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain 1.94.0
ENV PATH=/root/.cargo/bin:$PATH
RUN useradd -m -G video,render,input u
