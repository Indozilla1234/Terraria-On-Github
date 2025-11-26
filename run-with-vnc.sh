#!/bin/bash

# --- Configuration Variables ---
# Set the desired virtual display number (must be >= 1)
readonly DISPLAY_NUM=100
# The VNC server port (websockify will proxy to this)
readonly VNC_PORT=5901
# The port noVNC will connect to (forward this one in Codespaces)
readonly WEBSOCKIFY_PORT=6080

# --- Function to Clean Up Background Processes ---
cleanup() {
    echo -e "\n🛑 Shutting down VNC environment and cleaning up..."
    # Kill background processes started by the script (Xvfb, x11vnc, websockify)
    kill ${XVFB_PID} ${X11VNC_PID} ${WEBSOCKIFY_PID} 2>/dev/null || true
    # Kill the game if it is still running
    pkill -f Terraria.MonoGame 2>/dev/null || true
    # Remove stale X locks and sockets
    rm -f /tmp/.X${DISPLAY_NUM}-lock 2>/dev/null || true
    # Sudo is often needed for /tmp/.X11-unix, but we'll try without it first
    # This assumes the user running the script has permission to clean up their own sockets.
    # sudo rm -rf /tmp/.X11-unix 2>/dev/null || true
    echo "Cleanup complete."
    exit 0
}

# Trap signals (like Ctrl+C or kill) and execute the cleanup function
trap cleanup SIGINT SIGTERM EXIT

# --- 1. Environment Setup ---
echo "⚙️ Setting up X11 environment..."

# Export the DISPLAY variable for all subsequent graphical commands
export DISPLAY=:${DISPLAY_NUM}

# Attempt to ensure X11 socket permissions
# Note: In most modern Linux/Docker environments, this shouldn't require sudo
mkdir -p /tmp/.X11-unix 2>/dev/null || true
chmod 1777 /tmp/.X11-unix 2>/dev/null || true

# --- 2. Start Virtual Display and VNC ---

# Start Xvfb (Virtual Framebuffer)
echo "🖥️ Starting Xvfb on display :${DISPLAY_NUM} (1280x720x24)..."
Xvfb :${DISPLAY_NUM} -screen 0 1280x720x24 -nolisten tcp +extension COMPOSITE &
XVFB_PID=$!
sleep 2 # Give Xvfb time to initialize

# Start x11vnc (VNC server pointing to the Xvfb display)
echo "📡 Starting x11vnc on port ${VNC_PORT}..."
x11vnc -display :${DISPLAY_NUM} -nopw -forever -shared -rfbport ${VNC_PORT} -noxdamage -repeat -noclipboard -quiet &
X11VNC_PID=$!
sleep 1

# Start websockify (VNC to WebSockets Proxy)
# We only start the necessary port (6080) for simplicity.
echo "🌐 Starting websockify on ${WEBSOCKIFY_PORT} (proxies to VNC port ${VNC_PORT})..."
python3 -m websockify ${WEBSOCKIFY_PORT} localhost:${VNC_PORT} --web=/usr/share/novnc > /tmp/websockify.log 2>&1 &
WEBSOCKIFY_PID=$!
sleep 1

# --- 3. Graphics Environment Exports (For Headless/Software Rendering) ---
echo "✨ Setting environment variables for software rendering (MonoGame)..."
export LIBGL_ALWAYS_INDIRECT=1      # Force indirect GLX/OpenGL
export GALLIUM_DRIVER=swr           # Force Software Rasterizer
export MESA_GL_VERSION_OVERRIDE=3.0 # Override GL version for compatibility
export XLIB_SKIP_ARGB_VISUALS=1
export __GLX_VENDOR_LIBRARY_NAME=mesa
export HEADLESS_TERRARIA=1          # Custom flag for the game binary

# --- 4. Game Launch and Execution ---
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Terraria - VNC Session is Active                              ║"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║  Access via browser: http://localhost:${WEBSOCKIFY_PORT}/vnc.html        ║"
echo "║  (Remember to forward port ${WEBSOCKIFY_PORT} in your environment!)      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

cd /workspaces/Terraria-On-Github

# --- Check 1: Define the Game Binary Path ---
GAME_BINARY="./bin/Release/net8.0/Terraria.MonoGame"

# --- Check 2: Check for Game Binary and RUN_BINARY flag ---
if [ "${RUN_BINARY}" = "1" ] && [ -x "${GAME_BINARY}" ]; then
    echo "🎮 RUN_BINARY=1 set and executable found. Starting Terraria..."
    
    # Execute the game. We pipe its stdout/stderr to the script's output.
    # The 'exec' command replaces the current shell process with the game process.
    # This simplifies signal handling (Ctrl+C now targets the game directly).
    exec "${GAME_BINARY}"
    
    # If 'exec' fails (e.g., file not found or permission error), the script continues here.
    echo "ERROR: Failed to start the game binary at ${GAME_BINARY}."
    
else
    # Your original 'skip' logic, slightly improved.
    echo "⚠️ Skipping game binary (RUN_BINARY != 1 or binary missing)."
    echo "The VNC session is running. Please set RUN_BINARY=1 and ensure the game is built."
    
    # Keep the script running to maintain the VNC session
    wait # Wait for any background job (Xvfb/x11vnc) to finish.
fi