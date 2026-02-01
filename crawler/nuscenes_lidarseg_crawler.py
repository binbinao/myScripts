#!/usr/bin/env python3
"""
nuScenes LiDAR Segmentation 排行榜爬虫
爬取 https://www.nuscenes.org/lidar-segmentation 页面数据，输出 CSV / JSON / Markdown 表格
"""

import json
import os
import re
import sys
from pathlib import Path

import pandas as pd
from playwright.sync_api import sync_playwright
from tabulate import tabulate

URL = "https://www.nuscenes.org/lidar-segmentation?externalData=all&mapData=all&modalities=Any"
OUTPUT_DIR = Path(__file__).resolve().parent / "output"
OUTPUT_BASE = "nuscenes_lidarseg"
TIMEOUT_MS = 30000
WAIT_AFTER_LOAD_MS = 3000


def ensure_output_dir():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def scrape_leaderboard():
    """使用 Playwright 爬取排行榜表格数据"""
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            user_agent=(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            )
        )
        page = context.new_page()

        try:
            page.goto(URL, wait_until="networkidle", timeout=TIMEOUT_MS)
            page.wait_for_timeout(WAIT_AFTER_LOAD_MS)
        except Exception as e:
            print(f"访问页面失败: {e}", file=sys.stderr)
            browser.close()
            return []

        rows_data = []

        # 尝试多种表格选择器（适配 nuScenes 页面结构）
        table_selectors = [
            "table tbody tr",
            "table.leaderboard tbody tr",
            "[class*='leaderboard'] table tbody tr",
            "table tr",
        ]

        for selector in table_selectors:
            try:
                row_els = page.query_selector_all(selector)
                if not row_els:
                    continue

                # 若匹配到的是 thead 所在 table 的 tr，跳过表头行
                header_el = page.query_selector("table thead tr")
                header_cells = (
                    [c.inner_text().strip() for c in header_el.query_selector_all("th")]
                    if header_el
                    else []
                )

                for tr in row_els:
                    # 跳过 thead 里的 tr
                    if header_el and tr == header_el.query_selector(".."):
                        continue
                    cells = tr.query_selector_all("td")
                    if not cells:
                        continue
                    cell_texts = [c.inner_text().strip() for c in cells]
                    links = []
                    for a in tr.query_selector_all("a[href]"):
                        href = a.get_attribute("href") or ""
                        text = a.inner_text().strip()
                        if href.startswith("http") and text:
                            links.append({"text": text, "url": href})

                    if not header_cells and len(cell_texts) >= 2:
                        # 无表头时使用通用列名
                        col_count = len(cell_texts)
                        headers = (
                            ["Rank", "Method", "mIoU"]
                            + [f"Col_{i}" for i in range(4, col_count + 1)]
                        )[:col_count]
                    else:
                        headers = header_cells or [
                            f"Col_{i+1}" for i in range(len(cell_texts))
                        ]
                    row_dict = {}
                    for i, h in enumerate(headers):
                        if i < len(cell_texts):
                            key = re.sub(r"\s+", "_", h.strip()) or f"Col_{i+1}"
                            row_dict[key] = cell_texts[i]
                    if links:
                        row_dict["Paper_Link"] = links[0]["url"] if links else ""
                    if row_dict:
                        rows_data.append(row_dict)
                if rows_data:
                    break
            except Exception:
                continue

        # 若上述均未解析到，尝试按任意 table 取所有 td 按列数推断
        if not rows_data:
            try:
                all_cells = page.query_selector_all("table td")
                if all_cells:
                    first_row_count = len(
                        page.query_selector_all("table tbody tr:first-child td")
                    )
                    if first_row_count > 0:
                        cell_texts = [c.inner_text().strip() for c in all_cells]
                        for i in range(0, len(cell_texts), first_row_count):
                            chunk = cell_texts[i : i + first_row_count]
                            if len(chunk) == first_row_count:
                                row_dict = {
                                    "Rank": chunk[0] if len(chunk) > 0 else "",
                                    "Method": chunk[1] if len(chunk) > 1 else "",
                                    "mIoU": chunk[2] if len(chunk) > 2 else "",
                                }
                                for j in range(3, len(chunk)):
                                    row_dict[f"Col_{j+1}"] = chunk[j]
                                rows_data.append(row_dict)
            except Exception:
                pass

        browser.close()
        return rows_data


def normalize_columns(df: pd.DataFrame) -> pd.DataFrame:
    """统一列名：Rank, Method, mIoU 等（每个标准名只映射一列）"""
    cols = list(df.columns)
    rename = {}
    used = set()
    for c in cols:
        cl = c.lower().replace(" ", "_")
        target = None
        if ("rank" in cl or c == "Col_1") and "Rank" not in used:
            target = "Rank"
        elif ("method" in cl or "name" in cl or c == "Col_2") and "Method" not in used:
            target = "Method"
        elif ("miou" in cl or "iou" in cl or c == "Col_3") and "mIoU" not in used:
            target = "mIoU"
        if target:
            rename[c] = target
            used.add(target)
    df = df.rename(columns=rename)
    return df


def save_outputs(rows_data: list):
    """保存为 CSV、JSON、Markdown"""
    if not rows_data:
        print("未解析到任何数据，仅写入空文件占位")
        df = pd.DataFrame(columns=["Rank", "Method", "mIoU"])
    else:
        df = pd.DataFrame(rows_data)
        df = normalize_columns(df)

    ensure_output_dir()

    csv_path = OUTPUT_DIR / f"{OUTPUT_BASE}.csv"
    df.to_csv(csv_path, index=False, encoding="utf-8-sig")
    print(f"已保存: {csv_path}")

    json_path = OUTPUT_DIR / f"{OUTPUT_BASE}.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(df.to_dict(orient="records"), f, ensure_ascii=False, indent=2)
    print(f"已保存: {json_path}")

    md_path = OUTPUT_DIR / f"{OUTPUT_BASE}.md"
    with open(md_path, "w", encoding="utf-8") as f:
        f.write("# nuScenes LiDAR Segmentation 排行榜\n\n")
        f.write(tabulate(df, headers="keys", tablefmt="pipe", showindex=False))
        f.write("\n")
    print(f"已保存: {md_path}")


def main():
    print("正在爬取 nuScenes LiDAR Segmentation 排行榜...")
    rows = scrape_leaderboard()
    print(f"解析到 {len(rows)} 条记录")
    save_outputs(rows)
    print("完成。")


if __name__ == "__main__":
    main()
