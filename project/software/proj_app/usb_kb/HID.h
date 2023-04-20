#ifndef _HID_h_
#define _HID_h
typedef struct {
	BYTE addr;
	BYTE interface;
} HID_DEVICE;
typedef struct {
	BYTE button;
	BYTE Xdispl;
	BYTE Ydispl;
	BYTE bytes3to7[5];
} BOOT_MOUSE_REPORT;
typedef struct {
	BYTE mod;
	BYTE reserved;
	BYTE keycode[6];
} BOOT_KBD_REPORT;
BOOL HIDMProbe(BYTE address, DWORD flags);
BOOL HIDKProbe(BYTE address, DWORD flags);
void HID_init(void);
BYTE mousePoll(BOOT_MOUSE_REPORT* buf);
BYTE kbdPoll(BOOT_KBD_REPORT* buf);
BOOL HIDMEventHandler(BYTE addr, BYTE event, void *data, DWORD size);
BOOL HIDKEventHandler(BYTE addr, BYTE event, void *data, DWORD size);
#endif
