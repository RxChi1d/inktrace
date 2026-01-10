## ADDED Requirements
### Requirement: Tags Terms Inline Layout
Tags 的 taxonomy 列表頁 MUST 呈現 inline tag cloud 佈局，且單一 tag item 不得被強制固定寬度。

#### Scenario: Tags 列表為 inline tag cloud
- **WHEN** 使用 `terms` 模板渲染 tags 列表頁
- **THEN** tag items 必須以 inline 方式流動排列
- **AND** tag items 不得被 `w-full`/`sm:w-1/2` 類型的固定寬度 class 限制

### Requirement: Categories Terms Card Layout
Categories 的 taxonomy 列表頁 MUST 呈現卡片式 grid 佈局，並顯示 icon 與 Post/Posts 單複數文字。

#### Scenario: Categories 列表為卡片式 grid
- **WHEN** 使用 `terms` 模板渲染 categories 列表頁
- **THEN** 每個 category 必須以卡片形式排列在 grid 佈局中
- **AND** 卡片內需顯示 category icon 與文章數量（Post/Posts 單複數）

### Requirement: Icon 顏色隨主題切換
Taxonomy icon MUST 隨深/淺色模式切換而同步變化。

#### Scenario: 深色模式 icon 顏色一致
- **WHEN** 站點切換為 dark mode
- **THEN** taxonomy icon 顏色 MUST 與對應文字顏色一致
- **AND** 不得出現 icon 顏色固定不變的情況

### Requirement: Categories Icon 與文字間距
Categories 卡片內 icon 與文字 MUST 保持清楚的視覺間距，避免 icon 緊貼文字影響可讀性。

#### Scenario: Icon 與文字間距一致
- **WHEN** 顯示 categories 列表頁卡片
- **THEN** icon 與分類文字之間 MUST 有一致的間距
- **AND** 間距需足以避免 icon 與文字視覺黏連

### Requirement: Term 文章列表不受影響
Taxonomy 列表頁的樣式 MUST NOT 影響 term 文章列表頁的文章卡片樣式。

#### Scenario: Term 頁面樣式隔離
- **WHEN** 進入任一 taxonomy term 文章列表頁
- **THEN** 文章卡片的間距與排版 MUST 維持 Blowfish 原生樣式
- **AND** taxonomy list 的 CSS 不得汙染 term 文章列表
