
# best_model_state_dict.pt is saved by trained trained by mannix_fashion_mnist_ref1.ipynb
# https://colab.research.google.com/drive/19VL0b1lCRcvslFDKheGnGCCVr4BujiTy?usp=sharing

# this Python code can run locally on once following commands dump the model parameters from the pytourch run.
# torch.save(best_model.state_dict(), 'best_model_state_dict.pt') save parameters of best model
# Also NN_model should be the same as used in Colab for training


import torch
import NN_model
import numpy as np
import os


#--------------------------------------------------------------------------------

def dump_np_to_csv_multi2D(np_arr,path_prefix,format) :
  #Recursive functions to dump a numpy array with dimensions higher than 2 down to multiple 2D arrays
  
  if (len(np_arr.shape)<=2) :
    np.savetxt(path_prefix+'.csv',np_arr, fmt=format , delimiter=",")
  else : 
    for i in range(np_arr.shape[0]) :
        dump_np_to_csv_multi2D(np_arr[i],"%s_%d"%(path_prefix,i),format)
  

#--------------------------------------------------------------------------------

model = NN_model.My_NN(hidden_dim_1=120, hidden_dim_2=64, output_dim=10)
model.load_state_dict(torch.load('best_model_state_dict.pt'))

fc1_w = model.fc1.weight.data.detach().numpy()
fc1_b = model.fc1.bias.data.detach().numpy()

fc2_w = model.fc2.weight.data.detach().numpy()
fc2_b = model.fc2.bias.data.detach().numpy()

conv1_w = model.conv1.weight.data.detach().numpy()
conv1_b = model.conv1.bias.data.detach().numpy()

conv2_w = model.conv2.weight.data.detach().numpy()
conv2_b = model.conv2.bias.data.detach().numpy()


if not os.path.exists('csv_dumps'):
    os.makedirs('csv_dumps')
if not os.path.exists('csv_dumps/float_orig'):
    os.makedirs('csv_dumps/float_orig')


np.savetxt("csv_dumps/float_orig/fc1_w.csv" , fc1_w, delimiter=",")
np.savetxt("csv_dumps/float_orig/fc1_b.csv" , fc1_b, delimiter=",")
np.savetxt("csv_dumps/float_orig/fc2_w.csv" , fc2_w, delimiter=",")
np.savetxt("csv_dumps/float_orig/fc2_b.csv" , fc2_b, delimiter=",")

dump_np_to_csv_multi2D(conv1_w,"csv_dumps/float_orig/conv1_w",'%f')
dump_np_to_csv_multi2D(conv1_b,"csv_dumps/float_orig/conv1_b",'%f')
dump_np_to_csv_multi2D(conv2_w,"csv_dumps/float_orig/conv2_w",'%f')
dump_np_to_csv_multi2D(conv2_b,"csv_dumps/float_orig/conv2_b",'%f')


# Print Scaled

if not os.path.exists('csv_dumps/s caled_int2'):
    os.makedirs('csv_dumps/scaled_int2')

w_scale = 128
b_scale = 128*128

np.savetxt("csv_dumps/scaled_int2/fc1_w.csv" , (w_scale * fc1_w).astype(int), fmt='%i' , delimiter=",")
np.savetxt("csv_dumps/scaled_int2/fc1_b.csv" , (b_scale * fc1_b).astype(int), fmt='%i' , delimiter=",")
np.savetxt("csv_dumps/scaled_int2/fc2_w.csv" , (w_scale * fc2_w).astype(int), fmt='%i' , delimiter=",")
np.savetxt("csv_dumps/scaled_int2/fc2_b.csv" , (b_scale * fc2_b).astype(int), fmt='%i' , delimiter=",")

dump_np_to_csv_multi2D((w_scale * conv1_w).astype(int),"csv_dumps/scaled_int2/conv1_w",'%i')
dump_np_to_csv_multi2D((b_scale * conv1_b).astype(int),"csv_dumps/scaled_int2/conv1_b",'%i')
dump_np_to_csv_multi2D((w_scale * conv2_w).astype(int),"csv_dumps/scaled_int2/conv2_w",'%i')
dump_np_to_csv_multi2D((b_scale * conv2_b).astype(int),"csv_dumps/scaled_int2/conv2_b",'%i')



