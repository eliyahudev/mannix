#!/bin/bash

cd workspace/
echo "check compilation"

if ! ./check_rtl.sh | grep -q 'Simulation is complete'
then 
	echo "you have compliation errors!!!
fix the errors and run again
i.e. run:
cd workspace/
./check_rtl.sh
script exited"
	exit 0
fi
echo "compilation passed! bravo!!"

#no need to enter password when git push
if ! grep -q cache ~/.gitconfig
then
git config --global credential.helper 'cache --timeout=36000000'
git config --global push.default matching
	echo "your git credentials will be saved on the next push"
fi

echo "running acc_mem_wrap_tb.sv test"
./acc_mem_wrap_tb.sh > run.log
rm run.log
if  cat ../tb/FCresults.log | grep -q 'FAIL'
then 
	echo "acc_mem_wrap_tb.sv failed!!!!!
try to figure out what broken or contact with Dor or Simhi
for to run the test:
cd workspace
./acc_mem_wrap_tb.sh
script exited"
	exit 0
fi
echo "acc_mem_wrap_tb.sv test passed! bravo!!"

echo "git pull"
git pull
if git pull | grep -q error 
then
	echo "git pull command failed, try to run git pull and resolve the issue and then run again the push.sh script
script exited"
	exit 0
fi
echo "pull succeeded"

echo "check compilation agaim"
if ./check_rtl.sh | grep -q 'Simulation is complete' 
then
echo "compilation passed! bravo!!"
echo "running acc_mem_wrap_tb.sv test again"
./acc_mem_wrap_tb.sh > run.log
rm run.log
if  cat ../tb/FCresults.log | grep -q 'PASS'
then
	echo "acc_mem_wrap_tb.sv test passed! bravo!!
git push"
	git push
else 
	echo "acc_mem_wrap_tb.sv failed!!!!!
try to figure out what broken or contact with Dor or Simhi
for to run the test:
cd workspace
./acc_mem_wrap_tb.sh
script exited"
	exit 0
fi
else
	echo "you have compliation errors!!!
fix the errors and run again
i.e. run:
cd workspace/
./check_rtl.sh
script exited"
	exit 0
fi

