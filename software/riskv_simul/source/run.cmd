@REM compile and execute
@echo off
pushd C:\Users\eliyahu\Desktop\education\final_project\mannix_git\software\riskv_simul\source
gcc cnn_fashion_mnist.c -o cnn_fashion_mnist.exe -std=c99
cnn_fashion_mnist.exe
set /p id="press enter to exit... "
popd