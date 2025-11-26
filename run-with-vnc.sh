#!/bin/bash

# Kill any existing processes
echo "Cleaning up old processes..."
pkill -9 Xvfb 2>/dev/null || true
pkill -9 x11vnc 2>/dev/null || true
pkill -9 websockify 2>/dev/null || true
pkill -9 Terraria.MonoGame 2>/dev/null || true
rm -f /tmp/.X*-lock 2>/dev/null || true
sudo rm -rf /tmp/.X11-unix 2>/dev/null || true
sleep 1

DISPLAY_NUM=100
VNC_PORT=5901
export DISPLAY=:${DISPLAY_NUM}

# Fix X11 socket permissions
echo "Setting up X11 environment..."
sudo mkdir -p /tmp/.X11-unix 2>/dev/null || true
sudo chmod 1777 /tmp/.X11-unix 2>/dev/null || true

# Start Xvfb
echo "Starting Xvfb on display :${DISPLAY_NUM}..."
Xvfb :${DISPLAY_NUM} -screen 0 1280x720x24 -nolisten tcp +extension COMPOSITE &
XVFB_PID=$!
sleep 3

# Start x11vnc (connecting to running Xvfb)
echo "Starting x11vnc on port ${VNC_PORT}..."
DISPLAY=:${DISPLAY_NUM} x11vnc -display :${DISPLAY_NUM} -nopw -forever -shared -rfbport ${VNC_PORT} -noxdamage -repeat -noclipboard &
X11VNC_PID=$!
sleep 2

# Start websockify instances for noVNC on ports 5090 and 5091
echo "Starting websockify on ports 5090 and 5091 (mapping to VNC port ${VNC_PORT})..."
WEBSOCKIFY_PIDS=""
for WS_PORT in 5090 5091 6080; do
	LOGFILE="/tmp/websockify_${WS_PORT}.log"
	echo "  -> launching websockify ${WS_PORT} -> localhost:${VNC_PORT} (log: ${LOGFILE})"
	# Start websockify in background and capture PID
	python3 -m websockify ${WS_PORT} localhost:${VNC_PORT} --web=/usr/share/novnc > "${LOGFILE}" 2>&1 &
	PID=$!
	WEBSOCKIFY_PIDS="${WEBSOCKIFY_PIDS} ${PID}"
	# small gap to avoid race
	sleep 1
done
echo "websockify PIDs:${WEBSOCKIFY_PIDS}"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Terraria - Running in Codespace with VNC                      ║"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║  VNC Port:    ${VNC_PORT}                                      ║"
echo "║  Web:         http://localhost:6080/vnc.html                   ║"
echo "║  (Forward port 6080 in Codespaces for browser access)         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Force software rendering and disable OpenGL where possible
export DISPLAY=:${DISPLAY_NUM}
export LIBGL_ALWAYS_INDIRECT=1
export GALLIUM_DRIVER=swr
export MESA_GL_VERSION_OVERRIDE=3.0
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6
export XLIB_SKIP_ARGB_VISUALS=1
export __GLX_VENDOR_LIBRARY_NAME=mesa
export HEADLESS_TERRARIA=1

cd /workspaces/Terraria-On-Github

		# Run game with error output (skip running binary by default to avoid executing an outdated build)
		echo "Starting Terraria (headless mode)..."
		if [ "${RUN_BINARY}" = "1" ] && [ -x ./bin/Release/net8.0/Terraria.MonoGame ]; then
			echo "RUN_BINARY=1 set — launching game binary"
			./bin/Release/net8.0/Terraria.MonoGame 2>&1 || true
		else
			echo "Skipping game binary (either RUN_BINARY!=1 or binary missing). Keeping session alive..."
			# Keep the script running so VNC stays available; replace with actual binary after rebuilding
			sleep infinity
		fi

# Cleanup
echo "Shutting down..."
kill $XVFB_PID $X11VNC_PID 2>/dev/null || true
if [ -n "${WEBSOCKIFY_PIDS}" ]; then
	for p in ${WEBSOCKIFY_PIDS}; do
		kill ${p} 2>/dev/null || true
	done
fi
exit 0
