# 우분투에서 mp4 재생, 영상 크기 줄이려고 만든 레포

Ubuntu 에서 자주 쓰는 작은 도구. sudo 없이 conda 만 있으면 된다 (Ubuntu 20.04 에서 확인).

## 1. mp4 재생기 — `install_player.sh`

```bash
bash install_player.sh
```

- conda 환경 `player` 에 conda-forge **ffmpeg** (ffplay 포함) 를 깔고, mp4·mkv·webm·mov·avi 를 더블클릭하면 ffplay 로 열리게 연결한다.
- 조작: Space 재생/멈춤 · ←/→ 10 초 · ↑/↓ 1 분 · 마우스 오른쪽 클릭 그 위치로 · f 전체 화면 · q 닫기
- 버튼·진행 막대가 있는 재생기가 필요하면 `sudo apt install vlc`.

겪었던 문제:
- 기본 동영상 앱 (Totem) 은 H.264 코덱 (`gstreamer1.0-libav`) 이 없으면 mp4 를 못 연다 — 설치에 sudo 필요.
- conda-forge **mpv** 는 X11/Wayland 출력 없이 빌드돼 `Error opening/initializing the selected video_out` 로 창이 안 뜬다.
- `.desktop` 의 `Exec` 에 `%f` 를 두 번 쓰면 실행 항목이 무효가 돼 더블클릭이 아무 반응이 없다 (`desktop-file-validate` 로 확인).

## 2. 영상 줄여서 폴더 압축 — `shrink_videos.sh`

```bash
bash shrink_videos.sh <폴더> [출력.zip]          # 기본 출력 = <폴더>.zip
MAX_SIDE=2560 FPS=30 CRF=26 bash shrink_videos.sh <폴더>   # 화질 우선
```

- 폴더 구조 그대로 사본을 만들며 영상 (mp4 mkv mov avi webm m4v) 만 H.264 로 다시 인코딩하고, 나머지 파일은 그대로 복사해 zip 으로 묶는다.
  **원본은 건드리지 않는다** — 결과를 확인한 뒤 직접 지울 것.
- 기본: 긴 변 ≤ 1280 px, 15 fps, CRF 32, 소리 없음 (`KEEP_AUDIO=1` 이면 유지). ffmpeg 는 `install_player.sh` 가 깐 것을 쓴다.
- 예: 화면 녹화 12 개 9 GB → zip 25 MB (2560×2560 30 fps 1–2 GB 영상이 각 2 MB 안팎). 화면 녹화는 거의 안 변해서 잘 줄어든다.
  해상도 절반·15 fps 라 작은 글씨는 흐려질 수 있다.
