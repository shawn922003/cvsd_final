#!/usr/bin/env python3
# BCH(63,51), t = 2
# 產生：
#   - test_data.dat      : {S1,S2,S3,S4,S5,S6,S7,S8}，兩筆 syndromes
#   - test_code.dat      : 全部 "00"
#   - golden_sigma1_*    : 第一筆的 locator polynomial σ^(1)
#   - golden_sigma2_*    : 第二筆的 locator polynomial σ^(2)
#
# 放在 bch_sim_63_51/ 內執行：
#   python ibm_tp_gen.py

from pathlib import Path
from typing import List
import random

from bch_ibm_decode import BCH63_51_Decoder
from bch_table import N, T         # N = 63, T = 2


PATTERN_LEN = 10   # 和 testbench 的 PATTERN_LEN 一致


def gf_bits_to_int(bits: List[int]) -> int:
    """GF element (LSB-first bit list) -> 整數 (LSB 在 bit0)。"""
    v = 0
    for i, b in enumerate(bits):
        v |= (int(b) & 1) << i
    return v


def write_dat(path: Path, lines):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w") as f:
        for line in lines:
            f.write(line + "\n")


def main():
    random.seed(0)

    dec = BCH63_51_Decoder()
    gf = dec.gf

    base_dir = Path(__file__).resolve().parent
    out_dir = base_dir / ".." / "ibm_tp"
    out_dir.mkdir(parents=True, exist_ok=True)

    test_data_lines = []
    test_code_lines = []

    g_s1_0, g_s1_1, g_s1_2, g_s1_3, g_s1_4 = [], [], [], [], []
    g_s2_0, g_s2_1, g_s2_2 = [], [], []

    for pat in range(PATTERN_LEN):
        # 一個 pattern 裡面放兩個 codeword 的 syndromes
        syndromes_int = []
        sigma1 = None
        sigma2 = None

        for word_idx in range(2):     # 兩筆資料
            # 建立 error pattern：0,1,2 個錯誤位置
            w = random.randint(0, T)
            err_pos = random.sample(range(N), w)
            r = [0] * N
            for p in err_pos:
                r[p] = 1  # 全 0 codeword + error = r

            # 算 S1, S3，然後用 square table 生 S2, S4
            S1, S3 = dec.syndromes(r)
            S2 = gf.square_table(S1)
            S4 = gf.square_table(S2)

            # inversionless Berlekamp–Massey
            s0, s1, s2 = dec.berlekamp_iBM(S1, S3)

            if word_idx == 0:
                sigma1 = (s0, s1, s2)
            else:
                sigma2 = (s0, s1, s2)

            # 這四個依序對應到 i_S1~i_S4 或 i_S5~i_S8
            for S in (S1, S2, S3, S4):
                syndromes_int.append(gf_bits_to_int(S))

        assert sigma1 is not None and sigma2 is not None
        assert len(syndromes_int) == 8  # S1~S8

        # 把 8 個 10-bit syndrome 串成一行 80-bit binary，對應 test_data[pat]
        test_data_lines.append("".join(f"{v:010b}" for v in syndromes_int))
        # BCH63_51 -> i_code = 2'b00
        test_code_lines.append("00")

        # golden sigma，轉成 10-bit hex（用 3 位 hex 表現）
        s10, s11, s12 = map(gf_bits_to_int, sigma1)
        s20, s21, s22 = map(gf_bits_to_int, sigma2)

        g_s1_0.append(f"{s10:03X}")
        g_s1_1.append(f"{s11:03X}")
        g_s1_2.append(f"{s12:03X}")
        g_s1_3.append("000")  # BCH63 不用，先填 0
        g_s1_4.append("000")  # BCH63 不用，先填 0

        g_s2_0.append(f"{s20:03X}")
        g_s2_1.append(f"{s21:03X}")
        g_s2_2.append(f"{s22:03X}")

    # 寫檔
    write_dat(out_dir / "test_data.dat",        test_data_lines)
    write_dat(out_dir / "test_code.dat",        test_code_lines)
    write_dat(out_dir / "golden_sigma1_0.dat",  g_s1_0)
    write_dat(out_dir / "golden_sigma1_1.dat",  g_s1_1)
    write_dat(out_dir / "golden_sigma1_2.dat",  g_s1_2)
    write_dat(out_dir / "golden_sigma1_3.dat",  g_s1_3)
    write_dat(out_dir / "golden_sigma1_4.dat",  g_s1_4)
    write_dat(out_dir / "golden_sigma2_0.dat",  g_s2_0)
    write_dat(out_dir / "golden_sigma2_1.dat",  g_s2_1)
    write_dat(out_dir / "golden_sigma2_2.dat",  g_s2_2)

    print(f"[63,51] patterns generated to {out_dir}")


if __name__ == "__main__":
    main()
