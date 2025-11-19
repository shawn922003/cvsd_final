#!/usr/bin/env python3
"""
Syndrome Calculator Golden Pattern Generator
Generates expected syndrome values for BCH codes
"""

import numpy as np

class GaloisField:
    """Galois Field arithmetic for BCH codes"""
    
    def __init__(self, m):
        """
        Initialize Galois Field GF(2^m)
        m: field size exponent (6 for GF(64), 8 for GF(256), 10 for GF(1024))
        """
        self.m = m
        self.field_size = 2**m
        
        # Primitive polynomials (without the leading 1 bit)
        if m == 6:
            self.prim_poly = 0b000011  # x^6 + x + 1 (from BCH tables: p(x) = x^6 + x + 1)
        elif m == 8:
            self.prim_poly = 0b00011101  # x^8 + x^4 + x^3 + x^2 + 1
        elif m == 10:
            self.prim_poly = 0b0000001001  # x^10 + x^3 + 1
        else:
            raise ValueError(f"Unsupported field size m={m}")
        
        # Generate alpha power table
        self.alpha_to_int = [0] * self.field_size
        self.int_to_alpha = [0] * self.field_size
        
        self._generate_tables()
    
    def _generate_tables(self):
        """Generate alpha power and inverse lookup tables"""
        # Initialize int_to_alpha with -1 (indicating not set)
        self.int_to_alpha = [-1] * self.field_size
        
        alpha = 1
        for i in range(self.field_size - 1):
            self.alpha_to_int[i] = alpha
            if alpha < self.field_size:
                self.int_to_alpha[alpha] = i
            
            # Multiply by alpha (shift left)
            alpha = alpha << 1
            
            # If overflow, XOR with primitive polynomial  
            if alpha >= (1 << self.m):
                alpha ^= ((1 << self.m) | self.prim_poly)
        
        # Verify cyclical property: alpha^(field_size-1) should equal alpha^0 = 1
        if self.alpha_to_int[self.field_size - 2] != 1:
            print(f"Warning: Cyclical property check - alpha^{self.field_size-2} = {self.alpha_to_int[self.field_size-2]:x}, expected 1")
        
        # Set alpha^(field_size-1) = alpha^0 = 1
        self.alpha_to_int[self.field_size - 1] = 1
    
    def multiply(self, a, b):
        """Multiply two field elements"""
        if a == 0 or b == 0:
            return 0
        
        # Get alpha powers
        alpha_a = self.int_to_alpha[a]
        alpha_b = self.int_to_alpha[b]
        
        # Add powers (modulo field_size - 1)
        alpha_result = (alpha_a + alpha_b) % (self.field_size - 1)
        
        return self.alpha_to_int[alpha_result]
    
    def power(self, a, n):
        """Compute a^n in the field"""
        if a == 0:
            return 0
        if n == 0:
            return 1
        
        # Get alpha power
        alpha_a = self.int_to_alpha[a]
        
        # Multiply power by n
        alpha_result = (alpha_a * n) % (self.field_size - 1)
        
        return self.alpha_to_int[alpha_result]


class SyndromeCalculator:
    """Calculate syndrome values for BCH codes"""
    
    def __init__(self, code_type):
        """
        Initialize syndrome calculator
        code_type: '63,51', '255,239', or '1023,983'
        """
        self.code_type = code_type
        
        if code_type == '63,51':
            self.n = 63
            self.k = 51
            self.m = 6
            self.num_syndromes = 4  # S1, S2, S3, S4
        elif code_type == '255,239':
            self.n = 255
            self.k = 239
            self.m = 8
            self.num_syndromes = 4
        elif code_type == '1023,983':
            self.n = 1023
            self.k = 983
            self.m = 10
            self.num_syndromes = 8  # S1-S8
        else:
            raise ValueError(f"Unsupported code type: {code_type}")
        
        self.gf = GaloisField(self.m)
        self.alpha = 2  # Generator element alpha = x in GF(2^m)
    
    def calculate_syndrome(self, codeword_bits, syndrome_idx):
        """
        Calculate a single syndrome S_i
        codeword_bits: list of bits from MSB to LSB
        syndrome_idx: which syndrome to calculate (1, 3, 5, 7, etc.)
        """
        syndrome = 0
        
        # S_i = sum(c_j * alpha^(i*j)) for j from 0 to n-1
        for j, bit in enumerate(codeword_bits):
            if bit == 1:
                # Power of alpha for this position
                # j goes from 0 (MSB) to n-1 (LSB)
                # We want alpha^(i*(n-1-j)) for MSB-first ordering
                power = (syndrome_idx * (len(codeword_bits) - 1 - j)) % (self.gf.field_size - 1)
                alpha_power = self.gf.alpha_to_int[power]
                syndrome ^= alpha_power
        
        return syndrome
    
    def calculate_all_syndromes(self, data_bytes):
        """
        Calculate all syndromes for the given data
        data_bytes: bytes object or int representing the codeword
        Returns: dict with S1, S2, S3, S4, (S5, S6, S7, S8 for 1023,983)
        """
        # Convert to bit array (MSB first)
        if isinstance(data_bytes, int):
            # Convert int to bits
            num_bytes = (self.n + 7) // 8
            data_bytes = data_bytes.to_bytes(num_bytes, 'big')
        
        # Extract bits (MSB first)
        bits = []
        for byte in data_bytes[:self.n//8]:
            for i in range(7, -1, -1):
                bits.append((byte >> i) & 1)
        
        # Pad or truncate to n bits
        while len(bits) < self.n:
            bits.append(0)
        bits = bits[:self.n]
        
        # Calculate syndromes
        syndromes = {}
        
        # S1 = evaluation at alpha^1
        syndromes['S1'] = self.calculate_syndrome(bits, 1)
        
        # S2 = S1^2
        syndromes['S2'] = self.gf.power(syndromes['S1'], 2)
        
        # S3 = evaluation at alpha^3
        syndromes['S3'] = self.calculate_syndrome(bits, 3)
        
        # S4 = S2^2 = S1^4
        syndromes['S4'] = self.gf.power(syndromes['S2'], 2)
        
        if self.code_type == '1023,983':
            # S5 = evaluation at alpha^5
            syndromes['S5'] = self.calculate_syndrome(bits, 5)
            
            # S6 = S3^2
            syndromes['S6'] = self.gf.power(syndromes['S3'], 2)
            
            # S7 = evaluation at alpha^7
            syndromes['S7'] = self.calculate_syndrome(bits, 7)
            
            # S8 = S4^2 = S1^8
            syndromes['S8'] = self.gf.power(syndromes['S4'], 2)
        
        return syndromes


def format_syndrome(value, width=10):
    """Format syndrome value for Verilog"""
    return f"{width}'h{value:0{(width+3)//4}x}"


def generate_test_patterns():
    """Generate test patterns and golden values"""
    
    patterns = []
    
    # BCH(63,51) patterns
    print("\n" + "="*60)
    print("BCH(63,51) Test Patterns")
    print("="*60)
    
    calc_63 = SyndromeCalculator('63,51')
    
    # Pattern 0: All zeros
    data = 0x0000000000000000
    syn = calc_63.calculate_all_syndromes(data)
    patterns.append(('2\'b00', data, syn))
    print(f"\nPattern 0: All zeros")
    print(f"  Data: 0x{data:016x}")
    print(f"  S1={format_syndrome(syn['S1'])}, S2={format_syndrome(syn['S2'])}")
    print(f"  S3={format_syndrome(syn['S3'])}, S4={format_syndrome(syn['S4'])}")
    
    # Pattern 1: All ones (in 63 bits)
    data = 0x7FFFFFFFFFFFFFFF  # 63 bits of 1
    syn = calc_63.calculate_all_syndromes(data)
    patterns.append(('2\'b00', data, syn))
    print(f"\nPattern 1: All ones")
    print(f"  Data: 0x{data:016x}")
    print(f"  S1={format_syndrome(syn['S1'])}, S2={format_syndrome(syn['S2'])}")
    print(f"  S3={format_syndrome(syn['S3'])}, S4={format_syndrome(syn['S4'])}")
    
    # Pattern 2: Single bit error at MSB
    data = 0x8000000000000000
    syn = calc_63.calculate_all_syndromes(data)
    patterns.append(('2\'b00', data, syn))
    print(f"\nPattern 2: Single bit at MSB")
    print(f"  Data: 0x{data:016x}")
    print(f"  S1={format_syndrome(syn['S1'])}, S2={format_syndrome(syn['S2'])}")
    print(f"  S3={format_syndrome(syn['S3'])}, S4={format_syndrome(syn['S4'])}")
    
    # BCH(255,239) patterns
    print("\n" + "="*60)
    print("BCH(255,239) Test Patterns")
    print("="*60)
    
    calc_255 = SyndromeCalculator('255,239')
    
    # Pattern 3: All zeros
    data = 0x0000000000000000
    syn = calc_255.calculate_all_syndromes(data)
    patterns.append(('2\'b01', data, syn))
    print(f"\nPattern 3: All zeros")
    print(f"  Data: 0x{data:016x}")
    print(f"  S1={format_syndrome(syn['S1'])}, S2={format_syndrome(syn['S2'])}")
    print(f"  S3={format_syndrome(syn['S3'])}, S4={format_syndrome(syn['S4'])}")
    
    # Pattern 4: Alternating pattern
    data = 0xAAAAAAAAAAAAAAAA
    syn = calc_255.calculate_all_syndromes(data)
    patterns.append(('2\'b01', data, syn))
    print(f"\nPattern 4: Alternating")
    print(f"  Data: 0x{data:016x}")
    print(f"  S1={format_syndrome(syn['S1'])}, S2={format_syndrome(syn['S2'])}")
    print(f"  S3={format_syndrome(syn['S3'])}, S4={format_syndrome(syn['S4'])}")
    
    # Pattern 5: Single bit
    data = 0x8000000000000000
    syn = calc_255.calculate_all_syndromes(data)
    patterns.append(('2\'b01', data, syn))
    print(f"\nPattern 5: Single bit at MSB")
    print(f"  Data: 0x{data:016x}")
    print(f"  S1={format_syndrome(syn['S1'])}, S2={format_syndrome(syn['S2'])}")
    print(f"  S3={format_syndrome(syn['S3'])}, S4={format_syndrome(syn['S4'])}")
    
    # BCH(1023,983) patterns
    print("\n" + "="*60)
    print("BCH(1023,983) Test Patterns")
    print("="*60)
    
    calc_1023 = SyndromeCalculator('1023,983')
    
    # Pattern 6: All zeros
    data = 0x0000000000000000
    syn = calc_1023.calculate_all_syndromes(data)
    patterns.append(('2\'b10', data, syn))
    print(f"\nPattern 6: All zeros")
    print(f"  Data: 0x{data:016x}")
    print(f"  S1={format_syndrome(syn['S1'])}, S2={format_syndrome(syn['S2'])}")
    print(f"  S3={format_syndrome(syn['S3'])}, S4={format_syndrome(syn['S4'])}")
    print(f"  S5={format_syndrome(syn['S5'])}, S6={format_syndrome(syn['S6'])}")
    print(f"  S7={format_syndrome(syn['S7'])}, S8={format_syndrome(syn['S8'])}")
    
    # Pattern 7: Alternating
    data = 0x5555555555555555
    syn = calc_1023.calculate_all_syndromes(data)
    patterns.append(('2\'b10', data, syn))
    print(f"\nPattern 7: Alternating")
    print(f"  Data: 0x{data:016x}")
    print(f"  S1={format_syndrome(syn['S1'])}, S2={format_syndrome(syn['S2'])}")
    print(f"  S3={format_syndrome(syn['S3'])}, S4={format_syndrome(syn['S4'])}")
    print(f"  S5={format_syndrome(syn['S5'])}, S6={format_syndrome(syn['S6'])}")
    print(f"  S7={format_syndrome(syn['S7'])}, S8={format_syndrome(syn['S8'])}")
    
    # Pattern 8: Single bit
    data = 0x8000000000000000
    syn = calc_1023.calculate_all_syndromes(data)
    patterns.append(('2\'b10', data, syn))
    print(f"\nPattern 8: Single bit at MSB")
    print(f"  Data: 0x{data:016x}")
    print(f"  S1={format_syndrome(syn['S1'])}, S2={format_syndrome(syn['S2'])}")
    print(f"  S3={format_syndrome(syn['S3'])}, S4={format_syndrome(syn['S4'])}")
    print(f"  S5={format_syndrome(syn['S5'])}, S6={format_syndrome(syn['S6'])}")
    print(f"  S7={format_syndrome(syn['S7'])}, S8={format_syndrome(syn['S8'])}")
    
    # Pattern 9: Random
    data = 0x123456789ABCDEF0
    syn = calc_1023.calculate_all_syndromes(data)
    patterns.append(('2\'b10', data, syn))
    print(f"\nPattern 9: Random pattern")
    print(f"  Data: 0x{data:016x}")
    print(f"  S1={format_syndrome(syn['S1'])}, S2={format_syndrome(syn['S2'])}")
    print(f"  S3={format_syndrome(syn['S3'])}, S4={format_syndrome(syn['S4'])}")
    print(f"  S5={format_syndrome(syn['S5'])}, S6={format_syndrome(syn['S6'])}")
    print(f"  S7={format_syndrome(syn['S7'])}, S8={format_syndrome(syn['S8'])}")
    
    return patterns


def generate_verilog_pattern_code(patterns):
    """Generate Verilog code for pattern initialization"""
    
    print("\n" + "="*60)
    print("Verilog Pattern Initialization Code")
    print("="*60)
    print("\n// Copy this code into load_test_patterns task:\n")
    
    for i, (code, data, syn) in enumerate(patterns):
        print(f"        // Pattern {i}")
        print(f"        test_code[{i}] = {code};")
        print(f"        test_data[{i}] = 64'h{data:016x};")
        print(f"        golden_S1[{i}] = {format_syndrome(syn['S1'])};")
        print(f"        golden_S2[{i}] = {format_syndrome(syn['S2'])};")
        print(f"        golden_S3[{i}] = {format_syndrome(syn['S3'])};")
        print(f"        golden_S4[{i}] = {format_syndrome(syn['S4'])};")
        
        if 'S5' in syn:
            print(f"        golden_S5[{i}] = {format_syndrome(syn['S5'])};")
            print(f"        golden_S6[{i}] = {format_syndrome(syn['S6'])};")
            print(f"        golden_S7[{i}] = {format_syndrome(syn['S7'])};")
            print(f"        golden_S8[{i}] = {format_syndrome(syn['S8'])};")
        print()


def generate_pattern_files(patterns, output_dir="."):
    """Generate pattern files for testbench to read"""
    import os
    
    # Create output directory if not exists
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # Generate test_code.dat
    with open(os.path.join(output_dir, "test_code.dat"), "w") as f:
        for code, _, _ in patterns:
            f.write(f"{code}\n")
    
    # Generate test_data.dat  
    with open(os.path.join(output_dir, "test_data.dat"), "w") as f:
        for _, data, _ in patterns:
            f.write(f"{data:016x}\n")
    
    # Generate golden syndrome files
    with open(os.path.join(output_dir, "golden_S1.dat"), "w") as f:
        for _, _, syn in patterns:
            f.write(f"{syn['S1']:03x}\n")
    
    with open(os.path.join(output_dir, "golden_S2.dat"), "w") as f:
        for _, _, syn in patterns:
            f.write(f"{syn['S2']:03x}\n")
    
    with open(os.path.join(output_dir, "golden_S3.dat"), "w") as f:
        for _, _, syn in patterns:
            f.write(f"{syn['S3']:03x}\n")
    
    with open(os.path.join(output_dir, "golden_S4.dat"), "w") as f:
        for _, _, syn in patterns:
            f.write(f"{syn['S4']:03x}\n")
    
    # S5-S8 files (may have invalid data for BCH(63,51) and BCH(255,239))
    with open(os.path.join(output_dir, "golden_S5.dat"), "w") as f:
        for _, _, syn in patterns:
            if 'S5' in syn:
                f.write(f"{syn['S5']:03x}\n")
            else:
                f.write(f"000\n")
    
    with open(os.path.join(output_dir, "golden_S6.dat"), "w") as f:
        for _, _, syn in patterns:
            if 'S6' in syn:
                f.write(f"{syn['S6']:03x}\n")
            else:
                f.write(f"000\n")
    
    with open(os.path.join(output_dir, "golden_S7.dat"), "w") as f:
        for _, _, syn in patterns:
            if 'S7' in syn:
                f.write(f"{syn['S7']:03x}\n")
            else:
                f.write(f"000\n")
    
    with open(os.path.join(output_dir, "golden_S8.dat"), "w") as f:
        for _, _, syn in patterns:
            if 'S8' in syn:
                f.write(f"{syn['S8']:03x}\n")
            else:
                f.write(f"000\n")
    
    print(f"\n✓ Pattern files generated in '{output_dir}/' directory:")
    print(f"  - test_code.dat")
    print(f"  - test_data.dat")
    print(f"  - golden_S1.dat ~ golden_S8.dat")
    print(f"\nTotal: 10 patterns")


if __name__ == "__main__":
    import sys
    
    print("Syndrome Calculator Golden Pattern Generator")
    print("="*60)
    
    patterns = generate_test_patterns()
    generate_verilog_pattern_code(patterns)
    
    # Generate pattern files
    output_dir = sys.argv[1] if len(sys.argv) > 1 else "./pattern"
    generate_pattern_files(patterns, output_dir)
    
    print("\n" + "="*60)
    print("Pattern generation complete!")
    print("="*60)
