set -eu

TARGET_DIR="${1:-/data/lab-watched}"
FILE_COUNT="${2:-200}"

mkdir -p "${TARGET_DIR}"
echo "[lab] rewriting ${FILE_COUNT} files under ${TARGET_DIR}"

i=1
while [ "$i" -le "$FILE_COUNT" ]; do
  echo "lab-rewrite-$(date +%s%N)" > "${TARGET_DIR}/lab-file-${i}.txt"
  i=$((i + 1))
done

echo "[lab] simulation complete"
