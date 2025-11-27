#!/bin/bash

# --- Configuration Variables ---
readonly DISPLAY_NUM=100
readonly VNC_PORT=5900
readonly WEBSOCKIFY_PORT=6080
readonly LOGFILE=/tmp/websockify_${WEBSOCKIFY_PORT}.log
readonly WORKSPACE_ROOT="/workspaces/Terraria-On-Github"

# --- Function to Clean Up Background Processes ---
cleanup() {
    echo -e "\n🛑 Shutting down VNC environment and cleaning up..."
    # Kill all background processes started by the script
    kill ${XVFB_PID} ${X11VNC_PID} ${WEBSOCKIFY_PID} 2>/dev/null || true
    
    # Kill the game if it is still running
    pkill -f Terraria.MonoGame 2>/dev/null || true
    
    # Explicitly remove stale X locks and sockets
    rm -f /tmp/.X${DISPLAY_NUM}-lock 2>/dev/null || true
    sudo rm -f /tmp/.X11-unix/X${DISPLAY_NUM} 2>/dev/null || true
    
    echo "Cleanup complete."
    exit 0
}

# Trap signals and execute the cleanup function
trap cleanup SIGINT SIGTERM EXIT

# --- 1. Environment Setup ---
echo "⚙️ Setting up X11 environment..."

# Kill any processes using the display/ports before starting
pkill -f "Xvfb :${DISPLAY_NUM}" 2>/dev/null
pkill -f "rfbport ${VNC_PORT}" 2>/dev/null
pkill -f "websockify ${WEBSOCKIFY_PORT}" 2>/dev/null

export DISPLAY=:${DISPLAY_NUM}

mkdir -p /tmp/.X11-unix 2>/dev/null || true
chmod 1777 /tmp/.X11-unix 2>/dev/null || true

# --- 2. Start Virtual Display and VNC ---

echo "🖥️ Starting Xvfb on display :${DISPLAY_NUM} (1280x720x24)..."
Xvfb :${DISPLAY_NUM} -screen 0 1280x720x24 -nolisten tcp +extension COMPOSITE &
XVFB_PID=$!
sleep 2

echo "📡 Starting x11vnc on port ${VNC_PORT}..."
x11vnc -display :${DISPLAY_NUM} -nopw -forever -shared -rfbport ${VNC_PORT} -noxdamage -repeat -noclipboard -quiet &
X11VNC_PID=$!
sleep 1

echo "🌐 Starting websockify on ${WEBSOCKIFY_PORT} (proxies to VNC port ${VNC_PORT})..."
python3 -m websockify ${WEBSOCKIFY_PORT} localhost:${VNC_PORT} --web=${WORKSPACE_ROOT}/novnc > "${LOGFILE}" 2>&1 &
WEBSOCKIFY_PID=$!
sleep 1

# --- 3. Graphics Environment Exports (For Headless/Software Rendering) ---
echo "✨ Setting environment variables for robust software rendering..."

# FIX: Force the MESA software driver (llvmpipe is the most stable backend).
# This is typically the last resort to resolve X_GLXCreateContext errors.
export MESA_LOADER_DRIVER_OVERRIDE=llvmpipe

# Force the compatibility profile version that should work with older MonoGame/GLX
export MESA_GL_VERSION_OVERRIDE=3.3Compatibility

# Keep other necessary flags
export LIBGL_ALWAYS_INDIRECT=1
export XLIB_SKIP_ARGB_VISUALS=1
export __GLX_VENDOR_LIBRARY_NAME=mesa

# --- 4. Game Launch and Execution ---
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Terraria - VNC Session is Active                              ║"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║  Access via browser: http://localhost:${WEBSOCKIFY_PORT}/vnc.html        ║"
echo "║  (Remember to forward port ${WEBSOCKIFY_PORT} in your environment!)      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

cd "${WORKSPACE_ROOT}"

GAME_BINARY="./bin/Release/net7.0/linux-x64/publish/Terraria.MonoGame"

if [ "${RUN_BINARY}" = "1" ] && [ -x "${GAME_BINARY}" ]; then
    echo "🎮 RUN_BINARY=1 set and executable found. Starting Terraria..."
    exec "${GAME_BINARY}"
    echo "ERROR: Failed to start the game binary at ${GAME_BINARY}."
else
    echo "⚠️ Skipping game binary (RUN_BINARY != 1 or binary missing)."
    echo "The VNC session is running. Please set RUN_BINARY=1 and ensure the game is built."
    wait
fi