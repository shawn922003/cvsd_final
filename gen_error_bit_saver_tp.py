#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generate .dat files for tb_error_bit_saver with **reversed LLR↔r alignment**.

對齊規則（你要求的）：
- 以 r-index（接收序列位址）為基準：r ∈ [0, n_bits-1]，r=0 是 LSB，r=n_bits-1 是 MSB。
- LLR 與 r 反向對齊：llr[1] 對應 r[n_bits-1]，llr[2] 對應 r[n_bits-2]，…，llr[n_bits] 對應 r[0]。
- 翻轉/錯誤位置（err_loc 與 flip_pos*）的 index 都是 **r-index**。

其他重點：
- bch_code: 0→(63,51), 1→(255,239), 2→(1023,983)
- llr_mem_data：每行 1024 bytes（8192 bits），MSB byte = llr0（固定 0），byte1 = llr1，…；
  * code=0 → 前 64 bytes 有值（含 llr0），其餘 0
  * code=1 → 前 256 bytes 有值（含 llr0），其餘 0
  * code=2 → 1024 bytes 全有值
  * LLR 是有號 int8 ∈ [-127,127]（排除 -128）
- 每筆 pattern 有 4 組 (j=0..3) 的 {correct, num_err ≤ t, err_loc(sorted)}
  * 只有 correct=1 的組會進 FIFO，第一個正確的組出現在 o_tp1，依序到 o_tp4
  * flip 套用規則：j=0:∅；j=1:{pos1}；j=2:{pos2}；j=3:{pos1,pos2}
  * o_tp*_num_err 為 (err_loc ∪ flips) 的去重後大小；o_tp*_err_loc* 由小到大（最多 6 個）
- mim_llr_tp：在所有 **correct=1** 的（最多前 4 組）中，計算
      C = Σ_{r=0}^{n-1} l_r * (1 - 2 * ĉ_r)
  其中 l_r = 對應於 r 的 LLR（依反向對齊），ĉ_r 為 HD(LLR) 經該組 flips 後的位元；
  取 C 最大的那個 tp（1..4；同分 FIFO 先者勝），若無有效組則為 0。

輸出檔名完全對齊 testbench：
llr_mem_data.dat, bch_code.dat, err_loc{0..3}.dat, num_err.dat, correct.dat,
flip_pos1.dat, flip_pos2.dat, tp{1..4}_err_loc{0..5}.dat, tp{1..4}_num_err.dat,
tp{1..4}_correct.dat, mim_llr_tp.dat
"""

import argparse
from pathlib import Path
import random
import zipfile

# ----------------------------- config -----------------------------
DEFAULT_SEED = 2025
DEFAULT_PATTERNS = 30
OUT_DIR = Path("./pattern_error_bit_saver")

# code -> (llr_len, n_bits, t)
BCH63_51     = 0
BCH255_239   = 1
BCH1023_983  = 2
CODE_TABLE = {
    BCH63_51    : (64,   63,   2),
    BCH255_239  : (256,  255,  2),
    BCH1023_983 : (1024, 1023, 4),
}

# ----------------------------- helpers -----------------------------
def to_hex(value: int, width_bits: int) -> str:
    width_hex = (width_bits + 3) // 4
    return f"{value & ((1<<width_bits)-1):0{width_hex}x}"

def pack_4x10b(msb_j0_j1_j2_j3):
    """Pack 4 groups (each 10b) into 40b: j=0 -> [39:30](MSB) ... j=3 -> [9:0]."""
    assert len(msb_j0_j1_j2_j3) == 4
    j0, j1, j2, j3 = msb_j0_j1_j2_j3
    return (j0 << 30) | (j1 << 20) | (j2 << 10) | j3

def rand_llrs(llr_len: int):
    """Return 1024 signed 8-bit LLRs; only first llr_len are set; llr0==0; exclude -128."""
    arr = [0] * 1024
    arr[0] = 0
    for i in range(1, llr_len):
        arr[i] = random.randint(-127, 127)
    return arr

def llrs_to_hex_1024(llrs):
    # byte 0 = llr0 (MSB byte in readmemh), byte 1 = llr1, ...
    b = bytes((x & 0xFF) for x in llrs)
    return b.hex()

def choose_positions(n_bits: int, k: int, exclude=None):
    pool = set(range(n_bits))
    if exclude:
        pool -= set(exclude)
    k = max(0, min(k, len(pool)))
    return sorted(random.sample(list(pool), k))

# ----------------------------- core generator -----------------------------
def main(seed: int, patterns: int, out_dir: Path, zip_output: bool):
    random.seed(seed)
    out_dir.mkdir(parents=True, exist_ok=True)

    # Collectors
    L_llr_mem_data = []
    L_bch_code = []
    L_err_loc0 = []
    L_err_loc1 = []
    L_err_loc2 = []
    L_err_loc3 = []
    L_num_err = []
    L_correct = []
    L_flip_pos1 = []
    L_flip_pos2 = []

    gold_tp_err_locs = {tp: {idx: [] for idx in range(6)} for tp in range(1, 5)}
    gold_tp_num_err = {tp: [] for tp in range(1, 5)}
    gold_tp_correct = {tp: [] for tp in range(1, 5)}
    L_mim_llr_tp = []

    for _ in range(patterns):
        # --- pick code ---
        code = random.choice([BCH63_51, BCH255_239, BCH1023_983])
        llr_len, n_bits, t = CODE_TABLE[code]
        L_bch_code.append(to_hex(code, 2))

        # --- LLRs ---
        llrs = rand_llrs(llr_len)
        L_llr_mem_data.append(llrs_to_hex_1024(llrs))

        # --- flips (pos1 < pos2) ---
        pos1, pos2 = sorted(random.sample(range(n_bits), 2))
        L_flip_pos1.append(to_hex(pos1, 10))
        L_flip_pos2.append(to_hex(pos2, 10))

        # --- four groups: correct, num_err (<=t), locations sorted ---
        correct_bits = [random.randint(0, 1) for _ in range(4)]
        if sum(correct_bits) == 0:
            # 確保至少一組為 1，避免 TB wait(o_valid) 卡住
            correct_bits[random.randint(0, 3)] = 1

        group_num_err = []
        group_err_locs = []
        for j in range(4):
            k = random.randint(0, t)
            locs = choose_positions(n_bits, k)
            group_num_err.append(k)
            group_err_locs.append(locs)  # sorted unique

        # --- pack err_loc0..3: 每檔 40b，放四組的第 idx 個 err；不足以 0 補 ---
        def nth_or_zero(locs, idx):
            return locs[idx] if idx < len(locs) else 0

        for idx, collector in enumerate([L_err_loc0, L_err_loc1, L_err_loc2, L_err_loc3]):
            j0 = nth_or_zero(group_err_locs[0], idx)
            j1 = nth_or_zero(group_err_locs[1], idx)
            j2 = nth_or_zero(group_err_locs[2], idx)
            j3 = nth_or_zero(group_err_locs[3], idx)
            collector.append(to_hex(pack_4x10b([j0, j1, j2, j3]), 40))

        # --- num_err(12b) 與 correct(4b) ---
        num_err_word = (group_num_err[0] << 9) | (group_num_err[1] << 6) | \
                       (group_num_err[2] << 3) | (group_num_err[3] << 0)
        L_num_err.append(to_hex(num_err_word, 12))
        correct_word = sum((correct_bits[j] & 1) << j for j in range(4))
        L_correct.append(to_hex(correct_word, 4))

        # --- FIFO valid order ---
        valid_groups = [j for j in range(4) if correct_bits[j] == 1]

        # --- combined positions with flips（r-index） ---
        def combined_positions(j):
            s = set(group_err_locs[j])
            if j == 1:
                s.add(pos1)
            elif j == 2:
                s.add(pos2)
            elif j == 3:
                s.add(pos1); s.add(pos2)
            comb = sorted(x for x in s if 0 <= x < n_bits)
            return comb[:6]  # interface 上最多 6 個

        # --- LLR 與 r 的反向對齊：llr[1] -> r[n_bits-1], ..., llr[n_bits] -> r[0] ---
        def llr_aligned(r_idx: int) -> int:
            # r_idx ∈ [0, n_bits-1]
            li = 1 + (n_bits - 1 - r_idx)   # ← 反向對齊
            return llrs[li] if li < len(llrs) else 0

        # --- Hard decision over r-index using llr_aligned(r) ---
        hd_bits = [0] * n_bits
        for r in range(n_bits):
            v = llr_aligned(r)
            hd_bits[r] = 0 if v >= 0 else 1

        # --- correlations for mim_llr_tp among first up-to-4 valid groups ---
        corrs = []  # (score, tp_idx_in_fifo)
        for tp_idx, j in enumerate(valid_groups[:4]):
            flipped = set(combined_positions(j))  # r-index
            corr = 0
            for r in range(n_bits):
                bit = hd_bits[r] ^ (1 if r in flipped else 0)   # ĉ_r
                corr += llr_aligned(r) * (1 - 2 * bit)          # l_r * s_r
            corrs.append((corr, tp_idx))

        if corrs:
            # 取最大；平手時 FIFO 較早（較小 tp_idx）者勝
            best_tp_idx = max(corrs, key=lambda x: (x[0], -x[1]))[1]
            L_mim_llr_tp.append(to_hex(best_tp_idx + 1, 3))  # 1..4
        else:
            L_mim_llr_tp.append(to_hex(0, 3))  # 無有效

        # --- build golden tp1..tp4 ---
        for tp in range(1, 5):
            gold_tp_correct[tp].append("0")
            gold_tp_num_err[tp].append("0")
            for idx in range(6):
                gold_tp_err_locs[tp][idx].append(to_hex(0, 10))

        tp_slot = 1
        for j in valid_groups:
            if tp_slot > 4:
                break
            comb = combined_positions(j)
            k = len(comb)
            gold_tp_correct[tp_slot][-1] = "1"
            gold_tp_num_err[tp_slot][-1] = to_hex(k, 3)
            for idx in range(k):
                gold_tp_err_locs[tp_slot][idx][-1] = to_hex(comb[idx], 10)
            tp_slot += 1

    # ----------------------------- write files -----------------------------
    def write_lines(name, lines):
        with open(out_dir / name, "w") as f:
            for x in lines:
                f.write(str(x) + "\n")

    write_lines("llr_mem_data.dat", L_llr_mem_data)
    write_lines("bch_code.dat", L_bch_code)
    write_lines("err_loc0.dat", L_err_loc0)
    write_lines("err_loc1.dat", L_err_loc1)
    write_lines("err_loc2.dat", L_err_loc2)
    write_lines("err_loc3.dat", L_err_loc3)
    write_lines("num_err.dat", L_num_err)
    write_lines("correct.dat", L_correct)
    write_lines("flip_pos1.dat", L_flip_pos1)
    write_lines("flip_pos2.dat", L_flip_pos2)

    for tp in range(1, 5):
        for idx in range(6):
            write_lines(f"tp{tp}_err_loc{idx}.dat", gold_tp_err_locs[tp][idx])
        write_lines(f"tp{tp}_num_err.dat", gold_tp_num_err[tp])
        write_lines(f"tp{tp}_correct.dat", gold_tp_correct[tp])

    write_lines("mim_llr_tp.dat", L_mim_llr_tp)

    if zip_output:
        zip_path = out_dir.with_suffix(".zip")
        with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
            for p in out_dir.glob("*.dat"):
                zf.write(p, arcname=f"{out_dir.name}/{p.name}")
        print(f"[OK] Wrote: {zip_path}")
    print(f"[OK] Wrote dat files to: {out_dir.resolve()}")

# ----------------------------- cli -----------------------------
if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--patterns", type=int, default=DEFAULT_PATTERNS, help="number of patterns (lines) to generate")
    ap.add_argument("--seed", type=int, default=DEFAULT_SEED, help="rng seed")
    ap.add_argument("--out", type=str, default=str(OUT_DIR), help="output directory for .dat files")
    ap.add_argument("--zip", action="store_true", help="also write a .zip next to the folder")
    args = ap.parse_args()
    main(args.seed, args.patterns, Path(args.out), args.zip)
