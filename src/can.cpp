#include "can.h"
#include <linux/can.h>
#include <linux/can/raw.h>
#include <cstdlib> 

class BurtCan {

};

BurtCan* can_init() {
	return reinterpret_cast<BurtCan*>(new BurtCan());
}

NativeCanMessage* can_read(BurtCan* can) {
	// Sends a ScienceData(co2: 2) every 10th message
	static int i = 0;
	if (i++ % 10 != 0) return nullptr;
	NativeCanMessage* ptr = new NativeCanMessage();
	ptr->length = 5;
	ptr->buffer = (uint8_t*) calloc(8, sizeof(uint8_t));
	ptr->buffer[0] = 0x0d;
	ptr->buffer[1] = 0x00;
	ptr->buffer[2] = 0x00;
	ptr->buffer[3] = 0x00;
	ptr->buffer[4] = 0x40;
	ptr->id = 1234;
	return ptr;
}

void can_send(BurtCan* can, NativeCanMessage* message) { }

void can_free(BurtCan* can) { free(can); }

void can_message_free(NativeCanMessage* message) { 
	free(message->buffer);
	free(message);
}
