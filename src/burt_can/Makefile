shared: burt_can.so

burt_can.so: burt_can.cpp
	g++ -Wall -Werror -c burt_can.cpp -o burt_can.o
	g++ -Wall -Werror -c burt_can_ffi.cpp -o burt_can_ffi.o
	g++ -shared burt_can.o burt_can_ffi.o -o burt_can.so

clean: 
	rm -rf *.o *.so
