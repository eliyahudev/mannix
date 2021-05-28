@REM compile and execute
@echo off
pushd C:\Users\eliyahu\Desktop\education\final_project\mannix_git\software\riskv_simul\source
del -r ..\test_products\*
gcc mannix_simul_net.c -o mannix_simul_net.exe -std=c99
mannix_simul_net.exe
set /p id="press enter to exit... "
start ..\test_products\
popd