# 實作 (1023, 983) bch decoder
# p(x) = x^10 + x^3 + 1 is the primitive polynomial for GF(2^10)
# g(x) 為對應的生成多項式

from bch_table import ALPHA_POLY_BITS, BITS_TO_ALPHA_EXP, N, T, GENERATOR_POLY
from bch_gf_extension import GF2mVector
from typing import List, Tuple
from itertools import product
import random


random.seed(0)
def bits_to_hex_string(bits: List[int]) -> str:
    # conver to int 
    value = 0
    for i, bit in enumerate(bits):
        value |= (bit & 1) << i
    hex_length = (len(bits) + 3) // 4
    return f"{value:0{hex_length}X}"
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
        print(f"syndromes: S1={bits_to_hex_string(S1)} S2={bits_to_hex_string(self.gf.square_table(S1))} S3={bits_to_hex_string(S3)} S4={bits_to_hex_string(self.gf.square_table(self.gf.square_table(S1)))} S5={bits_to_hex_string(S5)} S6={bits_to_hex_string(self.gf.square_table(S3))} S7={bits_to_hex_string(S7)} S8={bits_to_hex_string(self.gf.square_table(self.gf.square_table(S1)))}")
        sigma1, sigma2, sigma3, sigma4, sigma_length = self.berlekamp(S1, S3, S5, S7)
        print(f"error locator poly: σ1={bits_to_hex_string(sigma1)} σ2={bits_to_hex_string(sigma2)} σ3={bits_to_hex_string(sigma3)} σ4={bits_to_hex_string(sigma4)} length={sigma_length}")
        roots = self.chien_search(sigma1, sigma2, sigma3, sigma4)
        print(f"Chien roots: {roots}")


       

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
            if pattern == (0,0):
                print(f"----------------pattern1: no flip-----------------")
            elif pattern == (1,0):
                print(f"----------------pattern2: flip index {sorted_indices[0]}-----------------")
            elif pattern == (0,1):
                print(f"----------------pattern3: flip index {sorted_indices[1]}-----------------")
            else:
                print(f"----------------pattern4: flip index {sorted_indices[0]}, {sorted_indices[1]}-----------------")
            


            # 依 pattern 覆寫/翻轉最不可靠的位
            for idx, bit in zip(sorted_indices, pattern):
                rx[idx] = bit   # 或 rx[idx] ^= bit，看你想怎麼定義 pattern

            # 硬解碼
            corrected, roots, success, _, _ = self.hard_decode(rx)
            
            print(f"decode success: {success}")

            if not success:
                # 解碼失敗的 candidate 丟掉，不算 correlation
                continue
            
            all_failed = False

            # 計算 correlation
            correlation = sum(r[i] * (1 - 2 * corrected[i]) for i in range(len(r)))
            print(f"correlation: {correlation}")
            extra_roots = [idx for idx, bit in zip(sorted_indices, pattern)
                        if input_rx[idx] != rx[idx]]

            set_roots = set(roots)
            set_extra = set(extra_roots)
                
            print(f"roots: {roots}")
            if correlation > best_correlation:
                best_correlation = correlation
                best_decoded = corrected
                # roots 要加上你在 pattern 裡面翻轉的那些 index
                

                # 只保留 roots 與 extra_roots 中「不在對方裡」的元素
                best_roots = sorted(set_roots ^ set_extra)   # 對稱差 (symmetric difference)
            elif correlation == best_correlation and best_roots != sorted(set_roots ^ set_extra):
                return None, None, True   # 多解，視為失敗
        
        print("=== Soft-decode result ===")
        print(f"best correlation: {best_correlation}")
        print(f"best roots: {best_roots}")
        return best_decoded, best_roots, all_failed


def mul(a, b):
    result = [0] * (len(a) + len(b) - 1)
    for i in range(len(a)):
        if a[i] == 1:
            for j in range(len(b)):
                if b[j] == 1:
                    result[i + j] ^= 1
                    
    return result[:N]  # 截斷為 N 位


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
    dec = BCH1023_983_Decoder()
    
    bits = """0000000001110100011010010110111110001111101011010101011100011110
0001000011101011001010111110110000101010010101111011110110101111
1001010111010111101011100011110111110011100111101110111111100110
0111000101000001111100010011010011001110110110000101100100111100
0011100101111011000010100010110110100101001001100010001101101011
0001001110101101100111000001101000100111011101110100101011011101
1011111100110000011101110000100110010111110110000011110110101110
1011011001001110000110001001111000110010011000110101000010100101
1011010000111001100000100010000100101110000101000100000001011011
1010011100101010001001101001001010100110110101110111101101101011
0010111100010010001101110001101001000001000010110011100110100110
1011111111110010101010000110101110010110110101000100100110101001
1001011000111110010000111010101001110011101100001001100110110110
1110000011100100100011011111100011010110111010110111001111000111
1001111000101000001000011011101010001000010001001101011101001001
1100010111101000010101011011100100101010011101111110001001100000
1111011111011110110011011101011110011110011000100111011010010000
1110101110100100000010111100000111010001110011111010100110011100
0111110100100000001100101100010001101011011111110001100010100110
0001011100100111001101011001011110011100011111000100010001000000
0001111010100001100011011100101100111110011101000011111111000100
0011011001010010111010110001001101001111011011100100000100011000
1110110011110111011011101011010110001011011000010011100110100101
1011101111011010001110100101100101100100111011000011110111110001
1010001001110011001011011010110011100011001011100010101110110101
0001011110110001010111010101111011001101111110000001101011111000
1110110111001101011010001100110101000001011101001101111100100111
1100100110001000101000111010111101000011110101111011001111100011
1011111100111011111101110001010111111000111010111100111001100100
1101111011010001010011010001011001001000100101011101001010000111
0001001111101011101100111010101011010100011001101111000100100111
1000001110001101000101101010000100011101110000001110001111100011
1011110111010111011110111000111010100000111000110100000010011110
0111001001010001000010110100111100111000000010101110100111101100
1101000100010010101010001001011000111000110111101101100001100100
0011100111011011010000111010011001010100101110001011000101110011
0011011111100001001111101010011101101111111101110101001111000011
1010101111011011001011001100110001001001001100000100010010101000
0111010110010111100110101011110101111000011001111001110101111011
0010100000110100001010100110101100011100000111110111100000100100
1000010101000011110011111010011000001010110010010100010001010111
1001010001100001001011001010001011011001111101100001010101000010
1001101110110110011100001000010100011111001000011001000011000111
1001111101010101001100101011001011100111000011001011101000111100
0111101010111101100100111000100001000000001101111111011111011111
0101000000100010000100001011101000011000101001001110110110011100
1011011010100000010111010100111011000101010101101101010111011110
0001001000111110111101100100110110111011011000110110011111001101
1001101010000011000010000010000110101010110100111000111010010111
1000101010000111011010101001001011000011101111111001111001001001
1001111111010100111100001111010000010011110011000011100010100110
1100010000111000011011001010011010011111011010011010011110010110
0010010100101100010001100011101110110010111110001010100000111111
0101100111010100101000100100011000011011001110110101111010001111
1100000101111101110001100110001101111101100001100110101010001110
0101001101100100010101000010111001000100010011101100100111010010
1100001101110000100001001010111001011010100101101110001111001100
0000110000111110010000000100000000101111000100001010000111011011
0011001000100101001110001111010110101001110011011110010111100001
0111000101111010101110011000100011110000011010110001010000011110
0101010111110100001001011010010100011110000010011010010110110110
0111110010000011101000100011111101011110001111111110001000101101
1100011011000000110100011011010000001100111001001011101111100100
1000011010000110000101011010010000010110010001001001000001100101
0010110010011011100100100010111111010010110001100000110001010011
0111000000101010110011101001011101000011000100000000111110010111
0101101101100011100011101101001111011100100000011000000110111110
0101100111010001101100100111111011011110110010000111100000010000
1100001000001101111100110110110110000010111011011100100111111000
1101001111010001111100010000100000001100101010011111001111100101
1000100110101100100010011110001110111100101001010001001010101110
1110011111110110100110010100111100011001100100110001010100010001
0110001011110000010101010110101101011100111010101101111101110001
0001010010000001010001100011111111101110111010101011110001100011
1000101001000001101110000110010101111001111000111011001100010101
1110011101110101110010011001101110001100110000101011011100011000
0001001001011000101110001111010010011011011110000100111011011001
1111101100010100100110111001001111001000011110101100100110110101
1000001111001111101100011001111101010001010011010011101001111100
1101000111011010101100000110000011101101111001010101010111000101
1000110010010101001101100110011000101100001101010100100000110111
1111011000001001000010001110011011011000100110100101111101100000
0010001010100101011110111110011100011111000101101000111010111010
1001101010111011010111011110100000101011001010010111000000011001
0111011100001101111000101000001101011100001101001001000001100111
0011000111011111101010000001010001001000011011011011100100011010
0101100000101000110011110010000000000111010110010001011001010111
0101110101100000110110010011010101101110001110110110101000010101
0010101101101011100000101100011101001111001101010000110001011001
0011001000100101001110101111010001101000110000111011010000101010
0110101101101110000111000111110100101001111100110110011100101010
0110010000010010001100101010010100111101111110001001010101011110
1101011011011011101001011000000101110000011101100110101110011110
1110001000101000001101110111111010001111101101011010011111101010
0001110101000111001000011000100101010000010101101010110100010001
1100010011010100100100001010000010100010000011010010100100001000
1111010110010010010101011110010011001110000111101000011111000101
1101101101010010101100100111000011011111100000111111010010100110
1011001101101000011101011000011000100000101111101000100001001101
1010010001000001101011010101011100110010100011111100110011001010
1110101001101010100100111111011000111101001101101110000101000101
0111011101111011001001010110010010100001100110111000101001011001
0110111101111011100110011001110001111001010110001000010110000011
1100011110010111101011001111011101011101011101111000000100100000
1010101010011001010001110011110001101000110001100001110011100101
1010001011000010110010000100000001110001011001100110010010100110
0110011111011101110110000001000010011111100000010001110001111100
0101000011111000110100100111110001100111000111110001010011100101
1101100011100010110001100010100001001010100001010101101000111101
0011000101001100011001010011111010111010101111011110100111011000
0101010111010000110110001101100001100100001011001100100001010101
0100100111110110010001111000000110100110010010011011100000100001
1100001011010110011001011010010110010111110001001001110000001100
0000101000111101010011110001001010010010001010110110001110010001
0000101111110101101110011010001010010001001110011011010000110100
1011001001000100101101010100000010110001100110010110010101100010
0111101110111100010100100001111110010001010100110110100011110101
0101010111001011001000101101000111000001000100001101110011101100
1110001101101100101010111011111010101000000110000111111110111001
1101000001110100110000001000101010100000000110111011101001101100
1000110000101000101110101100110110011110101101010110010001101110
1101110001101011111100111100101001111110101101110010100111000110
1001000001001100010110111000011001010100000101000010111101111010
1110100001001000111001111110011011110000100000011100110111100000
1111001111110101010001101011110000010001101011111011010100001110
1110011101011000101111011011000011100111010100001101011111101110
1101001011001011100000110001100010001000101111011000010011001001
1111001111001110111010111000100011101100101010010101111000010110"""
    
    bits = bits.replace("\n", "").replace(" ", "")
    llrs = bits_to_signed_list(bits)
    llrs = llrs[1:]
    llrs = list(reversed(llrs))
    
    input_rx = [0 if val >= 0 else 1 for val in llrs]
    # _,hard_result,_,_,_ = dec.soft_decode(input_rx)
    
    _,soft_result, all_failed = dec.soft_decode(llrs, p=2)
    
    # tx = [0]*400 + [1]*583  # 983 bit 傳輸
    
    # # 編碼
    # rx = mul(tx, GENERATOR_POLY)
    
    # hard_codeword = rx[:]
    # error0 = 100
    # error1 = 500
    # hard_codeword[error0] ^= 1
    # hard_codeword[error1] ^= 1
    # corrected, roots, _, _, _  = dec.hard_decode(hard_codeword)
    # print(f"硬判決：是否修正回原碼字？ {corrected == rx}")
    # print(f"硬判決：Chien 找到 roots = {roots}") 
    
    
    
    # soft_decode_llr = []
    # # 模擬信道不確定性：降低某些位置的可靠性
    # errors = [100, 200, 500, 800]
    # for idx in range(N):
    #     soft_decode_llr.append((1-2 *rx[idx]) * 127)

    # soft_decode_llr[errors[0]] = soft_decode_llr[errors[0]] / 5
    # soft_decode_llr[errors[1]] = soft_decode_llr[errors[1]] / 10
    # soft_decode_llr[errors[2]] = soft_decode_llr[errors[2]] / 15
    # soft_decode_llr[errors[3]] = soft_decode_llr[errors[3]] / 20

    # p = 4  # 測試 4 個最不可靠的位
    # soft_corrected, roots = dec.soft_decode(soft_decode_llr, p=p)

    # # 驗證與顯示
    # print(f"軟判決：是否修正回原碼字？ {soft_corrected == rx}")
    # print(f"軟判決：找到錯誤位置 = {roots}")