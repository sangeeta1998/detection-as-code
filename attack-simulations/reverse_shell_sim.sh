set -eu

TARGET_HOST="${1:-lab-listener}"
TARGET_PORT="${2:-4444}"

echo "[lab] simulating outbound shell connection to ${TARGET_HOST}:${TARGET_PORT}"

#A shell built-in TCP connection (bash's /dev/tcp) is enough to trigger the
# "shell process, outbound connect" pattern the Falco rule looks for,
#without needing netcat installed in the image.
sh -c "exec 3<>/dev/tcp/${TARGET_HOST}/${TARGET_PORT} && echo lab-probe >&3" || true

echo "[lab] simulation complete"
