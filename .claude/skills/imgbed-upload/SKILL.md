---
name: imgbed-upload
description: 把 inktrace 部落格的配圖上傳到 CloudFlare-ImgBed（images.rxchi1d.me）、驗證上傳結果、取得文章要用的網址。只要使用者提到上傳圖片／配圖到 imgbed、替換或更新線上圖片、要把新圖放上線，或詢問文章圖片網址的格式與來源，都應該使用這個 skill——即使他們說的是「推 R2」或「上傳 CDN」。不適用於 rclone 的 r2:inktrace-files（那是舊的 cdn.rxchi1d.me）。
---

# ImgBed 圖片上傳

文章配圖放在 CloudFlare-ImgBed（`https://images.rxchi1d.me`），不是 rclone 的
`r2:inktrace-files`。後者是舊 CDN `cdn.rxchi1d.me`，網址格式不同，不要把新圖傳過去。

## 前置條件

- repo 根目錄有 `.env`，內含 `IMGBED_AUTH_CODE`。`.env` 已被 gitignore。
- 讀取時必須用 `^IMGBED_AUTH_CODE=` 錨定行首。`.env` 可能保留被註解的舊 token，
  不錨定會抓到兩行，造成 `401` 或 curl 錯誤。
- 不得把 token 印到輸出、commit 或回覆裡。檢查 `.env` 時只看變數名稱，例如
  `rg -o '^[A-Z_]+' .env`。
- 圖片必須先通過人工過目（見記憶 `visual-output-human-review-gate`），再上傳。

## 上傳

```bash
auth_code=$(rg '^IMGBED_AUTH_CODE=' .env | cut -d= -f2-)
curl -s -X POST "https://images.rxchi1d.me/upload?authCode=${auth_code}&uploadFolder=inktrace/<category>/<slug>" \
  -F "file=@<本地檔路徑>"
```

- `<category>/<slug>` 與文章路徑一致，例如 `engineering/immich-geodata-tech-01-reverse-geocoding`。
- 一次一個檔案。多張圖逐張呼叫。
- 伺服器會在檔名前加 13 位毫秒時間戳，所以每次上傳都是新網址，不會覆蓋舊檔。

回傳是 JSON 陣列，文章要用 `publicUrl`：

```json
[{"src":"/file/inktrace/<category>/<slug>/1791784365453_name.png",
  "publicUrl":"https://images.rxchi1d.me/file/inktrace/<category>/<slug>/1791784365453_name.png"}]
```

## 驗證

上傳後下載回來，比對本地檔的 md5：

```bash
curl -s "<publicUrl>" | md5sum
md5sum <本地檔路徑>
```

兩個值必須相同。

## 更新既有圖片

上傳永遠不會覆蓋。同名檔存在時，伺服器會改存成 `name(1).ext`。所以有兩種做法：

**做法 A：換網址（預設）**

1. 上傳新圖，取得新的 `publicUrl`。
2. 把 `index.md` 與 `index.en.md` 的圖片網址換成新網址，需要時一併修改圖說。
3. 舊圖留在 ImgBed，等有刪除權限時再清掉。刪除前，必須確認 `main` 已不再引用它，
   也就是含新網址的 PR 已合併。

**做法 B：沿用原路徑（文章網址不變）**

1. 備份舊圖並確認 md5：`curl -s <舊網址> -o backup.png`。
2. 刪除舊檔（需要 `delete` 權限，見下一節）。
3. 把新圖複製成舊檔名（含時間戳前綴），用 `uploadNameType=origin` 上傳：

   ```bash
   curl -s -X POST -H "Authorization: Bearer ${auth_code}" \
     "https://images.rxchi1d.me/upload?uploadFolder=inktrace/<category>/<slug>&uploadNameType=origin" \
     -F "file=@<以舊檔名命名的新圖>"
   ```

4. 回傳的 `src` 必須與舊路徑完全相同。
5. 用 `?x=$RANDOM` 之類的查詢參數繞過快取，比對 md5。

**快取限制（2026-10-12 實測）**：沿用原路徑後，原站已是新圖，但 Cloudflare 邊緣
仍回舊圖（`cf-cache-status: HIT`、`age: 63199`），瀏覽器端 `cache-control` 為
`max-age=2592000`（30 天）。所以做法 B 對讀者不會立即生效。需要立即生效時，
改用做法 A 的新網址，或到 Cloudflare 後台 purge 該網址（本 repo 沒有 Cloudflare API token）。

## 權限與驗證方式

`.env` 的 token 有兩種，驗證方式不同：

| token 類型 | 驗證方式 | 能做的事 |
| :--- | :--- | :--- |
| 舊的上傳碼（authCode） | URL 參數 `authCode=` | 只能上傳 |
| API token | 標頭 `Authorization: Bearer <token>` | 依勾選的權限 |

API token 不能放在 `authCode=` 參數。2026-10-12 實測：同一個全權限 token，
用 `Authorization: Bearer` 呼叫 `list` 回 `200`，用 `authCode=` 回 `401`。

管理 API 依路徑要求不同權限：

| 路徑 | 需要權限 |
| :--- | :--- |
| `GET /api/manage/list?dir=<資料夾>&count=50` | `list` |
| `DELETE /api/manage/delete/{path}`（路徑的 `/` 寫成 `,`） | `delete` |
| 其他 `/api/manage/*`（`move`、`rename` 等） | `manage` |

已實測：`list`（回 `.files[].name`）、`delete`（回 `{"success":true,"fileId":…}`）、
`upload` 搭配 Bearer。刪除不可逆，執行前必須得到使用者明確同意，並先備份。

## 常見錯誤

- 把圖傳到 `r2:inktrace-files`：網址不是 `images.rxchi1d.me`，與文章其他圖不一致。
- 假設重傳同名檔會覆蓋：不會，伺服器會存成 `name(1).ext`。要沿用路徑必須先刪除。
- 用 `grep IMGBED_AUTH_CODE` 取 token：會連註解行一起抓到。
- 在 `uploadFolder` 用錯 slug：圖會落在別的資料夾，網址與文章路徑對不上。
