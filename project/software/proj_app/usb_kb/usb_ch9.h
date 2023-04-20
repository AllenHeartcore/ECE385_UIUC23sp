#ifndef _USB_CH9_H_
#define _USB_CH9_H_
#define DEV_DESCR_LEN 18
#define CONF_DESCR_LEN 9
#define INTR_DESCR_LEN 9
#define EP_DESCR_LEN 7
typedef struct {
	BYTE bLength;
	BYTE bDescriptorType;
	WORD bcdUSB;
	BYTE bDeviceClass;
	BYTE bDeviceSubClass;
	BYTE bDeviceProtocol;
	BYTE bMaxPacketSize0;
	WORD idVendor;
	WORD idProduct;
	WORD bcdDevice;
	BYTE iManufacturer;
	BYTE iProduct;
	BYTE iSerialNumber;
	BYTE bNumConfigurations;
} USB_DEVICE_DESCRIPTOR;
typedef struct {
	BYTE bLength;
	BYTE bDescriptorType;
	WORD wTotalLength;
	BYTE bNumInterfaces;
	BYTE bConfigurationValue;
	BYTE iConfiguration;
	BYTE bmAttributes;
	BYTE bMaxPower;
} USB_CONFIGURATION_DESCRIPTOR;
#define USB_CFG_DSC_REQUIRED 0x80
#define USB_CFG_DSC_SELF_PWR (0x40)
#define USB_CFG_DSC_REM_WAKE (0x20)
typedef struct {
	BYTE bLength;
	BYTE bDescriptorType;
	BYTE bInterfaceNumber;
	BYTE bAlternateSetting;
	BYTE bNumEndpoints;
	BYTE bInterfaceClass;
	BYTE bInterfaceSubClass;
	BYTE bInterfaceProtocol;
	BYTE iInterface;
} USB_INTERFACE_DESCRIPTOR;
typedef struct {
	BYTE bLength;
	BYTE bDescriptorType;
	BYTE bEndpointAddress;
	BYTE bmAttributes;
	WORD wMaxPacketSize;
	BYTE bInterval;
} USB_ENDPOINT_DESCRIPTOR;
#define EP_DIR_IN 0x80
#define EP_DIR_OUT 0x00
#define EP_ATTR_CONTROL (0<<0)
#define EP_ATTR_ISOCH (1<<0)
#define EP_ATTR_BULK (2<<0)
#define EP_ATTR_INTR (3<<0)
#define EP_ATTR_NO_SYNC (0<<2)
#define EP_ATTR_ASYNC (1<<2)
#define EP_ATTR_ADAPT (2<<2)
#define EP_ATTR_SYNC (3<<2)
#define EP_ATTR_DATA (0<<4)
#define EP_ATTR_FEEDBACK (1<<4)
#define EP_ATTR_IMP_FB (2<<4)
#define EP_MAX_PKT_INTR_LS 8
#define EP_MAX_PKT_INTR_FS 64
#define EP_MAX_PKT_ISOCH_FS 1023
#define EP_MAX_PKT_BULK_FS 64
#define EP_LG_PKT_BULK_FS 32
#define EP_MED_PKT_BULK_FS 16
#define EP_SM_PKT_BULK_FS 8
typedef struct {
	BYTE bLength;
	BYTE bDescriptorType;
	BYTE bmAttributes;
} USB_OTG_DESCRIPTOR;
typedef struct {
	BYTE bLength;
	BYTE bDescriptorType;
	BYTE bString[256 - 2];
} USB_STRING_DESCRIPTOR;
typedef struct {
	BYTE bLength;
	BYTE bDescriptorType;
	WORD bcdUSB;
	BYTE bDeviceClass;
	BYTE bDeviceSubClass;
	BYTE bDeviceProtocol;
	BYTE bMaxPacketSize0;
	BYTE bNumConfigurations;
	BYTE bReserved;
} USB_DEVICE_QUALIFIER_DESCRIPTOR;
#define PID_OUT 0x1
#define PID_ACK 0x2
#define PID_DATA0 0x3
#define PID_PING 0x4
#define PID_SOF 0x5
#define PID_NYET 0x6
#define PID_DATA2 0x7
#define PID_SPLIT 0x8
#define PID_IN 0x9
#define PID_NAK 0xA
#define PID_DATA1 0xB
#define PID_PRE 0xC
#define PID_ERR 0xC
#define PID_SETUP 0xD
#define PID_STALL 0xE
#define PID_MDATA 0xF
#define PID_MASK_DATA 0x03
#define PID_MASK_DATA_SHIFTED (PID_MASK_DATA << 2)
#define LANG_EN_US								0x0409
#define OTG_HNP_SUPPORT 0x02
#define OTG_SRP_SUPPORT 0x01
#define USB_HUB_CLASSCODE 0x09
typedef struct {
	BYTE bLength;
	BYTE bDescriptorType;
	WORD bcdHID;
	BYTE bCountryCode;
	BYTE bNumDescriptors;
	BYTE bDescrType;
	WORD wDescriptorLength;
} USB_HID_DESCRIPTOR;
typedef struct {
	union {
		BYTE buf[80];
		USB_DEVICE_DESCRIPTOR device;
		USB_CONFIGURATION_DESCRIPTOR config;
		USB_INTERFACE_DESCRIPTOR interface;
		USB_ENDPOINT_DESCRIPTOR endpoint;
		USB_STRING_DESCRIPTOR string;
		USB_HID_DESCRIPTOR HID;
	} descr;
} USB_DESCR;
#endif
