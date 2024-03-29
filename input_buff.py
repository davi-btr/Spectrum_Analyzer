import cmath
import numpy as np

# Calculate the imaginary part of twiddle factors
# twiddle_factors_imag = [cmath.exp(2j*cmath.pi*n/8).imag for n in range(1024)]
# twiddle_factors_imag = [(n%5) for n in range(1024)]
# twiddle_factors_imag = [(n <= 511) for n in range(1024)]
# twiddle_factors_imag = [n for n in range(1024)]
#twiddle_factors_imag = [cmath.exp(2j*cmath.pi*n/(8*(1 + (n >= 64) + (n >= 128) + (n >= 256)))).imag for n in range(1024)]
#twiddle_factors_imag = [(cmath.exp(2j*((n)/2)).imag)/(2*((n)/2)) if (n!=0) else 1 for n in range(1024)]
#twiddle_factors_imag = [(n == 0) for n in range(1024)]
twiddle_factors_imag = [(cmath.exp(2j*cmath.pi*((n)/3)).imag)/(2*cmath.pi*((n)/3)) if (n!=0) else 1 for n in range(1024)]
#twiddle_factors_imag = [1 for n in range(1024)]

# Convert to 32-bit signed decimal values
twiddle_factors_decimal = [int(x*(-2**31)) for x in twiddle_factors_imag]
# twiddle_factors_decimal = [int(x*(2**28)) for x in twiddle_factors_imag]
#twiddle_factors_decimal = [int(x*(2**21)) for x in twiddle_factors_imag]

# Create a Quartus MIF file
with open('input_buff.mif', 'w') as f:
    f.write('DEPTH = 1024;\n')  # The size of memory in words
    f.write('WIDTH = 32;\n')  # The size of data in bits
    f.write('ADDRESS_RADIX = DEC;\n')  # The radix for address values
    f.write('DATA_RADIX = DEC;\n')  # The radix for data values
    f.write('CONTENT\n')  # Start of (address : data pairs)
    f.write('BEGIN\n')
    
    # Write the address : data pairs
    for i, value in enumerate(twiddle_factors_decimal):
        f.write(f'{i} : {value};\n')
    
    f.write('END;\n')