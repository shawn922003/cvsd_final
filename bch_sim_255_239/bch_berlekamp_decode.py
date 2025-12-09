# 實作 (255, 239) BCH decoder
# p(x) = 1 + x^2 + x^3 + x^4 + x^8 is the primitive polynomial for GF(2^8)
# φ1(x) = φ2(x) = φ4(x) = 1 + x^2 + x^3 + x^4 + x^8
# φ3(x) = 1 + x + x^2 + x^4 + x^5 + x^6 + x^8
# g(x) = 1 + x + x^5 + x^6 + x^8 + x^9 + x^10 + x^11 + x^13 + x^14 + x^16

from bch_table import ALPHA_POLY_BITS, BITS_TO_ALPHA_EXP, N, T, GENERATOR_POLY
from bch_gf_extension import GF2mVector
from typing import List, Tuple
from itertools import product
import random


random.seed(0)

# -------------------------
# BCH(255,239) 解碼（t=2）
# -------------------------
class BCH255_239_Decoder:
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

    # ------------ 多項式工具（係數是 GF 元素的 8-bit list）------------
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
    # 依投影片 p.22–23：把 μ 從投影片的 -1 起跳，平移成從 0 起跳
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
        for mu in range(1, 2*T+1):     # μ 從 1 起算，用 d_mu
            curr_d_mu = d_mu_array[mu]   # 用 d_μ，不是 d_{μ-1}

            if gf.is_zero(curr_d_mu):
                # d_μ = 0：σ、L 不變 → 直接複製到 μ+1 列
                sigma_mu_poly_array.append(sigma_mu_poly_array[mu][:])
                l_mu_array.append(l_mu_array[mu])
            else:
                # 找 ρ < μ 且 d_ρ ≠ 0 使 (ρ - l_ρ) 最大
                rho = 0
                best = -10**9
                for candidate_rho in range(0, mu):   # 允許到 ρ = μ-1
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
                L = l_mu_array[mu + 1]
                sigma_pad = self._poly_pad(sigma_mu_poly_array[mu + 1], L + 1)
                d_next = S[mu]                                 # S_{μ+1}（0-based）
                for i in range(1, L + 1):
                    d_next = gf.add(d_next, gf.mul_table(sigma_pad[i], S[mu - i]))
                d_mu_array.append(d_next)

        # 最終 σ(x) 取 σ^(2T)(x)
        final_sigma_poly = sigma_mu_poly_array[2*T+1]
        sigma1 = final_sigma_poly[1] if len(final_sigma_poly) > 1 else gf.zero()
        sigma2 = final_sigma_poly[2] if len(final_sigma_poly) > 2 else gf.zero()
        return sigma1, sigma2, len(final_sigma_poly) - 1


    # Chien 掃根：找 i 使 σ(α^{-i})=0
    def chien_search(self, sigma1: List[int], sigma2: List[int]) -> List[int]:
        roots = []
        one = self.gf.one()
        for i in range(N):
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
        sigma1, sigma2, sigma_length = self.berlekamp(S1, S3)
        roots = self.chien_search(sigma1, sigma2)


        corrected = self.correct(r, roots)

        # 再檢查一次 syndrome 是否為 0，保險
        if self.gf.is_zero(sigma1) and self.gf.is_zero(sigma2):
            deg = 0
        elif self.gf.is_zero(sigma2):
            deg = 1
        else:
            deg = 2
            
        success = (deg == len(roots)) and sigma_length <= T

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
        
        all_failed = True

        if p == 2:
            patterns = [(0,0), (1,0), (0,1), (1,1)]
        else:
            patterns = product([0, 1], repeat=p)
        for pattern in patterns:
            # 先從硬判決結果複製一份
            rx = input_rx[:]

            # 依 pattern 覆寫/翻轉最不可靠的位
            for idx, bit in zip(sorted_indices, pattern):
                rx[idx] ^= bit   # 或 rx[idx] ^= bit，看你想怎麼定義 pattern

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
def bits_to_signed_list(bit_str):
    assert len(bit_str) % 8 == 0, "長度不是 8 的倍數"
    vals = []
    for i in range(0, len(bit_str), 8):
        byte = bit_str[i:i+8]
        u = int(byte, 2)       # 先當成 unsigned
        if u >= 128:           # 轉成 signed 8-bit
            u -= 256
        vals.append(u)
    return vals


# -------------------------
# 小測試（用 1/2-bit 錯誤）
# -------------------------
if __name__ == "__main__":
    dec = BCH255_239_Decoder()
    # tx = [0]*239
    
    # # 編碼
    # rx = mul(tx, GENERATOR_POLY)
    
    # hard_codeword = rx[:]
    # error0 = 10
    # error1 = 100
    # hard_codeword[error0] ^= 1
    # hard_codeword[error1] ^= 1
    # correted, roots, _, _, _ = dec.hard_decode(hard_codeword)
    # print(f"硬判決：是否修正回原碼字？ {correted == rx}")
    # print(f"硬判決：Chien 找到 roots = {roots}") 
    
    
    # # p=2：只在這兩個最不可靠位上枚舉 4 個候選
    # soft_decode_llr = []
    # errors =[10, 100, 150, 200]
    # for idx in range(N):
    #     soft_decode_llr.append((1-2 *rx[idx]) * 127)
    
    # soft_decode_llr[errors[0]] = -20
    # soft_decode_llr[errors[1]] = -20
    # soft_decode_llr[errors[2]] = -10
    # soft_decode_llr[errors[3]] = -10
    
    # p = 2
    # soft_corrected, roots = dec.soft_decode(soft_decode_llr, p=p)

    # # 驗證與顯示
    # print(f"軟判決：是否修正回原碼字？ {soft_corrected == rx}")
    # print(f"軟判決：Chien 找到 roots = {roots}")
    
    bits = """0000000000111001101010001110101111001011001010111101000110111011
1101010010010110101111010100001111010100100111000001100110101100
0010000111110001011101110001011101000011010001111011111010001110
1011111001111110001000100110110011110000101000101010000000110011
0111010001010010001011010010100101100100101001011011111001100011
0001101001010001110110101001010110101001101100100101101111101110
1000100111100001101111101011001011110101110100010000100001000100
0011001000101001101000000101000011010011010010001101110011110000
1101011110100110010101001101110111101101110001001100011100110000
0011000010010101001010011011101100101011110101100001011001001111
0011101000010110110000101100001010001101101000101111001010110110
0100000001010011101011100101110000110101101100001100100000001110
1110010000101010010100111001000100001100000101101101011100100000
0111111000001010000111100111110111010110010010111000100101101011
1010100100010000100101111110110010010101111100101001011111111000
1110011110110110100001010001111011110110101110001011010000110101
0111111110001010011000110001011011001001010111001101101110000101
1111011111000101010001011110000000110111010001010111001000001010
1101001000100010111101100000110101001010010010000101111001000110
1100010011011110001011110001010000111010100111110100011011011100
0011001000001110011101101111101000010100001111010101011000101001
1101000101011110011010001101000101011001001000110011101101010110
0001010100110100111000010011101101111011011010010111101001011100
1101000010010111001110101100011001001000001111010100110111110010
1100000001111000100110111010111000111010010011111010011010100011
0110100000111100010100111000110111100110111011000110010111000101
0101011000100101011100001101111111001010111100001101111111110001
0011010010101101000010110001100001100110101000010010010011000110
1111100110000110101000111011001111100001100001111001010101101100
1011000010000001011111010000110100000111000001001100011100101010
1100101110000111101110110111011101011011100101101001001010111100
1001000000111100111101011110011001010100011000010100000101001000"""
    
    bits = bits.replace("\n", "").replace(" ", "")
    llrs = bits_to_signed_list(bits)
    llrs = llrs[1:]
    llrs = list(reversed(llrs))
    
    # input_rx = [0 if val >= 0 else 1 for val in llrs]
    # result = dec.soft_decode(input_rx)
    
    result = dec.soft_decode(llrs, p=2)
