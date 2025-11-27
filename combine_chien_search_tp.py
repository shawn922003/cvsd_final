#!/usr/bin/env python3
import os, argparse

FIELDS = [
    "data", "code", "mode",
    "err_loc0", "err_loc1", "err_loc2", "err_loc3",
    "num_err", "correct"
]

def read_dat(path):
    with open(path, "r") as f:
        return [ln.strip() for ln in f if ln.strip()]

def write_dat(path, lines):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")

def merge_one_dir(indir, tag):
    out = {}
    for fld in FIELDS:
        path = os.path.join(indir, f"chien_search_{fld}_{tag}.dat")
        out[fld] = read_dat(path)
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir63",   default="bch_63_chien_search_tp")
    ap.add_argument("--dir255",  default="bch_255_chien_search_tp")
    ap.add_argument("--dir1023", default="bch_1023_chien_search_tp")
    ap.add_argument("--order",   default="63,255,1023", help="concat order")
    ap.add_argument("--outdir",  default="pattern_chien_search")
    args = ap.parse_args()

    in_dirs = {"63": args.dir63, "255": args.dir255, "1023": args.dir1023}
    order = [x.strip() for x in args.order.split(",")]

    merged = {fld: [] for fld in FIELDS}
    total_two = 0  # = sum( code!=2 && mode==1 )

    for tag in order:
        d = in_dirs[tag]
        chunk = merge_one_dir(d, tag)

        # 串接
        for fld in FIELDS:
            merged[fld].extend(chunk[fld])

        # 統計 PATTERN_TWO_LEN：僅 63/255 的 i_mode==1 會多吐一筆
        for c, m in zip(chunk["code"], chunk["mode"]):
            try:
                if int(c, 16) != 2 and int(m, 16) == 1:
                    total_two += 1
            except ValueError:
                pass

    # 寫出沒有尾碼的合併檔
    for fld in FIELDS:
        out_path = os.path.join(args.outdir, f"chien_search_{fld}.dat")
        write_dat(out_path, merged[fld])

    # 檢查與摘要
    pat_len = len(merged["data"])
    golden_len = len(merged["err_loc0"])
    expect_golden = pat_len + total_two

    print(f"[OK] Wrote merged files to: {args.outdir}")
    print(f"     PATTERN_LEN      = {pat_len}")
    print(f"     PATTERN_TWO_LEN  = {total_two}  (non-1023 with i_mode==1)")
    if golden_len != expect_golden:
        print(f"[WARN] golden lines = {golden_len}, expected = {expect_golden}")
    else:
        print(f"[CHECK] golden lines match: {golden_len}")

if __name__ == "__main__":
    main()
