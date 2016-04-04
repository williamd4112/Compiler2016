make

if [ $? -eq 0 ] 
then
	./hw1 < testcase/testcase1.c
	./hw1 < testcase/testcase2.c
	./hw1 < testcase/testcase3.c
else
	echo "FAIL"
fi	
