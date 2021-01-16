

Input Files:

best_model_state_dict.pt (binary file)
This file is saved by trained trained by mannix_fashion_mnist_ref1.ipynb
# https://colab.research.google.com/drive/19VL0b1lCRcvslFDKheGnGCCVr4BujiTy?usp=sharing
by this command already used in the train run: 
torch.save(best_model.state_dict(), 'best_model_state_dict.pt') save parameters of best model

NN_model.py
Do not modify, imported as is into parse_model_state_dict.py
This is the the original NN model used in above pyTourch training environment.  
NN_model should and is the same as used in Colab for training

Parse utility:
parse_model_state_dict.py
this Python code parses the model parameters already dumped into best_model_state_dict.pt from the pytourch run.
and generates csv both for the original float params at local csv_dumps\float_orig
and the corresponding scaled integer params into local csv_dumps\float_orig\scaled_int

run:

python parse_model_state_dict.py
