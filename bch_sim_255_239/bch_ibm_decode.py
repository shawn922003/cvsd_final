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
from itertools import product
import random



# -------------------------
# BCH(255, 239) 解碼（t=2）
# -------------------------
class BCH255_239_Decoder:
    def __init__(self):
        assert N == 255 and T == 2, "This implementation expects N=63, T=2."
        self.gf = GF2mVector()

    # S_k = sum_j r[j] * (alpha)^{j*k} ; returns S1, S3 (other via Frobenius)
    def syndromes(self, r: List[int]) -> Tuple[List[int], List[int]]:
        assert len(r) == N and all((b & 1) == b for b in r)
        S1 = self.gf.zero()
        S3 = self.gf.zero()
        for j, bit in enumerate(r):
            if bit & 1:
                # α^{j}, α^{3j}
                S1 = self.gf.add(S1, ALPHA_POLY_BITS[j])
                S3 = self.gf.add(S3, ALPHA_POLY_BITS[(3 * j) % N])
        return S1, S3

    # -------- polynomial helpers (coefficients are GF elements) --------
    def _poly_add(self, A: List[List[int]], B: List[List[int]]) -> List[List[int]]:
        L = max(len(A), len(B))
        C = []
        for i in range(L):
            a = A[i] if i < len(A) else self.gf.zero()
            b = B[i] if i < len(B) else self.gf.zero()
            C.append(self.gf.add(a, b))
        # trim trailing zeros (optional)
        while len(C) > 1 and self.gf.is_zero(C[-1]):
            C.pop()
        return C

    def _poly_scale(self, A: List[List[int]], s: List[int]) -> List[List[int]]:
        return [self.gf.mul_table(a, s) for a in A]

    def _poly_shift(self, A: List[List[int]], k: int) -> List[List[int]]:
        if k <= 0:
            return A[:]
        return [self.gf.zero() for _ in range(k)] + A[:]

    # ---------------- iBM (Algorithm 4 / Φ–Ψ 版, t=2) ----------------
    def berlekamp_iBM(self, S1: List[int], S3: List[int]) -> Tuple[List[int], List[int], List[int]]:
        """
        Returns sigma0, sigma1, sigma2 (locator polynomial Λ(z) = σ0 + σ1 z + σ2 z^2).
        Notes:
          - We construct S2 = S1^2, S4 = S2^2 by Frobenius (GF square).
          - Algorithm 4 initializes Φ(0)(z) = S(z) + z^{3t}, Ψ(0)(z) = 1, l=0.
          - Iterate 2t steps: Φ <- (Ψ0*Φ - Φ0*Ψ)/z ; update Ψ, l by conditions.
          - Finally, take Λ̂ = Φ(2t)[t..2t].
        """
        # Prepare syndromes S0..S3 mapped from S1,S2,S3,S4
        S2 = self.gf.square_table(S1)
        S4 = self.gf.square_table(S2)
        S = [S1, S2, S3, S4]  # 2t = 4 entries

        three_t = 3 * T
        zero = self.gf.zero()
        one = self.gf.one()

        # Φ(0) = S(z) + z^{3t}, where S(z) = S0 + S1 z + S2 z^2 + S3 z^3
        Phi = [self.gf.zero() for _ in range(three_t + 1)]
        for i in range(2 * T):
            Phi[i] = S[i]
        Phi[three_t] = one

        # Ψ(0) = 1
        Psi = [self.gf.zero() for _ in range(three_t + 1)]
        Psi[0] = one
        l = 0

        # Iterate r = 0..2t-1
        for r in range(2 * T):
            phi0 = Phi[0]
            psi0 = Psi[0]

            # Φ' = (psi0 * Φ  -  phi0 * Ψ) / z , in GF(2^m) subtraction == addition
            newPhi = [self.gf.zero() for _ in range(three_t + 1)]
            for i in range(three_t):
                t1 = self.gf.mul_table(psi0, Phi[i + 1])
                t2 = self.gf.mul_table(phi0, Psi[i + 1])
                newPhi[i] = self.gf.add(t1, t2)

            # Ψ' and l'
            if (not self.gf.is_zero(phi0)) and (l >= 0):
                newPsi = Phi[:]  # use previous Φ(r), not newPhi
                l = -l - 1
            else:
                newPsi = Psi[:]
                l = l + 1

            Phi, Psi = newPhi, newPsi

        # Λ̂(2t)(z) = Φ(2t)[t .. 2t]
        sigma = [Phi[T + j] if (T + j) < len(Phi) else zero for j in range(T + 1)]
        sigma0 = sigma[0] if len(sigma) > 0 else zero
        sigma1 = sigma[1] if len(sigma) > 1 else zero
        sigma2 = sigma[2] if len(sigma) > 2 else zero
        return sigma0, sigma1, sigma2

    # ---------------- Chien Search (use sigma0, NOT hard-coded 1) ----------------
    def chien_search(self, sigma0: List[int], sigma1: List[int], sigma2: List[int]) -> List[int]:
        roots = []
        for i in range(N):
            x = ALPHA_POLY_BITS[(-i) % N]        # α^{-i}
            x2 = ALPHA_POLY_BITS[(-2 * i) % N]   # (α^{-i})^2
            # Λ(α^{-i}) = σ0 + σ1 x + σ2 x^2
            val = self.gf.add(
                sigma0,
                self.gf.add(self.gf.mul_table(sigma1, x),
                            self.gf.mul_table(sigma2, x2))
            )
            if self.gf.is_zero(val):
                roots.append(i)
        return roots

    # Flip positions
    @staticmethod
    def correct(r: List[int], roots: List[int]) -> List[int]:
        c = r[:]
        for i in roots:
            c[i] ^= 1
        return c

    # 估計 deg(Λ)：（注意：iBM 允許整體常數倍；只看零/非零）
    def _loc_degree(self, s0: List[int], s1: List[int], s2: List[int]) -> int:
        if self.gf.is_zero(s1) and self.gf.is_zero(s2):
            return 0
        if self.gf.is_zero(s2):
            return 1
        return 2

    # (可選) 將 locator 正規化為 monic：σ ← σ / σ0
    def _monic(self, s0: List[int], s1: List[int], s2: List[int]) -> Tuple[List[int], List[int], List[int]]:
        if self.gf.is_zero(s0) or self.gf.is_one(s0):
            return s0, s1, s2
        inv_s0 = self.gf.inv_table(s0)
        return self.gf.one(), self.gf.mul_table(s1, inv_s0), self.gf.mul_table(s2, inv_s0)

    # High-level API
    # 高階接口：回傳（corrected, roots, (sigma1, sigma2), (S1, S3)）
    def hard_decode(self, r: List[int]):
        S1, S3 = self.syndromes(r)
        sigma0, sigma1, sigma2 = self.berlekamp_iBM(S1, S3)
        roots = self.chien_search(sigma0, sigma1, sigma2)


        corrected = self.correct(r, roots)

        # 再檢查一次 syndrome 是否為 0，保險
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
                        if input_rx[idx] != rx[idx]]

                set_roots = set(roots)
                set_extra = set(extra_roots)

                # 只保留 roots 與 extra_roots 中「不在對方裡」的元素
                best_roots = sorted(set_roots ^ set_extra)   # 對稱差 (symmetric difference)

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
    dec = BCH255_239_Decoder()
    tx = [0]*239
    
    # 編碼
    rx = mul(tx, GENERATOR_POLY)
    
    hard_codeword = rx[:]
    error0 = 10
    error1 = 100
    hard_codeword[error0] ^= 1
    hard_codeword[error1] ^= 1
    correted, roots, _, _, _ = dec.hard_decode(hard_codeword)
    print(f"硬判決：是否修正回原碼字？ {correted == rx}")
    print(f"硬判決：Chien 找到 roots = {roots}") 
    
    
    # p=2：只在這兩個最不可靠位上枚舉 4 個候選
    soft_decode_llr = []
    errors =[10, 100, 150, 200]
    for idx in range(N):
        soft_decode_llr.append((1-2 *rx[idx]) * 127)
    
    soft_decode_llr[errors[0]] = -20
    soft_decode_llr[errors[1]] = -20
    soft_decode_llr[errors[2]] = -10
    soft_decode_llr[errors[3]] = -10
    
    p = 2
    soft_corrected, roots = dec.soft_decode(soft_decode_llr, p=p)

    # 驗證與顯示
    print(f"軟判決：是否修正回原碼字？ {soft_corrected == rx}")
    print(f"軟判決：Chien 找到 roots = {roots}")
