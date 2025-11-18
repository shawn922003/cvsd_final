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
        S = []
        for k in range(1, 2*T, 2):  # k = 1, 3, 5, ..., 39
            S_k = self.gf.zero()
            for j, bit in enumerate(r):
                if bit & 1:
                    S_k = self.gf.add(S_k, ALPHA_POLY_BITS[(k * j) % N])  # α^{kj}
            S.append(S_k)
        return S

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
    def berlekamp(self, S: List[List[int]]) -> List[List[int]]:
        gf = self.gf

        # 準備 S1..S40（t=20）
        # S 已經是 [S1, S3, S5, ..., S39]，需要補上偶數次方
        S_full = [gf.zero()]  # S[0] 不使用
        for i in range(1, 2*T + 1):
            if i % 2 == 1:
                # 奇數：直接從輸入取
                S_full.append(S[(i-1)//2])
            else:
                # 偶數：從奇數平方得到
                # S_{2k} = (S_k)^2
                S_full.append(gf.square_table(S_full[i//2]))

        sigma_mu_poly_array: List[List[List[int]]] = []
        d_mu_array: List[List[int]] = []
        l_mu_array: List[int] = []

        # μ = -1  對應 index 0
        sigma_mu_poly_array.append([gf.one()])
        d_mu_array.append(gf.one())
        l_mu_array.append(0)

        # μ = 0   對應 index 1
        sigma_mu_poly_array.append([gf.one()])
        d_mu_array.append(S_full[1])      # d_0 = S1
        l_mu_array.append(0)

        # μ = 1..2T-1 （t=20 → μ=1,2,...,39），每一步產生 σ^(μ+1)
        for mu in range(1, 2*T):
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
                d_next = S_full[mu + 1]
                for i in range(1, L + 1):
                    d_next = gf.add(d_next, gf.mul_table(sigma_pad[i], S_full[mu + 1 - i]))
                d_mu_array.append(d_next)

        # 最終 σ(x) 取 σ^(2T)(x)
        final_sigma_poly = sigma_mu_poly_array[2*T]
        # 提取係數 sigma1, sigma2, ..., sigma20
        sigma_coeffs = []
        for i in range(1, T + 1):
            if i < len(final_sigma_poly):
                sigma_coeffs.append(final_sigma_poly[i])
            else:
                sigma_coeffs.append(gf.zero())
        return sigma_coeffs


    # Chien 掃根：找 i 使 σ(α^{-i})=0
    def chien_search(self, sigma_coeffs: List[List[int]]) -> List[int]:
        roots = []
        one = self.gf.one()
        for i in range(N):
            # 計算 σ(α^{-i}) = 1 + σ1*α^{-i} + σ2*α^{-2i} + ... + σt*α^{-ti}
            val = one
            for j in range(1, T + 1):
                x_power = ALPHA_POLY_BITS[(-j * i) % N]  # α^{-ji}
                val = self.gf.add(val, self.gf.mul_table(sigma_coeffs[j-1], x_power))
            if self.gf.is_zero(val):
                roots.append(i)
        return roots

    # 依位置翻轉
    def correct(self, r: List[int], roots: List[int]) -> List[int]:
        c = r[:]
        for i in roots:
            c[i] ^= 1
        return c

    # 高階接口：回傳（corrected, roots, sigma_coeffs, S）
    def hard_decode(self, r: List[int]):
        S = self.syndromes(r)
        sigma_coeffs = self.berlekamp(S)
        roots = self.chien_search(sigma_coeffs)
        corrected = self.correct(r, roots)
        return corrected, roots, sigma_coeffs, S
    
    # ---------------------------- 軟判決解碼 ----------------------------
    def soft_decode(self, r: List[int], p: int = 4):
        # Step 1: 找出 p 個最不可靠的位
        sorted_indices = sorted(range(len(r)), key=lambda i: abs(r[i]))[:p]
        
        # Step 2: 生成所有 2^p 的測試模式
        test_patterns = list(product([0, 1], repeat=p))
        
        best_correlation = float('-inf')
        best_decoded = None
        best_roots = None
        
        # 將 LLR 轉換為硬判決
        input_rx = []
        for val in r:
            if val >= 0:
                input_rx.append(0)
            else:
                input_rx.append(1)
        
        # Step 3: 測試每一個測試模式
        for pattern in test_patterns:
            # 複製接收信號
            rx = input_rx[:]
            
            # 根據當前測試模式翻轉最不可靠的位
            for idx, bit in zip(sorted_indices, pattern):
                rx[idx] = bit
            
            # Step 4: 使用硬判決解碼
            corrected, roots, sigma_coeffs, S = self.hard_decode(rx)
            
            # Step 5: 計算相關性
            correlation = sum([r[i] * (1 - 2 * corrected[i]) for i in range(len(r))])
            
            # Step 6: 保持最佳解碼結果
            if correlation > best_correlation:
                best_correlation = correlation
                best_decoded = corrected
                # 重新計算相對於原始輸入的錯誤位置
                best_roots = [i for i in range(len(input_rx)) 
                            if input_rx[i] != corrected[i]]
    
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
    dec = BCH1023_983_Decoder()
    tx = [0]*400 + [1]*583  # 983 bit 傳輸
    
    # 編碼
    rx = mul(tx, GENERATOR_POLY)
    
    hard_codeword = rx[:]
    error0 = 100
    error1 = 500
    hard_codeword[error0] ^= 1
    hard_codeword[error1] ^= 1
    hard_decode = dec.hard_decode(hard_codeword)
    print(f"硬判決：是否修正回原碼字？ {hard_decode[0] == rx}")
    print(f"硬判決：Chien 找到 roots = {hard_decode[1]}") 
    
    
    # === 軟判決測試 ===
    # 製造接收訊號（有錯誤）
    received = rx[:]
    error_positions = [100, 500]  # 實際錯誤位置
    for pos in error_positions:
        received[pos] ^= 1

    # 基於接收訊號生成 LLR
    soft_decode_llr = []
    for idx in range(N):
        # 正確映射：0→正LLR, 1→負LLR
        soft_decode_llr.append((1 - 2 * received[idx]) * 127)

    # 模擬信道不確定性：降低某些位置的可靠性
    unreliable_positions = [100, 200, 500, 800]
    # 只降低絕對值，不改變符號
    soft_decode_llr[unreliable_positions[0]] = soft_decode_llr[unreliable_positions[0]] / 5
    soft_decode_llr[unreliable_positions[1]] = soft_decode_llr[unreliable_positions[1]] / 10
    soft_decode_llr[unreliable_positions[2]] = soft_decode_llr[unreliable_positions[2]] / 15
    soft_decode_llr[unreliable_positions[3]] = soft_decode_llr[unreliable_positions[3]] / 20

    p = 4  # 測試 4 個最不可靠的位
    soft_corrected, roots = dec.soft_decode(soft_decode_llr, p=p)

    # 驗證與顯示
    print(f"軟判決：是否修正回原碼字？ {soft_corrected == rx}")
    print(f"軟判決：找到錯誤位置 = {roots}")