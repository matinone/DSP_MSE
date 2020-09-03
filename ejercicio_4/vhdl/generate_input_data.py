from fxpoint._fixedInt import DeFixedInt
from fxpoint._fixedInt import arrayFixedInt

import matplotlib.pyplot as plt
from scipy import signal
import numpy as np

def generate_sin_signal(A, N, fs, f=None, phase=np.pi/2):
    if f is None:
        f = 0.01    # normalized frequency to 1 Hz by default
    time = np.linspace(0, N*(1.0/fs), N, endpoint=False)
    sin_values = A * np.sin(2*np.pi * (f/fs) * time + phase)

    return time, sin_values

# Q1.15
NB_INPUT  = 16
NBF_INPUT = 15
NBI_INPUT = NB_INPUT - NBF_INPUT

# filter coefficients
filter_data = np.load('../analisis_sistema_lineal/filter_coef.npz')
b = filter_data['ba'][0]
a = filter_data['ba'][1]
a = [coef if coef <= 0.999969 else 0.999969 for coef in a]

# fixed point coefficients
b_fp_int = [(DeFixedInt(NBI_INPUT-1, NBF_INPUT, coef, roundMode='trunc')).value for coef in b]      # for RTL design
b_fp_float = [(DeFixedInt(NBI_INPUT-1, NBF_INPUT, coef, roundMode='trunc')).fValue for coef in b]   # for lfilter function
a_fp_int = [(DeFixedInt(NBI_INPUT-1, NBF_INPUT, coef, roundMode='trunc')).value for coef in a]      # for RTL design
a_fp_float = [(DeFixedInt(NBI_INPUT-1, NBF_INPUT, coef, roundMode='trunc')).fValue for coef in a]   # for lfilter function

print("Filter coefficient - float")
print("b = {}\na = {}".format(b, a))
print("\nFilter coefficient - fixed point representation")
print("b = {}\na = {}".format(b_fp_float, a_fp_float))
print("\nFilter coefficient - fixed point integer value")
print("b = {}\na = {}".format(b_fp_int, a_fp_int))

A = 0.25
N = 200
fs = 1.0
test_frequency = {"fny_0p1": 0.1 * fs / 2, "fny_0p8": 0.8 * fs / 2}

print("\nUsing fs = {}".format(fs))
for f_str in test_frequency.keys():
    print("Generating input for {} (f = {})".format(f_str, test_frequency[f_str]))
    [time, input_values] = generate_sin_signal(A=0.25, N=N, fs=fs, f=test_frequency[f_str])

    # generate tuple with int and float values
    fixed_array = [(DeFixedInt(NBI_INPUT-1, NBF_INPUT, value, roundMode='trunc').value,
                    DeFixedInt(NBI_INPUT-1, NBF_INPUT, value, roundMode='trunc').fValue) for value in input_values]

    # generate file for the testbench
    with open("data/data_in_{}.txt".format(f_str), "w") as input_file:
        for value in fixed_array:
            input_file.write("{}\n".format(value[0]))

    # generate expected output data
    expected_output = signal.lfilter(b=b_fp_float, a=a_fp_float, x=[value[1] for value in fixed_array])

    fig = plt.figure(1, figsize=(20,8))
    plt.plot(time, expected_output, 'ko')
    plt.plot(time, expected_output, 'k')
    plt.grid()
    plt.show()

    with open("data/data_out_{}_python.txt".format(f_str), "w") as input_file:
        for value in expected_output:
            input_file.write("{}\n".format(value))

