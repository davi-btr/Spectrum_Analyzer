import cmath
import numpy as np

# Calculate the imaginary part of twiddle factors
twiddle_factors_imag = [cmath.exp(2j*cmath.pi*n/1024).imag for n in range(512)]

# Convert to 32-bit signed decimal values
twiddle_factors_decimal = [int(x*(-2**31)) for x in twiddle_factors_imag]

# Create a Quartus MIF file
with open('twiddle_factors_imag.mif', 'w') as f:
    f.write('DEPTH = 512;\n')  # The size of memory in words
    f.write('WIDTH = 32;\n')  # The size of data in bits
    f.write('ADDRESS_RADIX = DEC;\n')  # The radix for address values
    f.write('DATA_RADIX = DEC;\n')  # The radix for data values
    f.write('CONTENT\n')  # Start of (address : data pairs)
    f.write('BEGIN\n')
    
    # Write the address : data pairs
    for i, value in enumerate(twiddle_factors_decimal):
        f.write(f'{i} : {value};\n')
    
    f.write('END;\n')