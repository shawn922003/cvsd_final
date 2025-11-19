# 實作 (63, 51) bch decoder
# p(x) = x^6 + x + 1 is the primitive polynomial for GF(2^6)
# phi1(x) = x^6 + x + 1
# phi2(x) = x^6 + x + 1
# phi3(x) = x^6 + x^4 + x^2 + x + 1
# phi4(x) = x^6 + x + 1
# g(x) = x^12 + x^10 + x^8 + x^5 + x^4 + x^3 + 1

from bch_table import ALPHA_POLY_BITS, BITS_TO_ALPHA_EXP, N, T, GENERATOR_POLY
from bch_gf_extension import GF2mVector
from typing import List, Tuple
from itertools import product
import random


random.seed(0)

# -------------------------
# BCH(63,51) 解碼（t=2）
# -------------------------
class BCH63_51_Decoder:
    def __init__(self):
        self.gf = GF2mVector()

    # S_k = sum r[j] * (alpha)^{j*k}; 保持相容，只回 S1, S3
    def syndromes(self, r: List[int]) -> Tuple[List[int], List[int]]:
        assert len(r) == N and all((b & 1) == b for b in r)
        S1 = self.gf.zero()
        S3 = self.gf.zero()
        for j, bit in reversed(list(enumerate(r))):
            if bit & 1:
                S1 = self.gf.add(S1, ALPHA_POLY_BITS[j])           # α^{j}
                S3 = self.gf.add(S3, ALPHA_POLY_BITS[(3 * j) % N]) # α^{3j}
        return S1, S3

    # ------------ 多項式工具（係數是 GF 元素的 6-bit list）------------
    def _poly_add(self, A: List[List[int]], B: List[List[int]]) -> List[List[int]]:
        '''
            多項式加法：C(x) = A(x) + B(x)
        '''
        L = max(len(A), len(B))
        Z = self.gf.zero()
        C = []
        for i in range(L):
            a = A[i] if i < len(A) else Z
            b = B[i] if i < len(B) else Z
            C.append(self.gf.add(a, b))
        # 去尾端的全零係數（可省略）
        while len(C) > 1 and self.gf.is_zero(C[-1]):
            C.pop()
        return C

    def _poly_scale(self, A: List[List[int]], s: List[int]) -> List[List[int]]:
        '''
            多項式數乘：B(x) = s * A(x)
        '''
        return [self.gf.mul_table(a, s) for a in A]

    def _poly_shift(self, A: List[List[int]], k: int) -> List[List[int]]:
        '''
            多項式位移：B(x) = x^k * A(x)
        '''
        if k <= 0:
            return A[:]
        Z = self.gf.zero()
        return [Z for _ in range(k)] + A[:]

    def _poly_pad(self, A: List[List[int]], length: int) -> List[List[int]]:
        Z = self.gf.zero()
        if len(A) < length:
            A = A + [Z] * (length - len(A))
        return A

    # ---------------- Berlekamp（t=2）: 回傳 (sigma1, sigma2) ----------------
    # 依 p.22–23：把 μ 從投影片的 -1 起跳，平移成從 0 起跳
    # ---------------- Berlekamp（t=2）: 回傳 (sigma1, sigma2) ----------------
    # 依投影片 p.22–23：以 μ = -1, 0 為起始列，往上推到 μ = 2t
    def berlekamp(self, S1: List[int], S3: List[int]) -> Tuple[List[int], List[int]]:
        gf = self.gf

        # 準備 S1..S4（t=2）
        S2 = gf.square_table(S1)
        S4 = gf.square_table(S2)
        S  = [S1, S2, S3, S4]  # S[0]=S1, S[1]=S2, ...

        sigma_mu_poly_array: List[List[List[int]]] = []
        d_mu_array: List[List[int]] = []
        l_mu_array: List[int] = []

        # μ = -1  對應 index 0
        sigma_mu_poly_array.append([gf.one()])
        d_mu_array.append(gf.one())
        l_mu_array.append(0)

        # μ = 0   對應 index 1
        sigma_mu_poly_array.append([gf.one()])
        d_mu_array.append(S[0])      # d_0 = S1
        l_mu_array.append(0)

        # μ = 1..2T-1 （t=2 → μ=1,2,3），每一步產生 σ^(μ+1)
        for mu in range(1, 2*T + 1):     # FIX#1: μ 從 1 起算，用 d_mu
            curr_d_mu = d_mu_array[mu]   # 用 d_μ，不是 d_{μ-1}

            if gf.is_zero(curr_d_mu):
                # d_μ = 0：σ、L 不變 → 直接複製到 μ+1 列
                sigma_mu_poly_array.append(sigma_mu_poly_array[mu][:])
                l_mu_array.append(l_mu_array[mu])
            else:
                # 找 ρ < μ 且 d_ρ ≠ 0 使 (ρ - l_ρ) 最大
                rho = 0
                best = -10**9
                for candidate_rho in range(0, mu):   # FIX#2: 允許到 ρ = μ-1
                    if not gf.is_zero(d_mu_array[candidate_rho]):
                        val = candidate_rho - l_mu_array[candidate_rho]
                        if val > best:
                            best = val
                            rho  = candidate_rho

                shift  = mu - rho
                factor = gf.div_table(curr_d_mu, d_mu_array[rho])
                sigma_next = self._poly_add(
                    sigma_mu_poly_array[mu],
                    self._poly_scale(
                        self._poly_shift(sigma_mu_poly_array[rho], shift),
                        factor
                    )
                )
                l_next = max(l_mu_array[mu], l_mu_array[rho] + (mu - rho))
                sigma_mu_poly_array.append(sigma_next)
                l_mu_array.append(l_next)

            # 計 d_{μ+1}：用「新的一列」(μ+1) 的 σ、L
            if mu <= 2*T - 1:
                L = l_mu_array[mu + 1]                        # FIX#3: 用 L_{μ+1}
                sigma_pad = self._poly_pad(sigma_mu_poly_array[mu + 1], L + 1)
                d_next = S[mu]                                 # S_{μ+1}（0-based）
                for i in range(1, L + 1):
                    d_next = gf.add(d_next, gf.mul_table(sigma_pad[i], S[mu - i]))
                d_mu_array.append(d_next)

        # 最終 σ(x) 取 σ^(2T)(x)
        final_sigma_poly = sigma_mu_poly_array[2*T + 1]
        sigma1 = final_sigma_poly[1] if len(final_sigma_poly) > 1 else gf.zero()
        sigma2 = final_sigma_poly[2] if len(final_sigma_poly) > 2 else gf.zero()
        return sigma1, sigma2


    # Chien 掃根：找 i 使 σ(α^{-i})=0
    def chien_search(self, sigma1: List[int], sigma2: List[int]) -> List[int]:
        roots = []
        one = self.gf.one()
        for i in range(63):
            x  = ALPHA_POLY_BITS[(-i) % N]       # x = α^{-i}
            x2 = ALPHA_POLY_BITS[(-2 * i) % N]   # x^2 = α^{-2i}
            val = self.gf.add(one, self.gf.add(self.gf.mul_table(sigma1, x),
                                               self.gf.mul_table(sigma2, x2)))
            if self.gf.is_zero(val):
                roots.append(i)
        return roots

    # 依位置翻轉
    def correct(self, r: List[int], roots: List[int]) -> List[int]:
        c = r[:]
        for i in roots:
            c[i] ^= 1
        return c

    # 高階接口：回傳（corrected, roots, (sigma1, sigma2), (S1, S3)）
    def hard_decode(self, r: List[int]):
        S1, S3 = self.syndromes(r)
        sigma1, sigma2 = self.berlekamp(S1, S3)
        roots = self.chien_search(sigma1, sigma2)


        corrected = self.correct(r, roots)

        # 再檢是否success
        if self.gf.is_zero(sigma1) and self.gf.is_zero(sigma2):
            deg = 0
        elif self.gf.is_zero(sigma2):
            deg = 1
        else:
            deg = 2
            
        success = (deg == len(roots))
        
        
        return corrected, roots, success, (sigma1, sigma2), (S1, S3)
    
    # ---------------------------- 軟判決解碼 ----------------------------
    def soft_decode(self, r: List[float], p: int = 2):
        # Step 1: 找出 p 個最不可靠位（|LLR| 最小）
        sorted_indices = sorted(range(len(r)), key=lambda i: abs(r[i]))[:p]

        # 硬判決基準
        input_rx = [0 if val >= 0 else 1 for val in r]

        best_correlation = float('-inf')
        best_decoded = None
        best_roots = None

        for pattern in product([0, 1], repeat=p):
            # 先從硬判決結果複製一份
            rx = input_rx[:]

            # 依 pattern 覆寫/翻轉最不可靠的位
            for idx, bit in zip(sorted_indices, pattern):
                rx[idx] = bit   # 或 rx[idx] ^= bit，看你想怎麼定義 pattern

            # 硬解碼
            corrected, roots, success, _, _ = self.hard_decode(rx)

            if not success:
                # 解碼失敗的 candidate 丟掉，不算 correlation
                continue

            # 計算 correlation
            correlation = sum(r[i] * (1 - 2 * corrected[i]) for i in range(len(r)))

            if correlation > best_correlation:
                best_correlation = correlation
                best_decoded = corrected
                # roots 要加上你在 pattern 裡面翻轉的那些 index
                extra_roots = [idx for idx, bit in zip(sorted_indices, pattern)
                            if input_rx[idx] != corrected[idx]]
                best_roots = sorted(set(roots + extra_roots))

        return best_decoded, best_roots


def mul(a, b):
    result = [0] * (len(a) + len(b) - 1)
    for i in range(len(a)):
        if a[i] == 1:
            for j in range(len(b)):
                if b[j] == 1:
                    result[i + j] ^= 1
                    
    return result[:N]  # 截斷為 N 位

# -------------------------
# 小測試（用 1/2-bit 錯誤）
# -------------------------
if __name__ == "__main__":
    dec = BCH63_51_Decoder()
    
    rx_int = int("0102_0304_0506_0708", base=16)
    rx = [(rx_int >> i) & 1 for i in range(63)]
    
    s1, s3 = dec.syndromes(rx)
    
    print("S1:", BITS_TO_ALPHA_EXP[tuple(s1)] if not dec.gf.is_zero(s1) else "0")
    print("S3:", BITS_TO_ALPHA_EXP[tuple(s3)] if not dec.gf.is_zero(s3) else "0")
    
    # tx = [0]*51
    
    # # 編碼
    # # rx = mul(tx, GENERATOR_POLY)
    # rx = [0] * 63
    
    # hard_codeword = rx[:]
    # error0 = 10
    # error1 = 20
    # hard_codeword[error0] ^= 1
    # hard_codeword[error1] ^= 1
    # correted, roots, _, _, _ = dec.hard_decode(hard_codeword)
    # print(f"硬判決：是否修正回原碼字？ {correted == rx}")
    # print(f"硬判決：Chien 找到 roots = {roots}") 
    
    
    # # p=2：只在這兩個最不可靠位上枚舉 4 個候選
    # soft_decode_llr = []
    # errors =[10, 20, 30, 40]
    # for idx in range(N):
    #     soft_decode_llr.append((1-2 *rx[idx]) * 127)
    
    # soft_decode_llr[errors[0]] = -soft_decode_llr[errors[0]]
    # soft_decode_llr[errors[1]] = -soft_decode_llr[errors[1]]
    # soft_decode_llr[errors[2]] = -soft_decode_llr[errors[2]] / 10
    # soft_decode_llr[errors[3]] = -soft_decode_llr[errors[3]] / 10
    
    # p = 2
    # soft_corrected, roots = dec.soft_decode(soft_decode_llr, p=p)

    # # 驗證與顯示
    # print(f"軟判決：是否修正回原碼字？ {soft_corrected == rx}")
    # print(f"軟判決：Chien 找到 roots = {roots}")
