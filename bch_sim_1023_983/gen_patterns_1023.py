# 檔名 "decorder" 按你的 testbench
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "bch_sim_1023_983"))

from bch_berlekamp_decode import BCH1023_983_Decoder, N, T, GENERATOR_POLY
import argparse, random
from typing import List, Tuple

import os, random, argparse, sys
from typing import List, Tuple


def tc8(v: int) -> str:
    if v < -127 or v > 127:
        raise ValueError(f"LLR out of range [-127,127]: {v}")
    if v < 0:
        v = (256 + v) & 0xFF
    return f"{v:08b}"


def pack_llrs_to_64bit_rows(llrs: List[int]) -> List[str]:
    assert len(llrs) % 8 == 0, "Total LLR count must be a multiple of 8"
    rows = []
    for i in range(0, len(llrs), 8):
        chunk = llrs[i:i+8]
        bits = ''.join(tc8(x) for x in chunk)
        rows.append(bits)
    return rows


def write_lines(path: str, lines: List[str]):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        for L in lines:
            f.write(L.strip() + "\n")


def encode_with_generator(tx: List[int], GENERATOR_POLY: List[int], N: int) -> List[int]:
    res = [0] * (len(tx) + len(GENERATOR_POLY) - 1)
    for i, a in enumerate(tx):
        if a & 1:
            for j, b in enumerate(GENERATOR_POLY):
                if b & 1:
                    res[i + j] ^= 1
    return res[:N]


def choose_flip_count(max_exclusive: int) -> int:
    if max_exclusive <= 0:
        return 0
    return random.randint(0, max_exclusive)


def flip_bits(vec: List[int], count: int):
    n = len(vec)
    if count <= 0:
        return vec[:], []
    pos = sorted(random.sample(range(n), count))
    out = vec[:]
    for p in pos:
        out[p] ^= 1
    return out, pos


def append_testa_for_roots(testa_lines: List[str], roots: List[int]) -> None:
    if not roots:
        testa_lines.append(f"{(1 << 10) - 1:010b}")
    else:
        for r in sorted(roots):
            testa_lines.append(f"{r:010b}")


def make_llrs_from_rx(rx: List[int], N: int, llr0: int = 0, seed: int = None,
                      allow_equal_two_min: bool = True,
                      min_mag_max: int = 16,
                      min_pos_rx: Tuple[int, int] | None = None) -> List[int]:
    """
    min_pos_rx:
        若為 None -> 跟原本一樣，隨機挑兩個位置當最小 |LLR|
        若給 (r1, r2) -> 讓 rx index 為 r1, r2 的兩個 bit 成為 LLR 內的兩個最小 |LLR| 位置
    """
    if seed is not None:
        random.seed(seed)

    mags = [None] * N

    if min_pos_rx is None:
        # 原本行為：隨機挑兩個
        i1, i2 = random.sample(range(N), 2)
    else:
        r1, r2 = min_pos_rx
        # rx index r 對應到 llrs[1:] 的 j index = N-1-r
        i1 = N - 1 - r1
        i2 = N - 1 - r2

    m1 = random.randint(1, min_mag_max)

    if allow_equal_two_min and random.random() < 0.5:
        m2 = m1
    else:
        if m1 == min_mag_max:
            m2 = m1
        else:
            m2 = random.randint(m1, min_mag_max)

    lower = max(m1, m2) + 1
    if lower > 127:
        lower = 127

    mags[i1] = m1
    mags[i2] = m2
    for j in range(N):
        if j == i1 or j == i2:
            continue
        mags[j] = random.randint(lower, 127)

    llrs = [llr0]
    for j in range(N):
        b = rx[N - 1 - j]
        m = mags[j]
        llrs.append(m if b == 0 else -m)
    return llrs


def safe_soft_decode(dec, llrs_in, p=2):
    out = dec.soft_decode(llrs_in, p=p)
    if isinstance(out, tuple):
        if len(out) == 3:
            decoded, roots, all_failed = out
            return decoded, roots, bool(all_failed)
        elif len(out) == 2:
            decoded, roots = out
            return decoded, roots, False
    return None, [], True


def gen_one_hard(dec: BCH1023_983_Decoder, hard_flip_lt: int = 4):
    k = N - (len(GENERATOR_POLY) - 1)
    tx = [random.randint(0, 1) for _ in range(k)]
    cx = encode_with_generator(tx, GENERATOR_POLY, N)
    rx, _ = flip_bits(cx, choose_flip_count(hard_flip_lt))
    corrected, roots, success, *_ = dec.hard_decode(rx)
    return rx, roots


def gen_one_soft(dec: BCH1023_983_Decoder, soft_flip_lt: int = 6, p: int = 2):
    """
    產生一筆 soft decode 測試資料。

    條件：
      - 若實際 error bit 數 = 6：
          兩個最小 |LLR| 的 bit 都是 error bit（exactly 2 個 min 位置是 error）
      - 若實際 error bit 數 = 5：
          在兩個最小 |LLR| 的 bit 中，隨機選 1 個是 error bit，另一個不是 error
      - 若 error bit <= 4：
          不加限制
    """
    k = N - (len(GENERATOR_POLY) - 1)

    # 1. 產生隨機 codeword
    tx = [random.randint(0, 1) for _ in range(k)]
    cx = encode_with_generator(tx, GENERATOR_POLY, N)

    # 2. 決定 error 數量
    flip_cnt = choose_flip_count(soft_flip_lt)

    # 3. 根據 flip_cnt 決定 error 位置 & 最小 |LLR| 位置
    min_pos_rx = None  # 以 rx index 表示兩個最小 |LLR| 的 bit 位置

    if flip_cnt == 6:
        # 兩個最小 LLR 都要是 error bit
        min_pos_rx = random.sample(range(N), 2)
        # 其餘 4 個 error bit 從非 min_pos_rx 中挑
        others = list(set(range(N)) - set(min_pos_rx))
        extra_errs = random.sample(others, 4)
        flip_pos = sorted(set(min_pos_rx) | set(extra_errs))
        rx = cx[:]
        for pi in flip_pos:
            rx[pi] ^= 1

    elif flip_cnt == 5:
        # 在兩個最小 LLR 中隨機挑一個當 error bit，另一個一定不是 error
        min_pos_rx = random.sample(range(N), 2)
        chosen_min = random.choice(min_pos_rx)
        # 其它 4 個 error bit 從「不含兩個 min_pos_rx」的集合中挑
        others = list(set(range(N)) - set(min_pos_rx))
        extra_errs = random.sample(others, 4)
        flip_pos = sorted({chosen_min} | set(extra_errs))
        rx = cx[:]
        for pi in flip_pos:
            rx[pi] ^= 1

    else:
        # 0~4 個 error：維持原本隨機 flip，最小 LLR 位置隨機
        rx, flip_pos = flip_bits(cx, flip_cnt)
        min_pos_rx = None  # 交給 make_llrs_from_rx 自己決定

    # 4. 產生 LLR，指定 min_pos_rx 時會保證那兩個位置是兩個最小 |LLR|
    llrs = make_llrs_from_rx(rx, N, llr0=0, min_pos_rx=min_pos_rx)
    llrs_in = list(reversed(llrs[1:]))

    # 5. 用 python decoder 做 soft decode，決定 roots / all_failed
    decoded, roots, all_failed = safe_soft_decode(dec, llrs_in, p=p)
    print("Generated soft-decode pattern with roots len:", len(roots), "flip count:", flip_cnt, "errors; all_failed =", all_failed)
    return llrs, roots, all_failed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=["hard", "soft"], default="soft")
    ap.add_argument("--ntest", type=int, default=10000)
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--outdir", type=str, default=".")
    args = ap.parse_args()
    random.seed(args.seed)

    dec = BCH1023_983_Decoder()
    data_lines, testa_lines = [], []

    produced = 0
    while produced < args.ntest:
        if args.mode == "hard":
            rx, roots = gen_one_hard(dec)
            llrs = make_llrs_from_rx(rx, N, llr0=0)
        else:
            llrs, roots, all_failed = gen_one_soft(dec)
            if all_failed:
                # 讓 all_failed 的 case 被丟掉，外面重跑，跟你原本邏輯一樣
                continue

        rows = pack_llrs_to_64bit_rows(llrs)
        data_lines.extend(rows)
        append_testa_for_roots(testa_lines, roots)
        produced += 1

    if args.mode == "hard":
        data_path = os.path.join(args.outdir, "p30000.txt")
        ans_path = os.path.join(args.outdir, "p30000a.txt")
    else:
        data_path = os.path.join(args.outdir, "soft_decorder_30000.txt")
        ans_path = os.path.join(args.outdir, "soft_decorder_30000a.txt")

    write_lines(data_path, data_lines)
    write_lines(ans_path, testa_lines)
    print("Wrote:", data_path, "and", ans_path)


if __name__ == "__main__":
    main()
