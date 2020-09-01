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



# fig = plt.figure(1, figsize=(20,8))
# plt.plot(time, sin_values, 'ko')
# plt.plot(time, sin_values, 'k')
# plt.grid()
# plt.show()

# filter coefficient (from the difference equation)
b = [1, -1, 1, 1]    
a = [1, -0.5, -0.25]

NB_INPUT  = 8
NBF_INPUT = 7
NBI_INPUT = NB_INPUT - NBF_INPUT

A = 0.25
N = 200
fs = 1.0
test_frequency = {"fny": fs / 2, "fny_2": fs / 4}

const_input = DeFixedInt(NBI_INPUT-1, NBF_INPUT, A, roundMode='trunc')
print("Generating DC input")
with open("data/data_in_dc.txt", "w") as input_file:
    for _ in range(N):
        input_file.write("{}\n".format(const_input.value))

print("Using fs = {}".format(fs))
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
    expected_output = signal.lfilter(b=b, a=a, x=[value[1] for value in fixed_array])

    with open("data_out_{}_python.txt".format(f_str), "w") as input_file:
        for value in expected_output:
            input_file.write("{}\n".format(value))

