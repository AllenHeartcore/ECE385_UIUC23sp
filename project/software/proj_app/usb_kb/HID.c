#include <stdio.h>
#include "../usb_kb/project_config.h"
BYTE bigbuf[256];
extern DEV_RECORD devtable[];
HID_DEVICE hid_device = { 0 };
EP_RECORD hid_ep[2] = { 0 };
BOOL HIDMProbe(BYTE addr, DWORD flags) {
	BYTE tmpbyte;
	BYTE rcode;
	BYTE confvalue;
	WORD total_length;
	USB_DESCR* data_ptr = (USB_DESCR *) &bigbuf;
	BYTE* byte_ptr = bigbuf;
	rcode = XferGetConfDescr(addr, 0, CONF_DESCR_LEN, 0, bigbuf);
	if (rcode) {
		return (FALSE);
	}
	if (data_ptr->descr.config.wTotalLength > 256) {
		total_length = 256;
	} else {
		total_length = data_ptr->descr.config.wTotalLength;
	}
	rcode = XferGetConfDescr(addr, 0, total_length, 0, bigbuf);
	if (rcode) {
		return (FALSE);
	}
	confvalue = data_ptr->descr.config.bConfigurationValue;
	while (byte_ptr < bigbuf + total_length) {
		if (data_ptr->descr.config.bDescriptorType != USB_DESCRIPTOR_INTERFACE) {
			byte_ptr = byte_ptr + data_ptr->descr.config.bLength;
			data_ptr = (USB_DESCR*) byte_ptr;
		}
		else {
			BYTE class = data_ptr->descr.interface.bInterfaceClass;
			BYTE subclass = data_ptr->descr.interface.bInterfaceSubClass;
			BYTE protocol = data_ptr->descr.interface.bInterfaceProtocol;
			if (class == HID_INTF && subclass == BOOT_INTF_SUBCLASS
					&& protocol == HID_PROTOCOL_MOUSE) {
				devtable[addr].devclass = HID_M;
				tmpbyte = devtable[addr].epinfo->MaxPktSize;
				HID_init();
				devtable[addr].epinfo = hid_ep;
				devtable[addr].epinfo[0].MaxPktSize = tmpbyte;
				hid_device.interface =
						data_ptr->descr.interface.bInterfaceNumber;
				hid_device.addr = addr;
				byte_ptr = byte_ptr + data_ptr->descr.config.bLength;
				data_ptr = (USB_DESCR*) byte_ptr;
				while (byte_ptr < bigbuf + total_length) {
					if (data_ptr->descr.config.bDescriptorType
							!= USB_DESCRIPTOR_ENDPOINT) {
						byte_ptr = byte_ptr + data_ptr->descr.config.bLength;
						data_ptr = (USB_DESCR*) byte_ptr;
					} else {
						devtable[addr].epinfo[1].epAddr =
								data_ptr->descr.endpoint.bEndpointAddress;
						devtable[addr].epinfo[1].Attr =
								data_ptr->descr.endpoint.bmAttributes;
						devtable[addr].epinfo[1].MaxPktSize =
								data_ptr->descr.endpoint.wMaxPacketSize;
						devtable[addr].epinfo[1].Interval =
								data_ptr->descr.endpoint.bInterval;
						rcode = XferSetConf(addr, 0, confvalue);
						if (rcode) {
							return (FALSE);
						}
						rcode = XferSetProto(addr, 0, hid_device.interface,
								BOOT_PROTOCOL);
						if (rcode) {
							return (FALSE);
						} else {
							return (TRUE);
						}
					}
				}
			}
			else {
				return (FALSE);
			}
		}
	}
	return (FALSE);
}
BOOL HIDKProbe(BYTE addr, DWORD flags) {
	BYTE tmpbyte;
	BYTE rcode;
	BYTE confvalue;
	WORD total_length;
	USB_DESCR* data_ptr = (USB_DESCR *) &bigbuf;
	BYTE* byte_ptr = bigbuf;
	rcode = XferGetConfDescr(addr, 0, CONF_DESCR_LEN, 0, bigbuf);
	if (rcode) {
		return (FALSE);
	}
	if (data_ptr->descr.config.wTotalLength > 256) {
		total_length = 256;
	} else {
		total_length = data_ptr->descr.config.wTotalLength;
	}
	rcode = XferGetConfDescr(addr, 0, total_length, 0, bigbuf);
	if (rcode) {
		return (FALSE);
	}
	confvalue = data_ptr->descr.config.bConfigurationValue;
	while (byte_ptr < bigbuf + total_length) {
		if (data_ptr->descr.config.bDescriptorType != USB_DESCRIPTOR_INTERFACE) {
			byte_ptr = byte_ptr + data_ptr->descr.config.bLength;
			data_ptr = (USB_DESCR*) byte_ptr;
		}
		else {
			BYTE class = data_ptr->descr.interface.bInterfaceClass;
			BYTE subclass = data_ptr->descr.interface.bInterfaceSubClass;
			BYTE protocol = data_ptr->descr.interface.bInterfaceProtocol;
			if (class == HID_INTF && subclass == BOOT_INTF_SUBCLASS
					&& protocol == HID_PROTOCOL_KEYBOARD) {
				devtable[addr].devclass = HID_K;
				tmpbyte = devtable[addr].epinfo->MaxPktSize;
				HID_init();
				devtable[addr].epinfo = hid_ep;
				devtable[addr].epinfo[0].MaxPktSize = tmpbyte;
				hid_device.interface =
						data_ptr->descr.interface.bInterfaceNumber;
				hid_device.addr = addr;
				byte_ptr = byte_ptr + data_ptr->descr.config.bLength;
				data_ptr = (USB_DESCR*) byte_ptr;
				while (byte_ptr < bigbuf + total_length) {
					if (data_ptr->descr.config.bDescriptorType
							!= USB_DESCRIPTOR_ENDPOINT) {
						byte_ptr = byte_ptr + data_ptr->descr.config.bLength;
						data_ptr = (USB_DESCR*) byte_ptr;
					} else {
						devtable[addr].epinfo[1].epAddr =
								data_ptr->descr.endpoint.bEndpointAddress;
						devtable[addr].epinfo[1].Attr =
								data_ptr->descr.endpoint.bmAttributes;
						devtable[addr].epinfo[1].MaxPktSize =
								data_ptr->descr.endpoint.wMaxPacketSize;
						devtable[addr].epinfo[1].Interval =
								data_ptr->descr.endpoint.bInterval;
						rcode = XferSetConf(addr, 0, confvalue);
						if (rcode) {
							return (FALSE);
						}
						rcode = XferSetProto(addr, 0, hid_device.interface,
								BOOT_PROTOCOL);
						if (rcode) {
							return (FALSE);
						} else {
							return (TRUE);
						}
					}
				}
			}
			else {
				return (FALSE);
			}
		}
	}
	return (FALSE);
}
void HID_init(void) {
	hid_ep[1].sndToggle = bmSNDTOG0;
	hid_ep[1].rcvToggle = bmRCVTOG0;
}
BYTE mousePoll(BOOT_MOUSE_REPORT* buf) {
	BYTE rcode;
	MAXreg_wr( rPERADDR, hid_device.addr);
	rcode = XferInTransfer(hid_device.addr, 1, 8, (BYTE*) buf,
			devtable[hid_device.addr].epinfo[1].MaxPktSize);
	return (rcode);
}
BYTE kbdPoll(BOOT_KBD_REPORT* buf) {
	BYTE rcode;
	MAXreg_wr( rPERADDR, hid_device.addr);
	rcode = XferInTransfer(hid_device.addr, 1, 8, (BYTE*) buf,
			devtable[hid_device.addr].epinfo[1].MaxPktSize);
	return (rcode);
}
BOOL HIDMEventHandler(BYTE address, BYTE event, void *data, DWORD size) {
	return (FALSE);
}
BOOL HIDKEventHandler(BYTE address, BYTE event, void *data, DWORD size) {
	return (FALSE);
}
