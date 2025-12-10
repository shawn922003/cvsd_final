# compare_decoders.py
#
# 隨機產生 10000 筆 BCH(255,239) codeword，
# 各加入 0~4 個隨機 error bit，
# 分別用：
#   - bch_berlekamp_decode.BCH255_239_Decoder
#   - bch_ibm_decode.BCH255_239_Decoder
# 的 hard_decode() 來解碼，
# 比較兩者的 corrected / roots / success。
#
# sigma 不比較。

import random

from bch_table import N, T, GENERATOR_POLY
from bch_berlekamp_decode import BCH63_51_Decoder as BerlekampDecoder
from bch_ibm_decode import BCH63_51_Decoder as IBMDecoder


def mul_poly(msg_bits, gen_poly, N):
    """
    多項式乘法 (GF(2))：
        c(x) = m(x) * g(x)
    輸入 / 輸出都是 bit list (LSB 在 index 0)，
    結果截斷成 N bit。
    """
    res = [0] * (len(msg_bits) + len(gen_poly) - 1)
    for i, b in enumerate(msg_bits):
        if b:
            for j, gb in enumerate(gen_poly):
                if gb:
                    res[i + j] ^= 1
    return res[:N]


def random_message(k):
    """產生長度 k 的隨機 bit list。"""
    return [random.randint(0, 1) for _ in range(k)]


def run_trials(num_trials=10000, max_errors=4, seed=0):
    random.seed(seed)

    # 檢查一下參數
    assert N == 63 and T == 2, "目前腳本是針對 BCH(255,239), t=2 寫的。"

    # 從 N 跟 g(x) 自動算出 k = N - deg(g)
    k = N - (len(GENERATOR_POLY) - 1)
    print(f"N = {N}, T = {T}, k = {k}, degree(g) = {len(GENERATOR_POLY) - 1}")

    dec_berlekamp = BerlekampDecoder()
    dec_ibm = IBMDecoder()

    mismatch_count = 0
    success_flag_diff = 0
    roots_diff = 0
    corrected_diff = 0

    # 依 error weight 做統計
    stats = {
        w: {
            "total": 0,
            "both_ok": 0,       # 兩個 decoder 都成功且 corrected == 原 codeword
            "berlekamp_only": 0,
            "ibm_only": 0,
            "both_fail_or_wrong": 0,  # 兩個都沒修回原碼字 (包含 success=False 或修錯)
        }
        for w in range(max_errors + 1)
    }

    for t_id in range(num_trials):
        # 1) random message (長度 k = 239)
        msg = random_message(k)

        # 2) encode: c(x) = m(x) * g(x)
        codeword = mul_poly(msg, GENERATOR_POLY, N)

        # 3) 加入 0~max_errors 個隨機錯誤
        w = random.randint(0, max_errors)
        error_pos = random.sample(range(N), w)
        r_rx = codeword[:]
        for pos in error_pos:
            r_rx[pos] ^= 1

        stats[w]["total"] += 1

        # 4) 兩種 hard decode
        c1, roots1, success1, _, _ = dec_berlekamp.hard_decode(r_rx)
        c2, roots2, success2, _, _ = dec_ibm.hard_decode(r_rx)

        # 6) 比較兩個 decoder 的輸出是否一致（不看 sigma）
        if success1 != success2:
            success_flag_diff += 1

        if sorted(roots1) != sorted(roots2):
            roots_diff += 1

        if c1 != c2:
            corrected_diff += 1

        print(f"-----------[Trial {t_id}]------")
        if (success1 != success2):
            print(f"[Trial {t_id}] [ERROR]: Success flag mismatch!")
        elif (success1 == False and success2 == False):
            print(f"[Trial {t_id}] [CORRECT] Both decoders failed as expected.")
        else:
            if c1 != c2:
                print(f"[Trial {t_id}] [ERROR]: Corrected codeword mismatch!")
            else:
                print(f"[Trial {t_id}] [CORRECT] Both decoders succeeded and matched.")
            if sorted(roots1) != sorted(roots2):
                print(f"[Trial {t_id}] [ERROR]: Roots mismatch!")
            else:
                print(f"[Trial {t_id}] [CORRECT] Roots matched.")
                
        print()
            
            



if __name__ == "__main__":
    # 你要改試次或最大 error 數就在這裡調
    run_trials(num_trials=10000, max_errors=4, seed=0)
