#!/usr/bin/env python3
import os, random, argparse
from typing import List, Tuple
from bch_ibm_decode import BCH255_239_Decoder

# -------- helpers --------
def bits_to_int(bits: List[int]) -> int:
    v = 0
    for i, b in enumerate(bits):
        if b:
            v |= (1 << i)
    return v & 0x3FF  # 10 bits

def pack80(fields_10bit: List[int]) -> str:
    """Pack 8x10b -> 80b hex (20 hex chars, upper)."""
    assert len(fields_10bit) == 8
    acc = 0
    for x in fields_10bit:
        acc = (acc << 10) | (x & 0x3FF)
    return f"{acc:020X}"

def degree_from_sigma(sigma_bits: List[List[int]]) -> int:
    # sigma[0] 是常數項，最高非零係數索引即為多項式階
    deg = 0
    for i in range(1, len(sigma_bits)):
        if any(sigma_bits[i]):
            deg = i
    return deg

def as_hex10(x: int) -> str:
    return f"{x & 0x3FF:03X}"

# -------- generator --------
def gen_one_sigma(dec: BCH255_239_Decoder, t_max: int = 2) -> Tuple[List[List[int]], List[int]]:
    n = 255
    t = random.randint(0, t_max)
    err_pos = sorted(random.sample(range(n), t)) if t > 0 else []
    rx = [0] * n
    for p in err_pos:
        rx[p] ^= 1
    S = dec.syndromes(rx)
    sigma_bits = dec.berlekamp_iBM(*S)      # sigma0..sigma2（bit-list）
    roots = dec.chien_search(*sigma_bits)   # list of positions
    return sigma_bits, roots

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--num", type=int, default=10, help="number of input patterns (PATTERN_LEN)")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--outdir", default="bch_255_chien_search_tp")
    args = ap.parse_args()
    random.seed(args.seed)

    os.makedirs(args.outdir, exist_ok=True)
    tag = "_255"

    dec = BCH255_239_Decoder()

    data_f = open(os.path.join(args.outdir, f"chien_search_data{tag}.dat"), "w")
    code_f = open(os.path.join(args.outdir, f"chien_search_code{tag}.dat"), "w")
    mode_f = open(os.path.join(args.outdir, f"chien_search_mode{tag}.dat"), "w")
    el0_f  = open(os.path.join(args.outdir, f"chien_search_err_loc0{tag}.dat"), "w")
    el1_f  = open(os.path.join(args.outdir, f"chien_search_err_loc1{tag}.dat"), "w")
    el2_f  = open(os.path.join(args.outdir, f"chien_search_err_loc2{tag}.dat"), "w")
    el3_f  = open(os.path.join(args.outdir, f"chien_search_err_loc3{tag}.dat"), "w")
    num_f  = open(os.path.join(args.outdir, f"chien_search_num_err{tag}.dat"), "w")
    cor_f  = open(os.path.join(args.outdir, f"chien_search_correct{tag}.dat"), "w")

    two_out_cnt = 0

    for _ in range(args.num):
        code_f.write("1\n")  # BCH255_239

        i_mode = random.randint(0, 1)
        mode_f.write(f"{i_mode}\n")

        # 第一組 sigma（sigma1_0..1_2）
        sigma1_bits, roots1 = gen_one_sigma(dec, t_max=2)
        s10 = bits_to_int(sigma1_bits[0])
        s11 = bits_to_int(sigma1_bits[1]) if len(sigma1_bits) > 1 else 0
        s12 = bits_to_int(sigma1_bits[2]) if len(sigma1_bits) > 2 else 0

        # 第二組（僅 i_mode==1）
        if i_mode == 1:
            sigma2_bits, roots2 = gen_one_sigma(dec, t_max=2)
            s20 = bits_to_int(sigma2_bits[0])
            s21 = bits_to_int(sigma2_bits[1]) if len(sigma2_bits) > 1 else 0
            s22 = bits_to_int(sigma2_bits[2]) if len(sigma2_bits) > 2 else 0
            two_out_cnt += 1
        else:
            roots2 = []
            s20 = s21 = s22 = 0

        # 255 不用 sigma1_3/1_4
        fields = [s10, s11, s12, 0, 0, s20, s21, s22]
        data_f.write(pack80(fields) + "\n")

        # golden（第一筆）
        r = sorted(roots1)[:4] + [0, 0, 0, 0]
        el0_f.write(as_hex10(r[0]) + "\n")
        el1_f.write(as_hex10(r[1]) + "\n")
        el2_f.write(as_hex10(r[2]) + "\n")
        el3_f.write(as_hex10(r[3]) + "\n")
        num_f.write(f"{min(len(roots1),7):X}\n")
        cor_f.write("1\n" if degree_from_sigma(sigma1_bits) == len(roots1) else "0\n")

        # golden（第二筆，僅 i_mode==1）
        if i_mode == 1:
            r = sorted(roots2)[:4] + [0, 0, 0, 0]
            el0_f.write(as_hex10(r[0]) + "\n")
            el1_f.write(as_hex10(r[1]) + "\n")
            el2_f.write(as_hex10(r[2]) + "\n")
            el3_f.write(as_hex10(r[3]) + "\n")
            num_f.write(f"{min(len(roots2),7):X}\n")
            cor_f.write("1\n" if degree_from_sigma(sigma2_bits) == len(roots2) else "0\n")

    for f in [data_f, code_f, mode_f, el0_f, el1_f, el2_f, el3_f, num_f, cor_f]:
        f.close()

    print(f"[BCH255_239] PATTERN_LEN={args.num}, PATTERN_TWO_LEN(請在 TB 設定)={two_out_cnt}")

if __name__ == "__main__":
    main()
