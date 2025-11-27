#!/usr/bin/env python3
import os, random, argparse
from typing import List, Tuple
from bch_ibm_decode import BCH1023_983_Decoder

# -------- helpers --------
def bits_to_int(bits: List[int]) -> int:
    v = 0
    for i, b in enumerate(bits):
        if b:
            v |= (1 << i)
    return v & 0x3FF

def pack80(fields_10bit: List[int]) -> str:
    assert len(fields_10bit) == 8
    acc = 0
    for x in fields_10bit:
        acc = (acc << 10) | (x & 0x3FF)
    return f"{acc:020X}"

def degree_from_sigma(sigma_bits: List[List[int]]) -> int:
    deg = 0
    for i in range(1, len(sigma_bits)):
        if any(sigma_bits[i]):
            deg = i
    return deg

def as_hex10(x: int) -> str:
    return f"{x & 0x3FF:03X}"

# -------- generator --------
def gen_one_sigma(dec: BCH1023_983_Decoder, t_max: int = 4) -> Tuple[List[List[int]], List[int]]:
    n = 1023
    t = random.randint(0, t_max)
    err_pos = sorted(random.sample(range(n), t)) if t > 0 else []
    rx = [0] * n
    for p in err_pos:
        rx[p] ^= 1
    S = dec.syndromes(rx)
    sigma_bits = dec.berlekamp_iBM(*S)       # sigma0..sigma4（bit-list）
    roots = dec.chien_search(*sigma_bits)    # list of positions
    return sigma_bits, roots

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--num", type=int, default=10, help="number of input patterns (PATTERN_LEN)")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--outdir", default="bch_1023_chien_search_tp")
    args = ap.parse_args()
    random.seed(args.seed)

    os.makedirs(args.outdir, exist_ok=True)
    tag = "_1023"

    dec = BCH1023_983_Decoder()

    data_f = open(os.path.join(args.outdir, f"chien_search_data{tag}.dat"), "w")
    code_f = open(os.path.join(args.outdir, f"chien_search_code{tag}.dat"), "w")
    mode_f = open(os.path.join(args.outdir, f"chien_search_mode{tag}.dat"), "w")
    el0_f  = open(os.path.join(args.outdir, f"chien_search_err_loc0{tag}.dat"), "w")
    el1_f  = open(os.path.join(args.outdir, f"chien_search_err_loc1{tag}.dat"), "w")
    el2_f  = open(os.path.join(args.outdir, f"chien_search_err_loc2{tag}.dat"), "w")
    el3_f  = open(os.path.join(args.outdir, f"chien_search_err_loc3{tag}.dat"), "w")
    num_f  = open(os.path.join(args.outdir, f"chien_search_num_err{tag}.dat"), "w")
    cor_f  = open(os.path.join(args.outdir, f"chien_search_correct{tag}.dat"), "w")

    # 1023：不論 i_mode 0/1 都只輸出一筆；不增加 PATTERN_TWO_LEN
    two_out_cnt = 0

    for _ in range(args.num):
        code_f.write("2\n")  # BCH1023_983

        i_mode = random.randint(0, 1)
        mode_f.write(f"{i_mode}\n")

        sigma_bits, roots = gen_one_sigma(dec, t_max=4)
        s10 = bits_to_int(sigma_bits[0])
        s11 = bits_to_int(sigma_bits[1]) if len(sigma_bits) > 1 else 0
        s12 = bits_to_int(sigma_bits[2]) if len(sigma_bits) > 2 else 0
        s13 = bits_to_int(sigma_bits[3]) if len(sigma_bits) > 3 else 0
        s14 = bits_to_int(sigma_bits[4]) if len(sigma_bits) > 4 else 0

        # 只用 sigma1_0..1_4；sigma2_* 全 0
        fields = [s10, s11, s12, s13, s14, 0, 0, 0]
        data_f.write(pack80(fields) + "\n")

        r = sorted(roots)[:4] + [0, 0, 0, 0]
        el0_f.write(as_hex10(r[0]) + "\n")
        el1_f.write(as_hex10(r[1]) + "\n")
        el2_f.write(as_hex10(r[2]) + "\n")
        el3_f.write(as_hex10(r[3]) + "\n")
        num_f.write(f"{min(len(roots),7):X}\n")
        cor_f.write("1\n" if degree_from_sigma(sigma_bits) == len(roots) else "0\n")

    for f in [data_f, code_f, mode_f, el0_f, el1_f, el2_f, el3_f, num_f, cor_f]:
        f.close()

    print(f"[BCH1023_983] PATTERN_LEN={args.num}, PATTERN_TWO_LEN(請在 TB 設定)={two_out_cnt}")

if __name__ == "__main__":
    main()
