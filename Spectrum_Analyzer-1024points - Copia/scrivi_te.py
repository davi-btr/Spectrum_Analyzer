import cmath
import numpy as np

# Calculate the imaginary part of twiddle factors
n_values = [(63-n) for n in range(52)]


# Create a Quartus MIF file
with open('scrivi_te.txt', 'w') as f:
    
    # Write the address : data pairs
    for i in n_values:
        j = i - 9
        f.write(f'      6*d{i} : begin\n')
        f.write(f'          adapt_buff_data1_reg = °6*b0, vga_buff_q1_w[{i}:{j}];$\n')
        f.write(f'          adapt_buff_data2_reg = °6*b0, vga_buff_q2_w[{i}:{j}];$\n')
        f.write('       end\n\n')