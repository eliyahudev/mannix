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
echo "compilation passed! bravo!!
git push"
	git push
else
	echo "you have compliation errors!!!
fix the errors and run again
i.e. run:
cd workspace/
./check_rtl.sh
script exited"
	exit 0
fi
