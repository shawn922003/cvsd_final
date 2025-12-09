# 實作 (1023, 983) bch decoder
# p(x) = x^10 + x^3 + 1 is the primitive polynomial for GF(2^10)
# g(x) 為對應的生成多項式

from bch_table import ALPHA_POLY_BITS, BITS_TO_ALPHA_EXP, N, T, GENERATOR_POLY
from bch_gf_extension import GF2mVector
from typing import List, Tuple
from itertools import product
import random


random.seed(0)

# -------------------------
# BCH(1023,983) 解碼（t=20）
# -------------------------
class BCH1023_983_Decoder:
    def __init__(self):
        self.gf = GF2mVector()

    # S_k = sum r[j] * (alpha)^{j*k}; 計算 S1, S3, ..., S39
    def syndromes(self, r: List[int]) -> List[List[int]]:
        assert len(r) == N and all((b & 1) == b for b in r)
        S1 = self.gf.zero()
        S3 = self.gf.zero()
        S5 = self.gf.zero()
        S7 = self.gf.zero()
        
        for j, bit in enumerate(r):
            if bit & 1:
                S1 = self.gf.add(S1, ALPHA_POLY_BITS[j])              # α^{j}
                S3 = self.gf.add(S3, ALPHA_POLY_BITS[(3 * j) % N])    # α^{3j}
                S5 = self.gf.add(S5, ALPHA_POLY_BITS[(5 * j) % N])    # α^{5j}
                S7 = self.gf.add(S7, ALPHA_POLY_BITS[(7 * j) % N])    # α^{7j}
        return S1, S3, S5, S7

    # ------------ 多項式工具（係數是 GF 元素的 10-bit list）------------
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

    # ---------------- Berlekamp（t=20）: 回傳 (sigma1, sigma2, ..., sigma20) ----------------
    # 依投影片 p.22–23：以 μ = -1, 0 為起始列，往上推到 μ = 2t
    def berlekamp(self, S1: List[int], S3: List[int], S5: List[int], S7: List[int]) -> Tuple[List[int], List[int], List[int], List[int]]:
        gf = self.gf

         # 準備 S1..S8（t=4）
        S2 = gf.square_table(S1)
        S4 = gf.square_table(S2)
        S6 = gf.square_table(S3)
        S8 = gf.square_table(S4)
        S  = [S1, S2, S3, S4, S5, S6, S7, S8]  # S[0]=S1, S[1]=S2, ...

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

        
        for mu in range(1, 2*T+1):
            curr_d_mu = d_mu_array[mu]

            if gf.is_zero(curr_d_mu):
                # d_μ = 0：σ、L 不變 → 直接複製到 μ+1 列
                sigma_mu_poly_array.append(sigma_mu_poly_array[mu][:])
                l_mu_array.append(l_mu_array[mu])
            else:
                # 找 ρ < μ 且 d_ρ ≠ 0 使 (ρ - l_ρ) 最大
                rho = 0
                best = -10**9
                for candidate_rho in range(0, mu):
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

            # 計算 d_{μ+1}：用「新的一列」(μ+1) 的 σ、L
            if mu <= 2*T - 1:
                L = l_mu_array[mu + 1]
                sigma_pad = self._poly_pad(sigma_mu_poly_array[mu + 1], L + 1)
                d_next = S[mu]
                for i in range(1, L + 1):
                    d_next = gf.add(d_next, gf.mul_table(sigma_pad[i], S[mu - i]))
                d_mu_array.append(d_next)

        # 最終 σ(x) 取 σ^(2T)(x)
        final_sigma_poly = sigma_mu_poly_array[2*T +1]
        sigma1 = final_sigma_poly[1] if len(final_sigma_poly) > 1 else gf.zero()
        sigma2 = final_sigma_poly[2] if len(final_sigma_poly) > 2 else gf.zero()
        sigma3 = final_sigma_poly[3] if len(final_sigma_poly) > 3 else gf.zero()
        sigma4 = final_sigma_poly[4] if len(final_sigma_poly) > 4 else gf.zero()
        return sigma1, sigma2, sigma3, sigma4, len(final_sigma_poly) - 1 


    # Chien 掃根：找 i 使 σ(α^{-i})=0
    def chien_search(self, sigma1: List[int], sigma2: List[int], sigma3: List[int], sigma4: List[int]) -> List[int]:
        roots = []
        one = self.gf.one()
        for i in range(N):  # N = 1023
            x  = ALPHA_POLY_BITS[(-i) % N]       # x = α^{-i}
            x2 = ALPHA_POLY_BITS[(-2 * i) % N]   # x^2 = α^{-2i}
            x3 = ALPHA_POLY_BITS[(-3 * i) % N]   # x^3 = α^{-3i}
            x4 = ALPHA_POLY_BITS[(-4 * i) % N]   # x^4 = α^{-4i}
            val = self.gf.add(one, 
                    self.gf.add(self.gf.mul_table(sigma1, x),
                    self.gf.add(self.gf.mul_table(sigma2, x2),
                    self.gf.add(self.gf.mul_table(sigma3, x3),
                                self.gf.mul_table(sigma4, x4)))))
            if self.gf.is_zero(val):
                roots.append(i)
        return roots

    # 依位置翻轉
    def correct(self, r: List[int], roots: List[int]) -> List[int]:
        c = r[:]
        for i in roots:
            c[i] ^= 1
        return c

    # 高階接口：回傳（corrected, roots, (sigma1, sigma2, sigma3, sigma4), (S1, S3, S5, S7)）
    def hard_decode(self, r: List[int]):
        S1, S3, S5, S7 = self.syndromes(r)
        sigma1, sigma2, sigma3, sigma4, sigma_length = self.berlekamp(S1, S3, S5, S7)
        roots = self.chien_search(sigma1, sigma2, sigma3, sigma4)


       

        corrected = self.correct(r, roots)




         # 5) 再檢查是否 success：deg(σ) 是否等於 roots 數量
        if (self.gf.is_zero(sigma1)
            and self.gf.is_zero(sigma2)
            and self.gf.is_zero(sigma3)
            and self.gf.is_zero(sigma4)):
            deg = 0
        elif not self.gf.is_zero(sigma4):
            deg = 4
        elif not self.gf.is_zero(sigma3):
            deg = 3
        elif not self.gf.is_zero(sigma2):
            deg = 2
        else:
            deg = 1
            
        success = (deg == len(roots))  and sigma_length <= T
        return corrected, roots,success, (sigma1, sigma2, sigma3, sigma4), (S1, S3, S5, S7)
    
    # ---------------------------- 軟判決解碼 ----------------------------
    def soft_decode(self, r: List[float], p: int = 2):
        # Step 1: 找出 p 個最不可靠的位
        sorted_indices = sorted(range(len(r)), key=lambda i: abs(r[i]))[:p]
        

        # 硬判決基準
        input_rx = [0 if val >= 0 else 1 for val in r]
        
        
        best_correlation = float('-inf')
        best_decoded = None
        best_roots = None
        
        all_failed = True   
        
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
            
            all_failed = False

            # 計算 correlation
            correlation = sum(r[i] * (1 - 2 * corrected[i]) for i in range(len(r)))

            extra_roots = [idx for idx, bit in zip(sorted_indices, pattern)
                        if input_rx[idx] != rx[idx]]

            set_roots = set(roots)
            set_extra = set(extra_roots)
                
                
            if correlation > best_correlation:
                best_correlation = correlation
                best_decoded = corrected
                # roots 要加上你在 pattern 裡面翻轉的那些 index
                

                # 只保留 roots 與 extra_roots 中「不在對方裡」的元素
                best_roots = sorted(set_roots ^ set_extra)   # 對稱差 (symmetric difference)
            elif correlation == best_correlation and best_roots != sorted(set_roots ^ set_extra):
                return None, None, True   # 多解，視為失敗

        return best_decoded, best_roots, all_failed


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
    dec = BCH1023_983_Decoder()
    tx = [0]*400 + [1]*583  # 983 bit 傳輸
    
    # 編碼
    rx = mul(tx, GENERATOR_POLY)
    
    hard_codeword = rx[:]
    error0 = 100
    error1 = 500
    hard_codeword[error0] ^= 1
    hard_codeword[error1] ^= 1
    corrected, roots, _, _, _  = dec.hard_decode(hard_codeword)
    print(f"硬判決：是否修正回原碼字？ {corrected == rx}")
    print(f"硬判決：Chien 找到 roots = {roots}") 
    
    
    
    soft_decode_llr = []
    # 模擬信道不確定性：降低某些位置的可靠性
    errors = [100, 200, 500, 800]
    for idx in range(N):
        soft_decode_llr.append((1-2 *rx[idx]) * 127)

    soft_decode_llr[errors[0]] = soft_decode_llr[errors[0]] / 5
    soft_decode_llr[errors[1]] = soft_decode_llr[errors[1]] / 10
    soft_decode_llr[errors[2]] = soft_decode_llr[errors[2]] / 15
    soft_decode_llr[errors[3]] = soft_decode_llr[errors[3]] / 20

    p = 4  # 測試 4 個最不可靠的位
    soft_corrected, roots = dec.soft_decode(soft_decode_llr, p=p)

    # 驗證與顯示
    print(f"軟判決：是否修正回原碼字？ {soft_corrected == rx}")
    print(f"軟判決：找到錯誤位置 = {roots}")