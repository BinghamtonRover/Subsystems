#include <cstring>
#include <unistd.h>

// Linux headers
#include <linux/can.h>
#include <linux/can/raw.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>

#include <cstring>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>

#include "burt_can.hpp"

burt_can::BurtCan::BurtCan(const char* interface, int32_t readTimeout, BurtCanType mode) :
	interface(interface),
	readTimeout(readTimeout),
	mode(mode) { }

BurtCanStatus burt_can::BurtCan::open() {
	// Declare structs
	struct sockaddr_can address;
	struct ifreq ifr;

	// Open the socket
	handle = socket(PF_CAN, SOCK_RAW, CAN_RAW);
	if (handle < 0) {
		return BurtCanStatus::SOCKET_CREATE_ERROR;
	}

	// Define the interface we'll use on the socket
	strncpy(ifr.ifr_name, interface, strlen(interface));
	ioctl(handle, SIOCGIFINDEX, &ifr);
	if (!ifr.ifr_ifindex) {
		return BurtCanStatus::INTERFACE_PARSE_ERROR;
	}

	if (mode == BurtCanType::CANFD) {  // Switch to FD mode
		int mtu = ifr.ifr_mtu;
		int enableFD = 1;

		if (ioctl(handle, SIOCGIFMTU, &ifr) < 0) {
			return BurtCanStatus::MTU_ERROR;
		} else if (mtu != CANFD_MTU) {
			return BurtCanStatus::CANFD_NOT_SUPPORTED;
		} else if (setsockopt(handle, SOL_CAN_RAW, CAN_RAW_FD_FRAMES, &enableFD, sizeof(enableFD))) {
			return BurtCanStatus::FD_MISC_ERROR;
		}
	}

	// Configure CAN options
	address.can_family = AF_CAN;
	address.can_ifindex = ifr.ifr_ifindex;
	struct timeval tv;
		tv.tv_sec = readTimeout;
		tv.tv_usec = 0;
	setsockopt(handle, SOL_SOCKET, SO_RCVTIMEO, (const char*) &tv, sizeof(struct timeval));

	// Bind the socket to the address
	if (bind(handle, (struct sockaddr*) &address, sizeof(address)) < 0) {
		return BurtCanStatus::BIND_ERROR;
	}
	return BurtCanStatus::OK;
}

BurtCanStatus burt_can::BurtCan::send(const NativeCanMessage* frame) {
	// Copy the CanFrame to a can_frame and send it.
	can_frame raw;
	raw.can_id = frame->id;
	raw.len = frame->length;
	std::memcpy(raw.data, frame->data, 8);
	int size = sizeof(raw);
	if (write(handle, &raw, size) == size) {
		return BurtCanStatus::OK;
	} else {		
		return BurtCanStatus::WRITE_ERROR;
	}
}

BurtCanStatus burt_can::BurtCan::receive(NativeCanMessage* frame) {
	can_frame raw;
	int size = sizeof(raw);
	int bytesRead = read(handle, &raw, size);
	if (byetsRead == 0) { 
		return BurtCanStatus::OK; 
	} else if (bytesRead == size) {
		frame->id = raw.can_id;
		frame->length = raw.len;
		std::memcpy(frame->data, raw.data, 8);
		return BurtCanStatus::OK;
	} else {
		frame->length = 0;
		return BurtCanStatus::OK;
	}
}

BurtCanStatus burt_can::BurtCan::dispose() {
	if (close(handle) < 0) {
		return BurtCanStatus::CLOSE_ERROR;
	} else {
		return BurtCanStatus::OK;
	}
}

burt_can::BurtCan::~BurtCan() {
	dispose();
}
