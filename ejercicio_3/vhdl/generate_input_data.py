from fxpoint._fixedInt import DeFixedInt
from fxpoint._fixedInt import arrayFixedInt

import matplotlib.pyplot as plt
from scipy import signal
import numpy as np

def generate_sin_signal(A, N, fs, f=None):
    if f is None:
        f = 0.01    # normalized frequency to 1 Hz by default
    time = np.linspace(0, N*(1.0/fs), N, endpoint=False)
    sin_values = A * np.sin(2*np.pi * (f/fs) * time)

    return time, sin_values

[time, sin_values] = generate_sin_signal(A=0.25, N=200, fs=1.0, f=0.01)

# fig = plt.figure(1, figsize=(20,8))
# plt.plot(time, sin_values, 'ko')
# plt.plot(time, sin_values, 'k')
# plt.grid()
# plt.show()

NB_INPUT  = 8
NBF_INPUT = 7
NBI_INPUT = NB_INPUT - NBF_INPUT

# generate DC (constant value with Q1.7)
const_input = DeFixedInt(NBI_INPUT-1, NBF_INPUT, 0.25, roundMode='trunc')
print(const_input)

# generate tuple with int and float values
sin_fixed_array = [(DeFixedInt(NBI_INPUT-1, NBF_INPUT, value, roundMode='trunc').value,DeFixedInt(NBI_INPUT-1, NBF_INPUT, value, roundMode='trunc').fValue) for value in sin_values]

# generate file for the testbench
constant_input_f = open("data_in_const.txt", "w")
sin_input_f      = open("data_in_sin.txt", "w")
for value in sin_fixed_array:
    constant_input_f.write("{}\n".format(const_input.value))
    sin_input_f.write("{}\n".format(value[0]))
constant_input_f.close()
sin_input_f.close()
