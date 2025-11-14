# 實作 (63, 51) bch decoder
# p(x) = x^6 + x + 1 is the primitive polynomial for GF(2^6)
# phi1(x) = x^6 + x + 1
# phi2(x) = x^6 + x + 1
# phi3(x) = x^6 + x^4 + x^2 + x + 1
# phi4(x) = x^6 + x + 1
# g(x) = x^12 + x^10 + x^8 + x^5 + x^4 + x^3 + 1


from bch_table import ALPHA_POLY_BITS, BITS_TO_ALPHA_EXP, N, T
from bch_gf_extension import GF2mVector
from typing import List, Tuple





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
        for j, bit in enumerate(r):
            if bit & 1:
                S1 = self.gf.add(S1, ALPHA_POLY_BITS[j])           # α^{j}
                S3 = self.gf.add(S3, ALPHA_POLY_BITS[(3 * j) % N]) # α^{3j}
        return S1, S3

    # ------------ 多項式工具（係數是 GF 元素的 6-bit list）------------
    def _poly_add(self, A: List[List[int]], B: List[List[int]]) -> List[List[int]]:
        '''
            多項式加法：C(x) = A(x) + B(x)
            方法：對應係數相加（GF 加法）
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
            方法：每個係數乘以 s（GF 乘法）
        '''
        return [self.gf.mul_table(a, s) for a in A]

    def _poly_shift(self, A: List[List[int]], k: int) -> List[List[int]]:
        '''
            多項式位移：B(x) = x^k * A(x)
            方法：在前面補 k 個零係數 (x^0 到 x^{k-1} 的係數為0)
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
    # 依 p.22：使用 S1..S4，迭代 discrepancy d、更新 σ(x) 與長度 L
    def berlekamp(self, S1: List[int], S3: List[int]) -> Tuple[List[int], List[int]]:
        # --- Frobenius：S2 = S1^2, S4 = S2^2 ---
        S2 = self.gf.square_table(S1)
        S4 = self.gf.square_table(S2)
        S  = [S1, S2, S3, S4]  # 對應 S_{1..4}，索引 0..3

        one  = self.gf.one()
        zero = self.gf.zero()

        # ---- 變數名稱對齊 PDF p.22 ----
        # μ
        # σ^(μ)(x) → sigma_mu_poly
        # B^(μ)(x) → B_mu
        # ℓ_μ      → l_mu
        # b_μ      → b_mu
        # μ−ℓ_μ    → mu_minus_l_mu（位移計數，等價於原本的 m）
        sigma_mu_poly       = [one]   # σ^(0)(x) = 1
        B_mu_poly           = [one]   # B^(0)(x) = 1  # B^μ(x)：上一個被選中的 σ^(ρ)(x) 的快取（滿足 d_ρ≠0 且 ρ−ℓ_ρ 最大），用於更新項 (d_μ/b_μ)·x^{μ−ℓ_μ}·B^μ(x)
        l_mu           = 0       # ℓ_0 = 0
        b_mu           = one     # b_0 = 1 # b^μ：上一個被選中迭代 ρ 的 discrepancy（= d_ρ），做為比例係數 (d_μ / b^μ) 的分母；當 2ℓ_μ ≤ μ 時更新為當前 d_μ，否則保持不變

        for mu in range(4):  # 用 S1..S4
            # d_μ = S_{μ+1} + sum_{i=1..ℓ_μ} σ_i^(μ) * S_{μ+1-i}
            d_mu = S[mu][:]
            for i in range(1, l_mu + 1):
                d_mu = self.gf.add(d_mu, self.gf.mul_table(sigma_mu_poly[i], S[mu - i]))

            if not self.gf.is_zero(d_mu):
                temp_sigma_mu_poly = sigma_mu_poly[:]  # 暫存 σ^(μ)(x)
                factor = self.gf.div_table(d_mu, b_mu)  # d_μ / b_μ
                sigma_mu_poly = self._poly_add(
                    sigma_mu_poly,
                    self._poly_shift(self._poly_scale(B_mu_poly, factor), mu - l_mu + 1)  # mu - ℓ_μ 之所以要加1，是因為 B^μ(x) 的次數是從 0 開始計算的
                )
                # 若 2ℓ_μ ≤ μ：更新度數與參考多項式
                if 2 * l_mu <= mu:
                    l_new = mu + 1 - l_mu                 # ℓ_{μ+1}
                    B_mu_poly, b_mu = temp_sigma_mu_poly, d_mu                  # B^(μ+1), b_{μ+1}
                    l_mu = l_new


        # σ(x) = 1 + σ1 x + σ2 x^2
        sigma1 = sigma_mu_poly[1] if len(sigma_mu_poly) > 1 else zero
        sigma2 = sigma_mu_poly[2] if len(sigma_mu_poly) > 2 else zero
        return sigma1, sigma2

    # Chien 掃根：找 i 使 σ(α^{-i})=0
    def chien_search(self, sigma1: List[int], sigma2: List[int]) -> List[int]:
        roots = []
        one = self.gf.one()
        for i in range(63):
            x = ALPHA_POLY_BITS[(-i) % N]     # x = α^{-i}
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
    def decode(self, r: List[int]):
        S1, S3 = self.syndromes(r)
        sigma1, sigma2 = self.berlekamp(S1, S3)
        roots = self.chien_search(sigma1, sigma2)
        # 若 roots 少於 deg(σ) 代表失敗；這裡做基本檢查（t=2）
        deg = (0 if self.gf.is_zero(sigma1) and self.gf.is_zero(sigma2)
               else (1 if self.gf.is_zero(sigma2) else 2))
        if len(roots) != deg:
            # 可能超出可修正或雜訊不一致
            raise ValueError(f"Decoding failure: roots={len(roots)} but deg(sigma)={deg}")
        corrected = self.correct(r, roots)
        return corrected, roots, (sigma1, sigma2), (S1, S3)

# -------------------------
# 小測試（用 1/2-bit 錯誤）
# -------------------------
if __name__ == "__main__":
    dec = BCH63_51_Decoder()
    # 假設某合法碼字（這裡用全 0 當示範），再注入錯誤：
    cw = [0]*63

    # 單錯在位置 i0
    i0 = 7
    rx = cw[:]
    rx[i0] ^= 1
    corrected, roots, (s1,s2), (S1,S3) = dec.decode(rx)
    print("1-error roots:", roots)            # 應含 i0
    print("1-error ok  :", corrected == cw)   # True

    # 兩錯在位置 i1, i2
    i1, i2 = 5, 33
    rx2 = cw[:]
    rx2[i1] ^= 1
    rx2[i2] ^= 1
    corrected2, roots2, *_ = dec.decode(rx2)
    print("2-error roots:", roots2)           # 應含 {i1, i2}
    print("2-error ok   :", corrected2 == cw) # True