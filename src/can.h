#include <stdint.h>

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

struct BurtCan;
typedef struct BurtCan BurtCan;

struct NativeCanMessage {
	uint8_t* buffer;
	uint16_t id;
	int length;
};
typedef struct NativeCanMessage NativeCanMessage;

#ifdef __cplusplus
extern "C" {
#endif

FFI_PLUGIN_EXPORT BurtCan* can_init();
FFI_PLUGIN_EXPORT void can_free(BurtCan* message);
FFI_PLUGIN_EXPORT void can_send(BurtCan* can, NativeCanMessage* message);
FFI_PLUGIN_EXPORT NativeCanMessage* can_read(BurtCan* can);

FFI_PLUGIN_EXPORT void can_message_free(NativeCanMessage* message);

#ifdef __cplusplus
}
#endif
