import tensorflow as tf
import argparse

# Create the parser
my_parser = argparse.ArgumentParser(description='List the content of a folder')
# Add the arguments
my_parser.add_argument('-p',
                       '--path',
                       action='store',
                       type=str,
                       default="example.tflite",
                       help='path to app dir')

# Execute parse_args()
args = my_parser.parse_args()

# Load TFLite model and allocate tensors.
interpreter = tf.lite.Interpreter(model_path=args.path)
interpreter.allocate_tensors()

# Get input and output tensors.
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()


# get details for each layer
all_layers_details = interpreter.get_tensor_details() 

for layer in all_layers_details:
    print("\n\n\n=======================","layer ",layer['index'], "=========================")
    # print(layer)
    print("layer name", str(layer['name']))
    print("layer shap", layer['shape'])
    # print(layer['quantization'])
    # print the weights in a dataset
    print("tensor")
    print(interpreter.get_tensor(layer['index']))
    print("============================================================================")