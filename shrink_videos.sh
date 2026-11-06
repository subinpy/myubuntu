#!/usr/bin/env bash
# 폴더 안 영상을 작게 다시 인코딩한 사본을 만들고 zip 으로 묶는다. 원본은 건드리지 않는다.
#   bash shrink_videos.sh <폴더> [출력.zip]
#   예: bash shrink_videos.sh ~/0_subiny/PiH/1106            → ~/0_subiny/PiH/1106.zip
# 설정 (환경 변수로 바꿈):
#   MAX_SIDE=1280   긴 변 최대 [px] (원본이 더 작으면 그대로)
#   FPS=15          프레임 [fps]
#   CRF=32          H.264 화질 (낮을수록 좋고 큼. 23 ≈ 원본 수준, 28 보통, 32 작게)
#   KEEP_AUDIO=0    1 이면 소리 유지 (AAC 96k)
# 2026-11-06 기본값으로 화면 녹화 9 GB → 25 MB (2560×2560 30 fps 1–2 GB 영상이 각 2 MB 안팎).
# 화면 녹화는 화면이 거의 안 변해 아주 잘 줄어든다. 글씨가 흐리면 MAX_SIDE=2560 FPS=30 CRF=26 정도로.
# ffmpeg 는 install_player.sh 가 깐 conda 환경 (player) 것을 쓴다 (FFMPEG=경로 로 바꿀 수 있음).
set -euo pipefail

SRC="${1:?usage: shrink_videos.sh <폴더> [출력.zip]}"
SRC="$(cd "$SRC" && pwd)"
OUT="${2:-$SRC.zip}"
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac
MAX_SIDE="${MAX_SIDE:-1280}"; FPS="${FPS:-15}"; CRF="${CRF:-32}"; KEEP_AUDIO="${KEEP_AUDIO:-0}"
EXTS="mp4 mkv mov avi webm m4v"

if [ -z "${FFMPEG:-}" ]; then
  for c in "$(conda info --base 2>/dev/null || true)" "$HOME/anaconda3" "$HOME/miniconda3" "$HOME/miniforge3"; do
    if [ -n "$c" ] && [ -x "$c/envs/${PLAYER_ENV:-player}/bin/ffmpeg" ]; then FFMPEG="$c/envs/${PLAYER_ENV:-player}/bin/ffmpeg"; break; fi
  done
fi
FFMPEG="${FFMPEG:-$(command -v ffmpeg || true)}"
[ -x "$FFMPEG" ] || { echo "ffmpeg 를 못 찾음 — install_player.sh 를 먼저 실행"; exit 1; }
ENC="$("$FFMPEG" -hide_banner -encoders 2>/dev/null || true)"     # 변수로 받음 (pipefail + grep -q 면 SIGPIPE 로 거짓 실패)
case "$ENC" in *libx264*) ;; *) echo "이 ffmpeg 에 libx264 가 없음: $FFMPEG"; exit 1 ;; esac
command -v zip >/dev/null || { echo "zip 이 없음 (python3 로 대신 묶음)"; }
[ -e "$OUT" ] && { echo "이미 있음: $OUT — 다른 이름을 주거나 직접 지운 뒤 다시"; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf -- "$WORK"' EXIT          # mktemp 가 만든 임시 폴더만 지운다
NAME="$(basename "$SRC")"
DST="$WORK/$NAME"
echo "원본 $SRC ($(du -sh "$SRC" | cut -f1)) → $OUT  [긴 변 ≤ $MAX_SIDE px, $FPS fps, CRF $CRF]"

is_video() { local e="${1##*.}"; e="${e,,}"; for x in $EXTS; do [ "$e" = "$x" ] && return 0; done; return 1; }

(cd "$SRC" && find . -type d) | while IFS= read -r d; do mkdir -p "$DST/$d"; done
(cd "$SRC" && find . -type f) | while IFS= read -r f; do
  if is_video "$f"; then
    out="$DST/${f%.*}.mp4"
    if [ "$KEEP_AUDIO" = "1" ]; then A=(-c:a aac -b:a 96k); else A=(-an); fi
    "$FFMPEG" -nostdin -hide_banner -loglevel error -y -i "$SRC/$f" \
      -vf "scale='if(gt(iw,ih),min($MAX_SIDE,iw),-2)':'if(gt(iw,ih),-2,min($MAX_SIDE,ih))',fps=$FPS" \
      -c:v libx264 -preset medium -crf "$CRF" -pix_fmt yuv420p "${A[@]}" -movflags +faststart "$out"
    echo "  $f  $(du -h "$SRC/$f" | cut -f1) → $(du -h "$out" | cut -f1)"
  else
    cp -p "$SRC/$f" "$DST/$f"
  fi
done

if command -v zip >/dev/null; then
  (cd "$WORK" && zip -qr "$OUT" "$NAME")
else
  python3 -c "import shutil,sys; shutil.make_archive(sys.argv[1][:-4], 'zip', sys.argv[2], sys.argv[3])" "$OUT" "$WORK" "$NAME"
fi
python3 -c "import zipfile,sys; bad=zipfile.ZipFile(sys.argv[1]).testzip(); print('zip 검사:', 'OK' if bad is None else 'BAD '+bad)" "$OUT"
echo "완료: $OUT ($(du -h "$OUT" | cut -f1)). 원본 폴더는 그대로 — 확인한 뒤 직접 지우세요."
