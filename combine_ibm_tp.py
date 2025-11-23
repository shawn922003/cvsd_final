#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
把 ibm_tp_63 / ibm_tp_255 / ibm_tp_1023 的 .dat 檔案合併成一組，
輸出到 00_TESTBED/pattern_ibm/ 底下。

合併順序：
    1) ibm_tp_63
    2) ibm_tp_255
    3) ibm_tp_1023

合併後記得把 testbench 裡的 PATTERN_LEN 改成
    63_pattern_num + 255_pattern_num + 1023_pattern_num
"""

from pathlib import Path

# 依你現在的資料夾名稱調整
SRC_DIRS = ["ibm_tp_63", "ibm_tp_255", "ibm_tp_1023"]

# 需要合併的 dat 檔清單（檔名在三個資料夾裡都一樣）
DAT_FILES = [
    "test_data.dat",
    "test_code.dat",
    "golden_sigma1_0.dat",
    "golden_sigma1_1.dat",
    "golden_sigma1_2.dat",
    "golden_sigma1_3.dat",
    "golden_sigma1_4.dat",
    "golden_sigma2_0.dat",
    "golden_sigma2_1.dat",
    "golden_sigma2_2.dat",
]


def read_lines(path: Path):
    """讀一個 .dat 檔，回傳行列表（去掉換行，但不動內容）"""
    lines = []
    with path.open("r") as f:
        for line in f:
            line = line.rstrip("\r\n")
            # 跳過真正的空行，其餘一律保留
            if line == "":
                continue
            lines.append(line)
    return lines


def main():
    root = Path(__file__).resolve().parent
    out_dir = root / "ibm_tp"
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"Output dir: {out_dir}")

    for dat_name in DAT_FILES:
        merged = []
        print(f"\nMerging {dat_name} ...")
        for src in SRC_DIRS:
            src_path = root / src / dat_name
            if not src_path.is_file():
                raise FileNotFoundError(f"{src_path} not found")
            lines = read_lines(src_path)
            merged.extend(lines)
            print(f"  {src_path} : {len(lines)} lines")

        out_path = out_dir / dat_name
        with out_path.open("w") as f:
            for line in merged:
                f.write(line + "\n")
        print(f"  -> {out_path} : {len(merged)} lines total")

    print("\nDone. 別忘了更新 testbench 的 PATTERN_LEN！")


if __name__ == "__main__":
    main()
