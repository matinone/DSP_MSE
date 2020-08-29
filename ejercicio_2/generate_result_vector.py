import numpy as np
import sk_dsp_comm.fec_conv as fec


# https://stackoverflow.com/questions/10321978/integer-to-bitfield-as-a-list
def bitfield(n):
    return [int(digit) for digit in '{0:016b}'.format(n)] 


# convolutional encoder with POL_1 = 171 OCTAL, POL_2 = 133 OCTAL
cc1 = fec.fec_conv(('1111001','1011011'))
state = '0000000'
result = np.array([], dtype=np.uint8)

int_array = np.array([0x0005,0x1004,0xAFAA, 0x1234, 0x7852], dtype=np.uint64)
print("Inputs: {}".format(int_array))
for item in int_array:
    bit_array =  bitfield(item)
    bit_array = bit_array[::-1]
    y, state = cc1.conv_encoder(bit_array,state)
    y = np.packbits(y[::-1].astype(np.int64), bitorder='big')
    result = np.concatenate([result,y])

result = result.reshape(result.size//4,4).astype(dtype = np.int64)
for output in result:
    print_value = '0x' + hex(int.from_bytes(list(output),byteorder = 'big'))[2:].zfill(8)
    print(print_value)
