import csv
import numpy as np
import matplotlib.pyplot as plt

N = 200
fs = 1.0
time = np.linspace(0, N*(1.0/fs), N, endpoint=False)

for f in ["fny", "fny_2"]:

    sim_output_file    = "data_out_{}.txt".format(f)
    python_output_file = "data_out_{}_python.txt".format(f)

    output_sim_fp = np.array([], dtype=np.int64)
    output_py_float = np.array([], dtype=float)

    with open(sim_output_file) as csvfile:
        reader = csv.reader(csvfile, delimiter=' ')
        for row in reader:
            output_sim_fp = np.append(output_sim_fp, np.array(row[0], dtype=np.int64))
    output_sim_float = (output_sim_fp / 2**7)

    with open(python_output_file) as py_file:
        for line in py_file:
            output_py_float = np.append(output_py_float, np.array(float(line), dtype=float))


    plt.figure(figsize=(20, 10))
    plt.plot(time, output_py_float, 'ko', label="Python")
    plt.plot(time, output_py_float, 'k')
    plt.plot(time[1:], output_sim_float,'r+', label="Simulation")
    plt.plot(time[1:], output_sim_float,'r')
    plt.title("Output for f = {}".format(f))
    plt.xlabel("Time")
    plt.ylabel("Amplitude")
    plt.legend()
    plt.grid()
    # plt.show()
    plt.savefig("output_comparison_{}.png".format(f))
