import csv
import numpy as np
import matplotlib.pyplot as plt

def generate_sin_signal(A, N, fs, f=None):
    if f is None:
        f = 0.01    # normalized frequency to 1 Hz by default
    time = np.linspace(0, N*(1.0/fs), N, endpoint=False)
    sin_values = A * np.sin(2*np.pi * (f/fs) * time)

    return time, sin_values

[time, sin_values] = generate_sin_signal(A=0.25, N=199, fs=1.0, f=0.01)

output_simulation_file = "data_out.txt"
output_fp = np.array([],dtype = np.int64)
with open(output_simulation_file) as csvfile:
    reader = csv.reader(csvfile, delimiter=' ')
    for row in reader:
        output_fp = np.append(output_fp,np.array(row[0],dtype = np.int64))

output_float = (output_fp / 2**7)
plt.plot(time, sin_values, 'ko')
plt.plot(time, sin_values, 'k')
plt.plot(time[:len(time)-5], output_float[5:],'ro')
plt.plot(time[:len(time)-5], output_float[5:],'r')
plt.grid()
plt.show()
