all: can serial

can: 
	g++ -c can.cpp -o can.o
	gcc -shared can.o -o can.so

clean: 
	rm -f *.o *.so *.exp *.lib *.obj *.out
	rm -f libserialport/*.so
	rm -f ../*.so

SerialCommand = gcc
SerialCommand += libserialport/serialport.c
SerialCommand += libserialport/timing.c
SerialCommand += libserialport/linux.c
SerialCommand += libserialport/linux_termios.c
SerialCommand += -DLIBSERIALPORT_ATBUILD  # Defines a preprocessor command
SerialCommand += -I. # Includes <config.h> from this dir
SerialCommand += -fPIC  # Position-independent code. Useful for shared libraries
SerialCommand += -std=c99 -Wall -Wextra -pedantic -Wmissing-prototypes -Wshadow  # Misc options
SerialCommand += -shared -o libserialport.so  # Output to a shared library

serial: 
	$(SerialCommand)
	sudo cp libserialport.so /usr/lib
