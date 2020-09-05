import csv
import numpy as np
import matplotlib.pyplot as plt

N = 200
fs = 1.0
time = np.linspace(0, N*(1.0/fs), N, endpoint=False)

# symmetric = ""
symmetric = "_symmetric"
freq_array = ["fny_0p1", "fny_0p8"]
for f in freq_array:

    # sim_input_file     = "data/data_in_{}.txt".format(f)
    sim_output_file    = "data/data_out_{}{}.txt".format(f, symmetric)
    python_output_file = "data/data_out_{}_python.txt".format(f)

    input_sim_fp = np.array([], dtype=np.int64)
    output_sim_fp = np.array([], dtype=np.int64)
    output_py_float = np.array([], dtype=float)

    # with open(sim_input_file) as csvfile:
    #     reader = csv.reader(csvfile, delimiter=' ')
    #     for row in reader:
    #         input_sim_fp = np.append(input_sim_fp, np.array(row[0], dtype=np.int64))
    # input_sim_float = (input_sim_fp / 2**15)

    with open(sim_output_file) as csvfile:
        reader = csv.reader(csvfile, delimiter=' ')
        for row in reader:
            output_sim_fp = np.append(output_sim_fp, np.array(row[0], dtype=np.int64))
    output_sim_float = (output_sim_fp / 2**16)

    with open(python_output_file) as py_file:
        for line in py_file:
            output_py_float = np.append(output_py_float, np.array(float(line), dtype=float))


    plt.figure(figsize=(20, 10))
    plt.plot(time, output_py_float, 'ko', label="Python")
    plt.plot(time, output_py_float, 'k')
    plt.plot(time[1:], output_sim_float,'r+', label="Simulation")
    plt.plot(time[1:], output_sim_float,'r')
    # plt.plot(time, input_sim_float, 'b*', label="Input")
    # plt.plot(time, input_sim_float, 'b')
    plt.title("Output for f = {} {}".format(f, symmetric.replace("_", "")))
    plt.xlabel("Time")
    plt.ylabel("Amplitude")
    plt.legend()
    plt.grid()
    # plt.show()
    plt.savefig("images/output_comparison_{}{}.png".format(f, symmetric))
