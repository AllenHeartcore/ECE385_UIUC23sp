#ifndef _transfer_h_
#define _transfer_h_
#define USB_NUMTARGETS 4
#define USB_NUMDEVICES 8
#define USB_NUMCLASSES 4
#define UNINIT 0
#define HID_K 1
#define HID_M 2
#define MSD 3
#define USB_REQUEST_GET_STATUS 0
#define USB_REQUEST_CLEAR_FEATURE 1
#define USB_REQUEST_SET_FEATURE 3
#define USB_REQUEST_SET_ADDRESS 5
#define USB_REQUEST_GET_DESCRIPTOR 6
#define USB_REQUEST_SET_DESCRIPTOR 7
#define USB_REQUEST_GET_CONFIGURATION 8
#define USB_REQUEST_SET_CONFIGURATION 9
#define USB_REQUEST_GET_INTERFACE 10
#define USB_REQUEST_SET_INTERFACE 11
#define USB_REQUEST_SYNCH_FRAME 12
#define USB_FEATURE_ENDPOINT_HALT 0
#define USB_FEATURE_DEVICE_REMOTE_WAKEUP 1
#define USB_FEATURE_TEST_MODE 2
#define USB_SETUP_HOST_TO_DEVICE 0x00
#define USB_SETUP_DEVICE_TO_HOST 0x80
#define USB_SETUP_TYPE_STANDARD 0x00
#define USB_SETUP_TYPE_CLASS 0x20
#define USB_SETUP_TYPE_VENDOR 0x40
#define USB_SETUP_RECIPIENT_DEVICE 0x00
#define USB_SETUP_RECIPIENT_INTERFACE 0x01
#define USB_SETUP_RECIPIENT_ENDPOINT 0x02
#define USB_SETUP_RECIPIENT_OTHER 0x03
#define USB_DESCRIPTOR_DEVICE 0x01
#define USB_DESCRIPTOR_CONFIGURATION 0x02
#define USB_DESCRIPTOR_STRING 0x03
#define USB_DESCRIPTOR_INTERFACE 0x04
#define USB_DESCRIPTOR_ENDPOINT 0x05
#define USB_DESCRIPTOR_DEVICE_QUALIFIER 0x06
#define USB_DESCRIPTOR_OTHER_SPEED 0x07
#define USB_DESCRIPTOR_INTERFACE_POWER 0x08
#define USB_DESCRIPTOR_OTG 0x09
#define OTG_FEATURE_B_HNP_ENABLE 3
#define OTG_FEATURE_A_HNP_SUPPORT 4
#define OTG_FEATURE_A_ALT_HNP_SUPPORT 5
#define USB_TRANSFER_TYPE_CONTROL 0x00
#define USB_TRANSFER_TYPE_ISOCHRONOUS 0x01
#define USB_TRANSFER_TYPE_BULK 0x02
#define USB_TRANSFER_TYPE_INTERRUPT 0x03
#define bmUSB_TRANSFER_TYPE 0x03
#define USB_FEATURE_ENDPOINT_STALL 0
#define USB_FEATURE_DEVICE_REMOTE_WAKEUP 1
#define USB_FEATURE_TEST_MODE 2
#define USB_MSD_GET_MAX_LUN 0xFE
#define USB_MSD_RESET 0xFF
#define HID_REQUEST_GET_REPORT 0x01
#define HID_REQUEST_GET_IDLE 0x02
#define HID_REQUEST_GET_PROTOCOL 0x03
#define HID_REQUEST_SET_REPORT 0x09
#define HID_REQUEST_SET_IDLE 0x0A
#define HID_REQUEST_SET_PROTOCOL 0x0B
#define HID_DESCRIPTOR_HID 0x21
#define HID_DESCRIPTOR_REPORT 0x22
#define HID_DESRIPTOR_PHY 0x23
#define BOOT_PROTOCOL 0x00
#define RPT_PROTOCOL 0x01
#define HID_INTF 0x03
#define BOOT_INTF_SUBCLASS 0x01
#define HID_PROTOCOL_NONE 0x00
#define HID_PROTOCOL_KEYBOARD 0x01
#define HID_PROTOCOL_MOUSE 0x02
typedef struct {
	union {
		BYTE bmRequestType;
		struct {
			BYTE recipient :5;
			BYTE type :2;
			BYTE direction :1;
		};
	} ReqType_u;
	BYTE bRequest;
	union {
		WORD wValue;
		struct {
			BYTE wValueLo;
			BYTE wValueHi;
		};
	} wVal_u;
	WORD wIndex;
	WORD wLength;
} SETUP_PKT, *PSETUP_PKT;
typedef struct {
	BYTE epAddr;
	BYTE Attr;
	WORD MaxPktSize;
	BYTE Interval;
	BYTE sndToggle;
	BYTE rcvToggle;
} EP_RECORD;
typedef struct {
	EP_RECORD* epinfo;
	BYTE devclass;
} DEV_RECORD;
typedef struct {
	union {
		DWORD val;
		struct {
			WORD idVendor;
			WORD idProduct;
		};
		struct {
			BYTE bClass;
			BYTE bSubClass;
			BYTE bProtocol;
		};
	} dev_u;
	BYTE bConfig;
	BYTE numep;
	EP_RECORD* epinfo;
	BYTE CltDrv;
	const char * desc;
} USB_TPL_ENTRY;
typedef BYTE (*CTRL_XFER)(BYTE addr, BYTE ep, WORD nbytes, BYTE* dataptr,
		BOOL direction);
typedef BOOL (*CLASS_INIT)(BYTE address, DWORD flags);
typedef BOOL (*CLASS_EVENT_HANDLER)(BYTE address, BYTE event, void *data,
		DWORD size);
typedef struct {
	CLASS_INIT Initialize;
	CLASS_EVENT_HANDLER EventHandler;
	DWORD flags;
} CLASS_CALLBACK_TABLE;
#define bmREQ_GET_DESCR USB_SETUP_DEVICE_TO_HOST|USB_SETUP_TYPE_STANDARD|USB_SETUP_RECIPIENT_DEVICE
#define bmREQ_SET USB_SETUP_HOST_TO_DEVICE|USB_SETUP_TYPE_STANDARD|USB_SETUP_RECIPIENT_DEVICE
#define bmREQ_CL_GET_INTF USB_SETUP_DEVICE_TO_HOST|USB_SETUP_TYPE_CLASS|USB_SETUP_RECIPIENT_INTERFACE
#define bmREQ_HIDOUT USB_SETUP_HOST_TO_DEVICE|USB_SETUP_TYPE_CLASS|USB_SETUP_RECIPIENT_INTERFACE
#define bmREQ_HIDIN USB_SETUP_DEVICE_TO_HOST|USB_SETUP_TYPE_CLASS|USB_SETUP_RECIPIENT_INTERFACE
#define XferSetAddr( oldaddr, ep, newaddr ) \
		XferCtrlReq( oldaddr, ep, bmREQ_SET, USB_REQUEST_SET_ADDRESS, newaddr, 0x00, 0x0000, 0x0000, NULL )
#define XferSetConf( addr, ep, conf_value ) \
		XferCtrlReq( addr, ep, bmREQ_SET, USB_REQUEST_SET_CONFIGURATION, conf_value, 0x00, 0x0000, 0x0000, NULL )
#define XferGetDevDescr( addr, ep, nbytes, dataptr ) \
		XferCtrlReq( addr, ep, bmREQ_GET_DESCR, USB_REQUEST_GET_DESCRIPTOR, 0x00, USB_DESCRIPTOR_DEVICE, 0x0000, nbytes, dataptr )
#define XferGetConfDescr( addr, ep, nbytes, conf, dataptr ) \
		XferCtrlReq( addr, ep, bmREQ_GET_DESCR, USB_REQUEST_GET_DESCRIPTOR, conf, USB_DESCRIPTOR_CONFIGURATION, 0x0000, nbytes, dataptr )
#define XferGetStrDescr( addr, ep, nbytes, index, langid, dataptr ) \
	XferCtrlReq( addr, ep, bmREQ_GET_DESCR, USB_REQUEST_GET_DESCRIPTOR, index, USB_DESCRIPTOR_STRING, langid, nbytes, dataptr )
#define XferSetProto( addr, ep, interface, protocol ) \
		XferCtrlReq( addr, ep, bmREQ_HIDOUT, HID_REQUEST_SET_PROTOCOL, protocol, 0x00, interface, 0x0000, NULL )
#define XferGetProto( addr, ep, interface, dataptr ) \
		XferCtrlReq( addr, ep, bmREQ_HIDIN, HID_REQUEST_GET_PROTOCOL, 0x00, 0x00, interface, 0x0001, dataptr )
#define XferGetIdle( addr, ep, interface, reportID, dataptr ) \
		XferCtrlReq( addr, ep, bmREQ_HIDIN, HID_REQUEST_GET_IDLE, reportID, 0, interface, 0x0001, dataptr )
BYTE XferCtrlReq(BYTE addr, BYTE ep, BYTE bmReqType, BYTE bRequest, BYTE wValLo,
		BYTE wValHi, WORD wInd, WORD nbytes, BYTE* dataptr);
BYTE XferCtrlData(BYTE addr, BYTE ep, WORD nbytes, BYTE* dataptr,
		BOOL direction);
BYTE XferCtrlND(BYTE addr, BYTE ep, WORD nbytes, BYTE* dataptr, BOOL direction);
BYTE XferDispatchPkt(BYTE token, BYTE ep);
BYTE XferInTransfer(BYTE addr, BYTE ep, WORD nbytes, BYTE* data,
		BYTE maxpktsize);
void USB_init(void);
void USB_Task(void);
BYTE GetUsbTaskState(void);
DEV_RECORD* GetDevtable(BYTE index);
BOOL MSDProbe(BYTE address, DWORD flags);
BOOL MSDEventHandler(BYTE address, BYTE event, void *data, DWORD size);
BOOL CDCProbe(BYTE address, DWORD flags);
BOOL CDCEventHandler(BYTE address, BYTE event, void *data, DWORD size);
BOOL DummyProbe(BYTE address, DWORD flags);
BOOL DummyEventHandler(BYTE address, BYTE event, void *data, DWORD size);
char* ConvUTF8ToStr(BYTE* utf8, BYTE length);
#endif
