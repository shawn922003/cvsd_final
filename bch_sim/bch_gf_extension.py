from typing import List, Dict, Tuple
from bch_table import ALPHA_POLY_BITS, BITS_TO_ALPHA_EXP, N

# -------------------------
# GF(2^6) 向量(bit-serial)版
# p(x) = x^6 + x + 1  →  x^6 ≡ x + 1
# 元素表示：LSB-first list [a0..a5]
# -------------------------
class GF2mVector:
    def __init__(self):
        self.m = 6
        # 溢出時 XOR 的約簡 taps：x^6 ≡ x + 1 → [1,1,0,0,0,0]
        self.reduction_taps = [1, 1, 0, 0, 0, 0]


    # ---------- 基本工具 ----------
    @staticmethod
    def check_len(a: List[int]): 
        '''
            檢查向量長度與元素型態
        '''
        assert isinstance(a, list) and len(a) == 6 and all((x & 1) == x for x in a)

    @staticmethod
    def clone(a: List[int]) -> List[int]: 
        return a.copy()

    @staticmethod
    def zero() -> List[int]: 
        return [0]*6

    @staticmethod
    def one() -> List[int]:
        v = [0]*6
        v[0] = 1
        return v


    # ---------- 加減 ----------
    @staticmethod
    def add(a: List[int], b: List[int]) -> List[int]:
        '''
            加法：GF(2^m) 中的加法即為逐位元 XOR
        '''
        GF2mVector.check_len(a)
        GF2mVector.check_len(b)
        return [(x ^ y) for x, y in zip(a, b)]
    
    @staticmethod
    def sub(a: List[int], b: List[int]) -> List[int]:
        '''
            減法：GF(2^m) 中的減法即為逐位元 XOR，與加法相同
        '''
        return GF2mVector.add(a, b)

    # ---------- 乘以 x (α) ----------
    # def mul_by_x(self, a: List[int]) -> List[int]:
    #     '''
    #         乘以 x：多項式左移一位，若有溢出則約簡
    #         約簡：把 x^6 拆成 x + 1，並加到結果上
    #     '''
    #     self.check_len(a)
    #     carry = a[5]
    #     b = [0]*6
    #     for i in range(5, 0, -1): 
    #         b[i] = a[i-1]
    #     b[0] = 0
    #     if carry:  # 約簡：XOR (x + 1)
    #         b = GF2mVector.add(b, self.reduction_taps)
    #     return b

    # # ---------- 乘法（bit-serial） ----------
    # def mul(self, a: List[int], b: List[int]) -> List[int]:
    #     self.check_len(a)
    #     self.check_len(b)
    #     res = [0]*6
    #     tmp = self.clone(a)
    #     for i in range(6):
    #         if b[i] & 1: 
    #             res = self.add(res, tmp)
    #         tmp = self.mul_by_x(tmp)
    #     return res

    # def square(self, a: List[int]) -> List[int]:
    #     return self.mul(a, a)

    # def pow(self, a: List[int], k: int) -> List[int]:
    #     if k == 0: 
    #         return self.one()
    #     base = self.clone(a)
    #     res = self.one()
    #     t = k
    #     while t > 0:
    #         if t & 1: 
    #             res = self.mul(res, base)
    #         base = self.square(base)
    #         t >>= 1
    #     return res

    # def inv(self, a: List[int]) -> List[int]:
    #     if self.is_zero(a): 
    #         raise ZeroDivisionError("inverse(0) undefined")
    #     return self.pow(a, (1 << self.m) - 2)  # a^{2^m-2}

    # def div(self, a: List[int], b: List[int]) -> List[int]:
    #     return self.mul(a, self.inv(b))
    
    # 用 table 完成乘法與除法
    def mul_by_x_table(self, a: List[int]) -> List[int]:
        alpha_pow = BITS_TO_ALPHA_EXP[tuple(a)]
        if alpha_pow == -1:
            return self.zero()
        next_pow = (alpha_pow + 1) % N
        return ALPHA_POLY_BITS[next_pow]
    
    def mul_table(self, a: List[int], b: List[int]) -> List[int]:
        GF2mVector.check_len(a)
        GF2mVector.check_len(b)
        a_pow = BITS_TO_ALPHA_EXP[tuple(a)]
        b_pow = BITS_TO_ALPHA_EXP[tuple(b)]
        if a_pow == -1 or b_pow == -1:
            return self.zero()
        res_pow = (a_pow + b_pow) % N
        return ALPHA_POLY_BITS[res_pow]
    
    def square_table(self, a: List[int]) -> List[int]:
        GF2mVector.check_len(a)
        a_pow = BITS_TO_ALPHA_EXP[tuple(a)]
        if a_pow == -1:
            return self.zero()
        res_pow = (2 * a_pow) % N
        return ALPHA_POLY_BITS[res_pow]
    
    def div_table(self, a: List[int], b: List[int]) -> List[int]:
        GF2mVector.check_len(a)
        GF2mVector.check_len(b)
        a_pow = BITS_TO_ALPHA_EXP[tuple(a)]
        b_pow = BITS_TO_ALPHA_EXP[tuple(b)]
        if a_pow == -1:
            return self.zero()
        if b_pow == -1:
            raise ZeroDivisionError("division by zero")
        res_pow = (a_pow - b_pow) % N
        return ALPHA_POLY_BITS[res_pow]

    # ---------- 判等 / 零 ----------
    @staticmethod
    def is_zero(a: List[int]) -> bool:
        GF2mVector.check_len(a)
        return not any(a)

    @staticmethod
    def eq(a: List[int], b: List[int]) -> bool:
        GF2mVector.check_len(a); GF2mVector.check_len(b)
        return all(x == y for x, y in zip(a, b))

    # ---------- 多項式評估（Chien 用） ----------
    def poly_eval(self, coeffs: List[List[int]], x: List[int]) -> List[int]:
        y = self.zero()
        for c in reversed(coeffs):
            y = self.mul(y, x)
            y = self.add(y, c)
        return y

    # ---------- 產生 α 表（若沒有全域表時用） ----------
    # def build_alpha_table(self) -> List[List[int]]:
    #     table: List[List[int]] = []
    #     cur = self.one()                  # alpha^0 = 1
    #     alpha = [0,1,0,0,0,0]             # x
    #     for _ in range(self.n):
    #         table.append(self.clone(cur)) # α^i
    #         cur = self.mul(cur, alpha)    # 下一個 α^{i+1}
    #     return table