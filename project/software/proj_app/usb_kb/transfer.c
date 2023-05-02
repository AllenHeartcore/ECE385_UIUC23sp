#define _transfer_c_
#include <stdio.h>
#include "../usb_kb/project_config.h"
#include "altera_avalon_timer.h"
#include "sys/alt_alarm.h"
EP_RECORD dev0ep = { 0 };
EP_RECORD msd_ep[ 3 ] = { 0 };
#define INIT_VID_PID(v,p) 0x##p##v
#define INIT_CL_SC_P(c,s,p) 0x##00##p##s##c
const CTRL_XFER ctrl_xfers[ 2 ] = {
	XferCtrlND,
	XferCtrlData
};
DEV_RECORD devtable[ USB_NUMDEVICES + 1 ];
CLASS_CALLBACK_TABLE ClientDriverTable[ USB_NUMCLASSES ] = {
	{
		MSDProbe,
		MSDEventHandler,
		0
	},
	{
		HIDMProbe,
		HIDMEventHandler,
		0
	},
	{
		HIDKProbe,
		HIDKEventHandler,
		0
	},
	{
		DummyProbe,
		DummyEventHandler,
		0
	}
};
BYTE usb_task_state = USB_DETACHED_SUBSTATE_INITIALIZE;
BYTE usb_error;
BYTE last_usb_task_state = 0;
BYTE XferCtrlReq( BYTE addr, BYTE ep, BYTE bmReqType, BYTE bRequest, BYTE wValLo, BYTE wValHi, WORD wInd, WORD nbytes, BYTE* dataptr )
{
 BOOL direction = FALSE;
 BYTE datastage = 1;
 BYTE rcode;
 SETUP_PKT setup_pkt;
	if( dataptr == NULL ) {
		datastage = 0;
	}
	MAXreg_wr( rPERADDR, addr );
	if( bmReqType & 0x80 ) {
		direction = TRUE;
	}
	setup_pkt.ReqType_u.bmRequestType = bmReqType;
	setup_pkt.bRequest = bRequest;
	setup_pkt.wVal_u.wValueLo = wValLo;
	setup_pkt.wVal_u.wValueHi = wValHi;
	setup_pkt.wIndex = wInd;
	setup_pkt.wLength = nbytes;
	MAXbytes_wr( rSUDFIFO, 8, (BYTE *)&setup_pkt );
	rcode = XferDispatchPkt( tokSETUP, ep );
	if( rcode ) {
		return( rcode );
	}
	rcode = ctrl_xfers[ datastage ]( addr, ep, nbytes, dataptr, direction );
	return( rcode );
}
BYTE XferCtrlData( BYTE addr, BYTE ep, WORD nbytes, BYTE* dataptr, BOOL direction )
{
 BYTE rcode;
	if( direction ) {
		devtable[ addr ].epinfo[ ep ].rcvToggle = bmRCVTOG1;
		rcode = XferInTransfer( addr, ep, nbytes, dataptr, devtable[ addr ].epinfo[ ep ].MaxPktSize );
		if( rcode ) {
		return( rcode );
		}
		rcode = XferDispatchPkt( tokOUTHS, ep );
		return( rcode );
	}
	else {
		return( 0xff );
	}
}
BYTE XferCtrlND( BYTE addr, BYTE ep, WORD nbytes, BYTE* dataptr, BOOL direction )
{
 BYTE rcode;
	if( direction ) {
		rcode = XferDispatchPkt( tokOUTHS, ep );
	}
	else {
		rcode = XferDispatchPkt( tokINHS, ep );
	}
	return( rcode );
}
BYTE XferDispatchPkt( BYTE token, BYTE ep )
{
 DWORD timeout = (alt_nticks()*1000)/alt_ticks_per_second() + USB_XFER_TIMEOUT;
 BYTE tmpdata;
 BYTE rcode;
 char retry_count = 0;
 BYTE nak_count = 0;
	while( 1 ) {
		MAXreg_wr( rHXFR, ( token|ep ));
		rcode = 0xff;
		while( (alt_nticks()*1000)/alt_ticks_per_second() < timeout ) {
			tmpdata = MAXreg_rd( rHIRQ );
			if( tmpdata & bmHXFRDNIRQ ) {
				MAXreg_wr( rHIRQ, bmHXFRDNIRQ );
				rcode = 0x00;
				break;
			}
		}
		if( rcode != 0x00 ) {
			return( rcode );
		}
		rcode = ( MAXreg_rd( rHRSL ) & 0x0f );
		if( rcode == hrNAK ) {
			nak_count++;
			if( nak_count == USB_NAK_LIMIT ) {
				break;
			}
			else {
				continue;
			}
		}
		if( rcode == hrTIMEOUT ) {
			retry_count++;
			if( retry_count == USB_RETRY_LIMIT ) {
				break;
			}
			else {
				continue;
			}
		}
		else break;
	}
	return( rcode );
}
BYTE XferInTransfer( BYTE addr/* not sure if it's necessary */, BYTE ep, WORD nbytes, BYTE* data, BYTE maxpktsize )
{
 BYTE rcode;
 BYTE pktsize;
 WORD xfrlen = 0;
	MAXreg_wr( rHCTL, devtable[ addr ].epinfo[ ep ].rcvToggle );
	while( 1 ) {
		rcode = XferDispatchPkt( tokIN, ep );
		if( rcode ) {
			return( rcode );
		}
		if(( MAXreg_rd( rHIRQ ) & bmRCVDAVIRQ ) == 0 ) {
			return ( 0xf0 );
		}
		pktsize = MAXreg_rd( rRCVBC );
		data = MAXbytes_rd( rRCVFIFO, pktsize, data );
		MAXreg_wr( rHIRQ, bmRCVDAVIRQ );
		xfrlen += pktsize;
		if (( pktsize < maxpktsize ) || (xfrlen >= nbytes )) {
			if( MAXreg_rd( rHRSL ) & bmRCVTOGRD ) {
				devtable[ addr ].epinfo[ ep ].rcvToggle = bmRCVTOG1;
			}
			else {
				devtable[ addr ].epinfo[ ep ].rcvToggle = bmRCVTOG0;
			}
			return( 0 );
		}
 }
}
void USB_init( void )
{
 BYTE i;
	for( i = 0; i < ( USB_NUMDEVICES + 1 ); i++ ) {
		devtable[ i ].epinfo = NULL;
		devtable[ i ].devclass = 0;
	}
	devtable[ 0 ].epinfo = &dev0ep;
	dev0ep.MaxPktSize = 0;
	dev0ep.sndToggle = bmSNDTOG0;
	dev0ep.rcvToggle = bmRCVTOG0;
}
void USB_Task( void )
{
 static DWORD usb_delay = 0;
 static BYTE tmp_addr;
 USB_DEVICE_DESCRIPTOR buf;
 BYTE rcode, tmpdata;
 BYTE i;
	switch( usb_task_state & USB_STATE_MASK ) {
		case( USB_STATE_DETACHED ):
			switch( usb_task_state ) {
				case( USB_DETACHED_SUBSTATE_INITIALIZE ):
					USB_init();
					usb_task_state = USB_DETACHED_SUBSTATE_WAIT_FOR_DEVICE;
					break;
				case( USB_DETACHED_SUBSTATE_WAIT_FOR_DEVICE ):
					MAXreg_wr(rHCTL,bmSAMPLEBUS);
					break;
				case( USB_DETACHED_SUBSTATE_ILLEGAL ):
					break;
			}
			break;
			/**/
		case( USB_STATE_ATTACHED ):
			switch( usb_task_state ) {
				case( USB_STATE_ATTACHED ):
					usb_delay = (alt_nticks()*1000)/alt_ticks_per_second() + 200;
					usb_task_state = USB_ATTACHED_SUBSTATE_SETTLE;
					break;
				case( USB_ATTACHED_SUBSTATE_SETTLE ):
					if( (alt_nticks()*1000)/alt_ticks_per_second() > usb_delay ) {
						usb_task_state = USB_ATTACHED_SUBSTATE_RESET_DEVICE;
					}
					break;
				case( USB_ATTACHED_SUBSTATE_RESET_DEVICE ):
					MAXreg_wr( rHIRQ, bmBUSEVENTIRQ );
					MAXreg_wr( rHCTL, bmBUSRST );
					usb_task_state = USB_ATTACHED_SUBSTATE_WAIT_RESET_COMPLETE;
					break;
				case( USB_ATTACHED_SUBSTATE_WAIT_RESET_COMPLETE ):
					if(( MAXreg_rd( rHCTL ) & bmBUSRST ) == 0 ) {
						tmpdata = MAXreg_rd( rMODE ) | bmSOFKAENAB;
						MAXreg_wr( rMODE, tmpdata );
						usb_task_state = USB_ATTACHED_SUBSTATE_WAIT_SOF;
					}
					break;
				case( USB_ATTACHED_SUBSTATE_WAIT_SOF ):
					if( MAXreg_rd( rHIRQ ) | bmFRAMEIRQ ) {
						usb_task_state = USB_ATTACHED_SUBSTATE_GET_DEVICE_DESCRIPTOR_SIZE;
					}
					break;
				case( USB_ATTACHED_SUBSTATE_GET_DEVICE_DESCRIPTOR_SIZE ):
					devtable[ 0 ].epinfo->MaxPktSize = 0x0008;
					rcode = XferGetDevDescr( 0, 0, 8, (BYTE *)&buf );
					if( rcode == 0 ) {
						devtable[ 0 ].epinfo->MaxPktSize = buf.bMaxPacketSize0;
						rcode = XferGetDevDescr( 0, 0, buf.bLength, (BYTE *)&buf );
						if (buf.iManufacturer != 0)
						{
							USB_STRING_DESCRIPTOR strDesc;
							rcode = XferGetStrDescr( 0, 0, 2, buf.iManufacturer, LANG_EN_US, (BYTE *)&strDesc);
							rcode = XferGetStrDescr( 0, 0, strDesc.bLength, buf.iManufacturer, LANG_EN_US, (BYTE *)&strDesc);
							printf ("Mfgr string(%i): %s\n", buf.iManufacturer, ConvUTF8ToStr(strDesc.bString, (strDesc.bLength>>1)-1));
						}
						if (buf.iProduct != 0)
						{
							USB_STRING_DESCRIPTOR strDesc;
							rcode = XferGetStrDescr( 0, 0, 2, buf.iProduct, LANG_EN_US, (BYTE *)&strDesc);
							rcode = XferGetStrDescr( 0, 0, strDesc.bLength, buf.iProduct, LANG_EN_US, (BYTE *)&strDesc);
							printf ("Product string(%i): %s\n", buf.iProduct, ConvUTF8ToStr(strDesc.bString, (strDesc.bLength>>1)-1));
						}
						usb_task_state = USB_STATE_ADDRESSING;
					}
					else {
						usb_error = rcode;
						last_usb_task_state = usb_task_state;
						usb_task_state = USB_STATE_ERROR;
					}
					break;
			}
			break;
		case( USB_STATE_ADDRESSING ):
			for( i = 1; i < USB_NUMDEVICES; i++ ) {
				if( devtable[ i ].epinfo == NULL ) {
					devtable[ i ].epinfo = devtable[ 0 ].epinfo;
					rcode = XferSetAddr( 0, 0, i );
					if( rcode == 0 ) {
						tmp_addr = i;
						usb_task_state = USB_STATE_CONFIGURING;
					}
					else {
						usb_error = rcode;
						last_usb_task_state = usb_task_state;
						usb_task_state = USB_STATE_ERROR;
					}
					break;
				}
			}
			if( usb_task_state == USB_STATE_ADDRESSING ) {
				usb_error = 0xfe;
				last_usb_task_state = usb_task_state;
				usb_task_state = USB_STATE_ERROR;
			}
			break;
		case( USB_STATE_CONFIGURING ):
			for( i = 0; i < USB_NUMCLASSES; i++ ) {
				rcode = ClientDriverTable[ i ].Initialize( tmp_addr, 0 );
				if( rcode == TRUE ) {
					usb_task_state = USB_STATE_RUNNING;
					break;
				}
			}
			if( usb_task_state == USB_STATE_CONFIGURING ) {
				usb_error = 0xfd;
				last_usb_task_state = usb_task_state;
				usb_task_state = USB_STATE_ERROR;
			}
			break;
		case( USB_STATE_RUNNING ):
			break;
		case( USB_STATE_ERROR ):
			break;
		default:
			break;
	}
}
BOOL MSDProbe( BYTE addr, DWORD flags )
{
	return( FALSE );
}
BOOL MSDEventHandler( BYTE address, BYTE event, void *data, DWORD size )
{
	return( FALSE );
}
BOOL CDCProbe( BYTE address, DWORD flags )
{
	return( FALSE );
}
BOOL CDCEventHandler( BYTE address, BYTE event, void *data, DWORD size )
{
	return( FALSE );
}
BOOL DummyProbe( BYTE address , DWORD flags )
{
	return( FALSE );
}
BOOL DummyEventHandler( BYTE address, BYTE event, void *data, DWORD size )
{
	return( FALSE );
}
BYTE GetUsbTaskState( void )
{
	return( usb_task_state );
}
DEV_RECORD* GetDevtable( BYTE index )
{
	return( &devtable[ index ] );
}
char* ConvUTF8ToStr(BYTE* utf8, BYTE length)
{
	BYTE i;
	for (i = 0; i < length; i++)
	{
		utf8[i] = utf8[2*i];
	}
	utf8[length] = 0x00;
	return (char*)utf8;
}
