# nuScenes LiDAR Segmentation 爬虫

爬取 [nuScenes LiDAR Segmentation](https://www.nuscenes.org/lidar-segmentation?externalData=all&mapData=all&modalities=Any) 排行榜数据，输出 CSV、JSON、Markdown 表格。

## 环境准备

```bash
cd crawler
pip install -r requirements.txt
playwright install chromium
```

## 运行

```bash
python nuscenes_lidarseg_crawler.py
```

## 输出

结果保存在 `output/` 目录：

- `nuscenes_lidarseg.csv`：CSV（Excel 可打开）
- `nuscenes_lidarseg.json`：JSON
- `nuscenes_lidarseg.md`：Markdown 表格
