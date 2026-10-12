#!/usr/bin/env python3
"""量測生成的示意圖，取代目測。

這支腳本存在的理由：目測會錯。開發這套流程時，一張圖被目測判定「刻度偏離
交界約 90px」而重跑了四輪，實際量下來偏差是 1px——原圖從頭到尾都是對的。
反過來也發生過：目測「內容填滿畫布」的版本，量出來文字只佔卡片寬度 32%。

所以凡是牽涉位置、比例、覆蓋率的判斷，一律跑這支腳本，不要用看的。

用法：
    python3 verify_diagram.py IMAGE [--render-dir DIR] [--min-ink-coverage 0.55]

輸出各項量測值與警告。exit code 1 表示有指標未達標。
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

# Reason: 卡片底色（淡珊瑚、淡灰、淡綠）在 RGB 上都 >= 240，但仍非純白。
# 用兩個門檻分開量：NEAR_WHITE 抓「有沒有東西」，INK 抓「是不是文字」。
# 只量 NEAR_WHITE 會得到「卡片有多寬」而非「內容有多滿」——這正是當初
# 誤判 94.1% 達標的原因。
NEAR_WHITE = 248
INK = 140

# 部落格實際顯示寬度。容器 .max-w-prose-xl 為 90ch ≈ 888px，
# 圖片多半設 width:90% → 799px。截圖像素不等於這個值，別拿截圖推算。
DISPLAY_WIDTHS = (799, 540)


def _bbox(img: Image.Image, threshold: int) -> tuple[int, int, int, int] | None:
    """回傳灰階低於 threshold 的像素外框 (x0, y0, x1, y1)。"""
    gray = img.convert("L")
    mask = gray.point(lambda v: 255 if v < threshold else 0)
    return mask.getbbox()


def _row_ink_extent(img: Image.Image, y: int, threshold: int) -> tuple[int, int] | None:
    """回傳某一列上，墨跡的最左與最右 x。"""
    gray = img.convert("L")
    w = gray.width
    px = gray.load()
    xs = [x for x in range(w) if px[x, y] < threshold]
    return (xs[0], xs[-1]) if xs else None


def measure(path: Path, min_ink_coverage: float, render_dir: Path | None) -> int:
    img = Image.open(path).convert("RGB")
    w, h = img.size
    problems: list[str] = []   # 阻斷：構圖有實質缺陷
    notes: list[str] = []      # 非阻斷：值得知道但不擋上稿

    print(f"檔案      {path.name}")
    print(f"尺寸      {w} x {h}  (比例 {w / h:.2f}:1)")
    size_kb = path.stat().st_size / 1024
    print(f"檔案大小  {size_kb:.0f} KB")
    if size_kb > 500:
        notes.append(
            f"檔案 {size_kb:.0f} KB，而顯示寬度只有 799px。"
            "轉 WebP 可降到約五分之一，但那屬於站台效能議題，不擋這張圖上稿。"
        )

    # --- 兩種 bbox，務必分開看 ---
    nw = _bbox(img, NEAR_WHITE)
    ink = _bbox(img, INK)
    if nw is None or ink is None:
        print("警告：圖片近乎全白，無法量測。")
        return 1

    nw_w = nw[2] - nw[0]
    ink_w = ink[2] - ink[0]
    print()
    print(f"非白區域  {nw_w}x{nw[3] - nw[1]}  佔畫布寬 {nw_w / w:.1%}")
    print("          ↑ 這是代理量，只說明「色塊有多寬」，不代表內容有多滿")
    print(f"深色墨跡  {ink_w}x{ink[3] - ink[1]}  佔畫布寬 {ink_w / w:.1%}")
    print("          ↑ 這才是文字實際佔用的範圍")

    # --- 逐列量文字覆蓋率，抓「寬扁空盒」 ---
    # Reason: 卡片被拉到滿版但文字只佔左側三分之一時，非白 bbox 會顯示 94%
    # 而看起來達標。逐列比較墨跡寬度與非白寬度才抓得到。
    sparse_rows = 0
    sampled = 0
    for y in range(nw[1], nw[3], max(1, (nw[3] - nw[1]) // 60)):
        block = _row_ink_extent(img, y, NEAR_WHITE)
        text = _row_ink_extent(img, y, INK)
        if not block or not text:
            continue
        block_w = block[1] - block[0]
        text_w = text[1] - text[0]
        if block_w < w * 0.3:
            continue  # 跳過非卡片列（標題、說明文字）
        sampled += 1
        if text_w / block_w < min_ink_coverage:
            sparse_rows += 1

    if sampled:
        ratio = sparse_rows / sampled
        print()
        print(f"稀疏列    {sparse_rows}/{sampled} 列的文字寬度不足色塊寬度的 "
              f"{min_ink_coverage:.0%}")
        if ratio > 0.4:
            problems.append(
                f"{ratio:.0%} 的色塊列是「寬扁空盒」——色塊拉滿但文字只佔一小段。"
                "這通常表示畫框比例不配合內容形狀：縱向流程塞進 16:9，"
                "多出來的寬度會變成卡片內的空白。改比例，不要砍內容。"
            )

    # --- 產生實際顯示尺寸的預覽供人眼判讀 ---
    if render_dir:
        render_dir.mkdir(parents=True, exist_ok=True)
        for dw in DISPLAY_WIDTHS:
            out = render_dir / f"{path.stem}@{dw}px.png"
            img.resize((dw, round(h * dw / w)), Image.LANCZOS).save(out)
            print(f"預覽      {out}")
        print("          ↑ 用這兩張確認最小字級與 badge 是否可讀")

    print()
    if notes:
        print("提示（不擋上稿）：")
        for n in notes:
            print(f"  - {n}")
        print()
    if problems:
        print("需要處理：")
        for p in problems:
            print(f"  - {p}")
        return 1
    print("構圖量測未發現問題。位置類斷言仍需用 --probe 逐條核對。")
    return 0


def probe(path: Path, xs: list[int], out: Path) -> None:
    """把指定的 x 座標畫成紅線疊在圖上，用來驗證位置量測是否可信。

    量到的數字要畫回圖上看過才算數——偵測邏輯可能抓到邊框而非刻度線。
    """
    from PIL import ImageDraw

    img = Image.open(path).convert("RGB")
    draw = ImageDraw.Draw(img)
    for x in xs:
        draw.line([(x, 0), (x, img.height)], fill=(255, 0, 0), width=3)
    img.save(out)
    print(f"已將 x={xs} 畫為紅線 → {out}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("image", type=Path)
    ap.add_argument("--render-dir", type=Path, default=None,
                    help="輸出 799px / 540px 預覽的目錄")
    ap.add_argument("--min-ink-coverage", type=float, default=0.55,
                    help="單列文字寬度相對色塊寬度的下限（預設 0.55）")
    ap.add_argument("--probe", type=int, nargs="+", default=None,
                    help="把這些 x 座標畫成紅線輸出，驗證位置量測")
    args = ap.parse_args()

    if not args.image.exists():
        print(f"找不到檔案：{args.image}", file=sys.stderr)
        return 2

    if args.probe:
        probe(args.image, args.probe, args.image.with_name(
            args.image.stem + "-probe.png"))
        return 0

    return measure(args.image, args.min_ink_coverage, args.render_dir)


if __name__ == "__main__":
    raise SystemExit(main())
