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
        assert N == 63 and T == 2, "This implementation expects N=63, T=2."
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
    def apply_corrections(r: List[int], roots: List[int]) -> List[int]:
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
    def decode(self, r: List[int], make_monic: bool = False):
        S1, S3 = self.syndromes(r)
        sigma0, sigma1, sigma2 = self.berlekamp_iBM(S1, S3)

        # 可選：把 locator 變 monic，僅為了美觀；Chien 搜根用原/monic 都一樣
        if make_monic:
            sigma0, sigma1, sigma2 = self._monic(sigma0, sigma1, sigma2)

        roots = self.chien_search(sigma0, sigma1, sigma2)

        deg = self._loc_degree(sigma0, sigma1, sigma2)
        if len(roots) != deg:
            raise ValueError(f"Decoding failure: roots={len(roots)} but deg(sigma)={deg}")

        corrected = self.apply_corrections(r, roots)
        return corrected, roots, (sigma0, sigma1, sigma2), (S1, S3)


# -------------------------
# Quick self-test
# -------------------------
if __name__ == "__main__":
    dec = BCH63_51_Decoder()

    # 全 0 碼字 + 1-bit error
    cw = [0] * N
    i0 = 7
    rx = cw[:]
    rx[i0] ^= 1
    corrected, roots, (s0, s1, s2), (S1, S3) = dec.decode(rx)
    print("[1-error] roots =", roots, " ok =", (corrected == cw))

    # 全 0 碼字 + 2-bit errors
    i1, i2 = 5, 33
    rx2 = cw[:]
    rx2[i1] ^= 1
    rx2[i2] ^= 1
    corrected2, roots2, *_ = dec.decode(rx2)
    print("[2-error] roots =", roots2, " ok =", (corrected2 == cw))