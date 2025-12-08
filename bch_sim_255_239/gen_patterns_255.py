import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "bch_sim_255_239"))

from bch_berlekamp_decode import BCH255_239_Decoder, N, T, GENERATOR_POLY
import argparse, random
from typing import List, Tuple, Optional

import os, random, argparse, sys


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
        for line in lines:
            f.write(line.strip() + "\n")


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
    for idx in pos:
        out[idx] ^= 1
    return out, pos


def append_testa_for_roots(testa_lines: List[str], roots: List[int]) -> None:
    if not roots:
        testa_lines.append(f"{(1 << 10) - 1:010b}")
    else:
        for r in sorted(roots):
            testa_lines.append(f"{r:010b}")


def make_llrs_from_rx(
    rx: List[int],
    N: int,
    llr0: int = 0,
    seed: int = None,
    allow_equal_two_min: bool = True,
    min_mag_max: int = 16,
    min_pos_rx: Optional[Tuple[int, int]] = None,
) -> List[int]:
    """
    min_pos_rx:
      - None: 兩個最小 |LLR| 位置隨機
      - (r1, r2): 指定 rx index 為 r1, r2 的兩個 bit 是 LLR 內兩個最小 |LLR|
    """
    if seed is not None:
        random.seed(seed)

    mags = [None] * N

    if min_pos_rx is None:
        # 原本行為：隨機兩個位置當最小 |LLR|
        idx1, idx2 = random.sample(range(N), 2)
    else:
        r1, r2 = min_pos_rx
        # rx index r -> llrs[1:] index j = N-1-r
        idx1 = N - 1 - r1
        idx2 = N - 1 - r2

    mag1 = random.randint(1, min_mag_max)

    if allow_equal_two_min and random.random() < 0.5:
        mag2 = mag1
    else:
        if mag1 == min_mag_max:
            mag2 = mag1
        else:
            mag2 = random.randint(mag1, min_mag_max)

    lower = max(mag1, mag2) + 1
    if lower > 127:
        lower = 127

    mags[idx1] = mag1
    mags[idx2] = mag2
    for j in range(N):
        if j == idx1 or j == idx2:
            continue
        mags[j] = random.randint(lower, 127)

    llrs = [llr0]
    for j in range(N):
        bit = rx[N - 1 - j]
        mag = mags[j]
        llrs.append(mag if bit == 0 else -mag)
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


def gen_one_hard(dec: BCH255_239_Decoder, hard_flip_lt: int = 2):
    k = N - (len(GENERATOR_POLY) - 1)
    tx = [random.randint(0, 1) for _ in range(k)]
    cx = encode_with_generator(tx, GENERATOR_POLY, N)
    rx, _ = flip_bits(cx, choose_flip_count(hard_flip_lt))
    corrected, roots, success, *_ = dec.hard_decode(rx)
    return rx, roots


def gen_one_soft(dec: BCH255_239_Decoder, soft_flip_lt: int = 4, p: int = 2):
    """
    產生一筆 soft decode 測試資料。

    條件：
      - 若實際 error bit 數 = 4：
          兩個最小 |LLR| 的 bit 都是 error bit
      - 若實際 error bit 數 = 3：
          error bits 中至少一個來自兩個最小 |LLR| 的 bit
      - 若 error bit <= 2：
          不加限制
    """
    k = N - (len(GENERATOR_POLY) - 1)

    # 1. 產生隨機 codeword
    tx = [random.randint(0, 1) for _ in range(k)]
    cx = encode_with_generator(tx, GENERATOR_POLY, N)

    # 2. 決定 error 數量
    flip_cnt = choose_flip_count(soft_flip_lt)

    # 3. 根據 flip_cnt 設計 error 位置 & 指定兩個最小 |LLR| 位於哪兩個 rx index
    min_pos_rx: Optional[Tuple[int, int]] = None  # 以 rx index 表示

    if flip_cnt == 4:
        # 兩個最小 LLR 都要是 error bit
        r1, r2 = random.sample(range(N), 2)
        min_pos_rx = (r1, r2)
        others = list(set(range(N)) - {r1, r2})
        extra_errs = random.sample(others, 2)  # 剩下 2 個 error
        flip_pos = sorted({r1, r2} | set(extra_errs))
        rx = cx[:]
        for bit_idx in flip_pos:
            rx[bit_idx] ^= 1

    elif flip_cnt == 3:
        # 至少一個 error 來自兩個最小 LLR bit
        r1, r2 = random.sample(range(N), 2)
        min_pos_rx = (r1, r2)
        # 決定有幾個最小 LLR bit 當 error：1 或 2
        num_min_err = 1 if random.random() < 0.5 else 2
        chosen_min_err = set(random.sample([r1, r2], num_min_err))
        others = list(set(range(N)) - {r1, r2})
        extra_errs = random.sample(others, flip_cnt - num_min_err)
        flip_pos = sorted(chosen_min_err | set(extra_errs))
        rx = cx[:]
        for bit_idx in flip_pos:
            rx[bit_idx] ^= 1

    else:
        # flip_cnt = 0,1,2：不限制，隨機 flip；最小 LLR 位置也隨機
        rx, flip_pos = flip_bits(cx, flip_cnt)
        min_pos_rx = None

    # 4. 產生 LLR，若指定 min_pos_rx 會確保這兩個位置是兩個最小 |LLR|
    llrs = make_llrs_from_rx(rx, N, llr0=0, min_pos_rx=min_pos_rx)
    llrs_in = list(reversed(llrs[1:]))

    # 5. 做 soft decode，讓外層用 all_failed 過濾掉 fail case
    decoded, roots, all_failed = safe_soft_decode(dec, llrs_in, p=p)
    # 需要 debug 時可以印這行：
    print("Generated soft-decode pattern with", flip_cnt, "errors; all_failed =", all_failed)
    return llrs, roots, all_failed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--mode", choices=["hard", "soft"], default="soft")
    ap.add_argument("--ntest", type=int, default=10000)
    ap.add_argument("--seed", type=int, default=1234)
    ap.add_argument("--outdir", type=str, default=".")
    args = ap.parse_args()
    random.seed(args.seed)

    dec = BCH255_239_Decoder()
    data_lines, testa_lines = [], []

    produced = 0
    while produced < args.ntest:
        if args.mode == "hard":
            rx, roots = gen_one_hard(dec)
            llrs = make_llrs_from_rx(rx, N, llr0=0)
        else:
            llrs, roots, all_failed = gen_one_soft(dec)
            if all_failed:
                continue

        rows = pack_llrs_to_64bit_rows(llrs)
        data_lines.extend(rows)
        append_testa_for_roots(testa_lines, roots)
        produced += 1

    if args.mode == "hard":
        data_path = os.path.join(args.outdir, "p20000.txt")
        ans_path = os.path.join(args.outdir, "p20000a.txt")
    else:
        data_path = os.path.join(args.outdir, "soft_decoder_20000.txt")
        ans_path = os.path.join(args.outdir, "soft_decoder_20000a.txt")

    write_lines(data_path, data_lines)
    write_lines(ans_path, testa_lines)
    print("Wrote:", data_path, "and", ans_path)


if __name__ == "__main__":
    main()
