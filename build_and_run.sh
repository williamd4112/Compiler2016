make

if [ $? -eq 0 ] 
then
	./hw1 < testcase/testcase1.c > output_testcase1
	./hw1 < testcase/testcase2.c > output_testcase2
	./hw1 < testcase/testcase3.c > output_testcase3
else
	echo "FAIL"
fi	
