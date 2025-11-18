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

    # 計算 syndromes（只需奇數次：S1, S3）
    # S_k = sum_{j=0}^{62} r[j] * α^{j*k}
    def syndromes(self, r: List[int]) -> Tuple[List[int], List[int]]:
        assert len(r) == N and all((b & 1) == b for b in r)
        S1 = self.gf.zero()
        S3 = self.gf.zero()
        for j, bit in enumerate(r):
            if bit & 1:
                S1 = self.gf.add(S1, ALPHA_POLY_BITS[j])           # α^{j}
                S3 = self.gf.add(S3, ALPHA_POLY_BITS[(3 * j) % N]) # α^{3j}
        return S1, S3

    # Peterson（t=2）：σ(x)=1 + σ1 x + σ2 x^2
    # 在 GF(2) 上，S1 = z1 + z2，S3 = z1^3 + z2^3，且 S2 = S1^2
    # 可用等式：σ1 = S1； σ2 = S3/S1 + S1^2（當 S1 ≠ 0）
    def peterson(self, S1: List[int], S3: List[int]) -> Tuple[List[int], List[int]]:
        if self.gf.is_zero(S1) and self.gf.is_zero(S3):
            # 無錯誤
            return self.gf.zero(), self.gf.zero()
        if self.gf.is_zero(S1):
            # S1=0 但 S3!=0 幾乎不可能在 ≤2錯下成立，視為不可解
            raise ValueError("Decoding failure: S1=0 but S3!=0 (beyond t=2 or inconsistent).")
        sigma1 = S1[:]  # = S1
        s1sq = self.gf.square_table(S1)
        s3_over_s1 = self.gf.div_table(S3, S1)
        sigma2 = self.gf.add(s3_over_s1, s1sq)
        return sigma1, sigma2

    # Chien 掃根：找 i∈[0..62] 使 σ(α^{-i}) = 0
    def chien_search(self, sigma1: List[int], sigma2: List[int]) -> List[int]:
        roots = []
        for i in range(63):
            x = ALPHA_POLY_BITS[(-i) % N]     # x = α^{-i}
            x2 = ALPHA_POLY_BITS[(-2 * i) % N]   # x^2 = α^{-2i}
            term = self.gf.add(self.gf.one(),
                                self.gf.add(self.gf.mul_table(sigma1, x),
                                            self.gf.mul_table(sigma2, x2)))
            if self.gf.is_zero(term):
                roots.append(i)
        return roots

    # 將 roots（位置 i）翻轉位元
    def correct(self, r: List[int], roots: List[int]) -> List[int]:
        c = r[:]
        for i in roots:
            c[i] ^= 1
        return c

    # 高階接口：回傳（corrected, roots, (sigma1, sigma2), (S1, S3)）
    def decode(self, r: List[int]) -> Tuple[List[int], List[int], Tuple[List[int], List[int]], Tuple[List[int], List[int]]]:
        S1, S3 = self.syndromes(r)
        sigma1, sigma2 = self.peterson(S1, S3)
        roots = self.chien_search(sigma1, sigma2)
        if len(roots) > T:
            raise ValueError(f"Decoding failure: #roots={len(roots)} > T={T}")
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