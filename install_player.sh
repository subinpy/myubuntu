#!/usr/bin/env bash
# sudo 없이 mp4 재생기 (ffplay) 설치 + 더블클릭 연결.
#   bash install_player.sh
# - conda 환경 'player' 에 conda-forge ffmpeg (ffplay·ffmpeg 포함, libx264 있는 GPL 빌드) 를 깐다.
#   ※ conda-forge mpv 는 X11/Wayland 출력 없이 빌드돼 창이 안 뜸 — 쓰지 않는다.
# - ~/.local/share/applications 에 실행 항목을 만들고 mp4·mkv·webm·mov·avi 기본 앱으로 지정.
#   ※ Exec 의 %f 는 한 번만 (두 번 쓰면 실행 항목이 무효가 돼 더블클릭이 아무 반응 없음).
set -euo pipefail

ENV_NAME="${PLAYER_ENV:-player}"
CONDA_BASE="$(conda info --base 2>/dev/null || true)"
for c in "$CONDA_BASE" "$HOME/anaconda3" "$HOME/miniconda3" "$HOME/miniforge3"; do
  if [ -n "$c" ] && [ -f "$c/etc/profile.d/conda.sh" ]; then CONDA_BASE="$c"; break; fi
done
[ -f "$CONDA_BASE/etc/profile.d/conda.sh" ] || { echo "conda 를 못 찾음 (anaconda/miniconda/miniforge 설치 필요)"; exit 1; }
source "$CONDA_BASE/etc/profile.d/conda.sh"

if [ ! -x "$CONDA_BASE/envs/$ENV_NAME/bin/ffplay" ]; then
  echo "[1/3] conda 환경 '$ENV_NAME' 에 ffmpeg (ffplay) 설치"
  if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    conda install -y -q -n "$ENV_NAME" -c conda-forge ffmpeg
  else
    conda create -y -q -n "$ENV_NAME" -c conda-forge ffmpeg
  fi
else
  echo "[1/3] 이미 설치됨: $CONDA_BASE/envs/$ENV_NAME/bin/ffplay"
fi
FFPLAY="$CONDA_BASE/envs/$ENV_NAME/bin/ffplay"
[ -x "$FFPLAY" ] || { echo "ffplay 가 없음: $FFPLAY"; exit 1; }

echo "[2/3] 실행 항목 만들기"
APPS="$HOME/.local/share/applications"
mkdir -p "$APPS"
cat > "$APPS/ffplay-conda.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=동영상 재생 (ffplay)
Comment=conda 환경 $ENV_NAME 의 ffplay (sudo 없이 설치)
Exec=$FFPLAY -x 1280 -loglevel quiet %f
Icon=video-x-generic
Terminal=false
Categories=AudioVideo;Video;Player;
MimeType=video/mp4;video/x-matroska;video/webm;video/quicktime;video/x-msvideo;
EOF
command -v desktop-file-validate >/dev/null && desktop-file-validate "$APPS/ffplay-conda.desktop"
command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" || true

echo "[3/3] 기본 앱으로 지정"
for m in video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo; do
  xdg-mime default ffplay-conda.desktop "$m"
done
echo "video/mp4 기본 앱: $(xdg-mime query default video/mp4)"
cat <<'EOF'

완료 — mp4 를 더블클릭하면 ffplay 로 열림 (터미널: ffplay 파일.mp4 대신 위 경로).
  Space 재생/멈춤 · ←/→ 10 초 · ↑/↓ 1 분 · 마우스 오른쪽 클릭 그 위치로 · f 전체 화면 · q 닫기
EOF
