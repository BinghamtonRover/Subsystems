#include "can.h"
#include <linux/can.h>
#include <linux/can/raw.h>
#include <cstdlib> 

class BurtCan {

};

BurtCan* can_init() {
	return reinterpret_cast<BurtCan*>(new BurtCan());
}

CanMessage* can_read(BurtCan* can) {
	static int i = 0;
	if (i++ % 10 != 0) return nullptr;
	CanMessage* ptr = new CanMessage();
	ptr->length = 2;
	ptr->buffer = (uint8_t*) calloc(8, sizeof(uint8_t));
	ptr->buffer[0] = 0x12;
	ptr->buffer[1] = 0x34;
	ptr->id = 1234;
	return ptr;
}

void can_send(BurtCan* can, CanMessage* message) { }

void can_destroy(BurtCan* can) { free(can); }

void can_message_free(CanMessage* message) {
	free(message->buffer);
	free(message);
}
