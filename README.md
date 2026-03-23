# MediaDiary iOS

## 1. 서버 실행

```bash
cd /Users/nayoon/개발/python/media_diary
sh run.sh
```

> `uvicorn` 명령어가 PATH에 없으므로 `run.sh`가 `python3 -m uvicorn`으로 실행합니다.

서버가 뜨면 → `http://localhost:8001` 접속해서 확인

---

## 2. Xcode 프로젝트 만들기

1. Xcode 열기
2. **File → New → Project**
3. **iOS → App** 선택 후:
   - Product Name: `MediaDiary`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Minimum Deployments: `iOS 17.0`
4. 저장 위치: `/Users/nayoon/개발/MediaDiaryiOS/` (이 폴더 안)

---

## 3. Swift 파일 추가

Xcode가 자동 생성한 파일 **2개 삭제**:
- `ContentView.swift` (Move to Trash)
- `[앱이름]App.swift` (Move to Trash)

그 다음 **Project Navigator에서 MediaDiary 그룹 우클릭 → Add Files to "MediaDiary"**:

```
MediaDiary/
├── MediaDiaryApp.swift          ← 추가
├── Models/
│   └── Work.swift               ← 추가
├── Services/
│   └── APIService.swift         ← 추가
└── Views/
    ├── ContentView.swift        ← 추가
    ├── Home/
    │   └── HomeView.swift       ← 추가
    ├── Library/
    │   └── LibraryView.swift    ← 추가
    ├── Search/
    │   └── SearchView.swift     ← 추가
    ├── Detail/
    │   └── DetailView.swift     ← 추가
    └── Components/
        ├── PosterView.swift     ← 추가
        └── AddWorkSheet.swift   ← 추가
```

> 팁: 폴더째로 드래그하면 한 번에 추가 가능. **"Create groups"** 선택.

---

## 4. Info.plist — HTTP 허용

Xcode Project Navigator에서 `Info.plist` 클릭 후 `+` 버튼:

| Key | Type | Value |
|-----|------|-------|
| App Transport Security Settings | Dictionary | |
| &nbsp;&nbsp;&nbsp;Allow Local Networking | Boolean | YES |

또는 `Info.plist`를 **Source Code로 열기** 후 `<dict>` 안에 붙여넣기:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

---

## 5. 실행

1. 상단 시뮬레이터 선택 (iPhone 16 등)
2. `Cmd + R`

---

## API 키 설정 (선택사항)

영화/드라마/소설/웹툰 **검색 기능** 사용 시 필요:

```bash
# /Users/nayoon/개발/python/media_diary/.env
TMDB_API_KEY=여기에입력    # https://www.themoviedb.org/settings/api (무료)
KAKAO_API_KEY=여기에입력   # https://developers.kakao.com (무료)
```

---

## 화면 구성

| 탭 | 기능 |
|---|---|
| 🏠 홈 | 통계 카드, 최근 기록 5개, AI 추천 작품 |
| 📚 라이브러리 | 전체 목록, 타입/상태 필터, 스와이프 삭제, pull-to-refresh |
| 🔍 검색 | 영화·드라마·애니·소설·웹툰 검색 → 별점·상태·태그 입력 후 추가 |
| 상세 | 포스터, 리뷰, 태그, 줄거리 + 편집/삭제 |

## 상태 값 (백엔드 동일)

| 값 | 라벨 |
|---|---|
| `completed` | 완료 |
| `in_progress` | 보는중 |
| `want` | 보고싶음 |
| `dropped` | 하차 |
