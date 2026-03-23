# MediaDiary iOS

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
