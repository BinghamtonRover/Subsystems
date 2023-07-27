#include <stdint.h>

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

struct BurtCan;
typedef struct BurtCan BurtCan;

struct CanMessage {
	uint8_t* buffer;
	uint16_t id;
	int length;
};
typedef struct CanMessage CanMessage;

#ifdef __cplusplus
extern "C" {
#endif

FFI_PLUGIN_EXPORT void can_message_free(CanMessage* message);

FFI_PLUGIN_EXPORT BurtCan* can_init();
FFI_PLUGIN_EXPORT void can_send(BurtCan* can, CanMessage* message);
FFI_PLUGIN_EXPORT CanMessage* can_read(BurtCan* can);
FFI_PLUGIN_EXPORT void can_destroy(BurtCan* can);

#ifdef __cplusplus
}
#endif
