#!/usr/bin/env python3
# BCH(255,239), t = 2
# 結構跟 63_51 版完全一樣，只是換 decoder & i_code = 01

from pathlib import Path
from typing import List
import random

from bch_ibm_decode import BCH255_239_Decoder
from bch_table import N, T         # N = 255, T = 2


PATTERN_LEN = 10   # 跟 testbench 一致


def gf_bits_to_int(bits: List[int]) -> int:
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
    random.seed(1)

    dec = BCH255_239_Decoder()
    gf = dec.gf

    base_dir = Path(__file__).resolve().parent
    out_dir = base_dir / ".." / "ibm_tp_255"
    out_dir.mkdir(parents=True, exist_ok=True)

    test_data_lines = []
    test_code_lines = []

    g_s1_0, g_s1_1, g_s1_2, g_s1_3, g_s1_4 = [], [], [], [], []
    g_s2_0, g_s2_1, g_s2_2 = [], [], []

    for pat in range(PATTERN_LEN):
        syndromes_int = []
        sigma1 = None
        sigma2 = None

        for word_idx in range(2):   # 一樣兩筆資料
            w = random.randint(0, T)
            err_pos = random.sample(range(N), w)
            r = [0] * N
            for p in err_pos:
                r[p] = 1

            S1, S3 = dec.syndromes(r)
            S2 = gf.square_table(S1)
            S4 = gf.square_table(S2)

            s0, s1, s2 = dec.berlekamp_iBM(S1, S3)

            if word_idx == 0:
                sigma1 = (s0, s1, s2)
            else:
                sigma2 = (s0, s1, s2)

            for S in (S1, S2, S3, S4):
                syndromes_int.append(gf_bits_to_int(S))

        assert sigma1 is not None and sigma2 is not None

        test_data_lines.append("".join(f"{v:010b}" for v in syndromes_int))
        # BCH255_239 -> i_code = 2'b01
        test_code_lines.append("01")

        s10, s11, s12 = map(gf_bits_to_int, sigma1)
        s20, s21, s22 = map(gf_bits_to_int, sigma2)

        g_s1_0.append(f"{s10:03X}")
        g_s1_1.append(f"{s11:03X}")
        g_s1_2.append(f"{s12:03X}")
        g_s1_3.append("000")  # 255 code 不用
        g_s1_4.append("000")

        g_s2_0.append(f"{s20:03X}")
        g_s2_1.append(f"{s21:03X}")
        g_s2_2.append(f"{s22:03X}")

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

    print(f"[255,239] patterns generated to {out_dir}")


if __name__ == "__main__":
    main()
