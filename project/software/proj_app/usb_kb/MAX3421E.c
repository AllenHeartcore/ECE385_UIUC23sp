#define _MAX3421E_C_
#include "system.h"
#include "stdlib.h"
#include "stdio.h"
#include "string.h"
#include "../usb_kb/project_config.h"
#include "altera_avalon_spi.h"
#include "altera_avalon_spi_regs.h"
#include "altera_avalon_pio_regs.h"
#include <sys/alt_stdio.h>
#include <unistd.h>
extern BYTE usb_task_state;
void SPI_init(BYTE sync_mode, BYTE bus_mode, BYTE smp_phase) {
}
BYTE SPI_wr(BYTE data) {
}
void MAXreg_wr(BYTE reg, BYTE val) {
	alt_u8 wbuf[2] = {reg + 2, val};
	if (alt_avalon_spi_command(SPI_BASE, 0, 2, wbuf, 0, NULL, 0) < 0)
		printf("SPI write register error\n");
}
BYTE* MAXbytes_wr(BYTE reg, BYTE nbytes, BYTE* data) {
	alt_u8 wbuf[nbytes + 1];
	wbuf[0] = reg + 2;
	for (int i = 0; i < nbytes; i++)
		wbuf[i + 1] = data[i];
	if (alt_avalon_spi_command(SPI_BASE, 0, nbytes + 1, wbuf, 0, NULL, 0) < 0)
		printf("SPI write bytes error\n");
	return data + nbytes;
}
BYTE MAXreg_rd(BYTE reg) {
	BYTE val = 0;
	if (alt_avalon_spi_command(SPI_BASE, 0, 1, &reg, 1, &val, 0) < 0)
		printf("SPI read register error\n");
	return val;
}
BYTE* MAXbytes_rd(BYTE reg, BYTE nbytes, BYTE* data) {
	if (alt_avalon_spi_command(SPI_BASE, 0, 1, &reg, nbytes, data, 0) < 0)
		printf("SPI read bytes error\n");
	return data + nbytes;
}
void MAX3421E_reset(void) {
	IOWR_ALTERA_AVALON_PIO_DATA(PIO_USB_RST_BASE, 0);
	usleep(1000000);
	IOWR_ALTERA_AVALON_PIO_DATA(PIO_USB_RST_BASE, 1);
	BYTE tmp = 0;
	MAXreg_wr( rUSBCTL, bmCHIPRES);
	MAXreg_wr( rUSBCTL, 0x00);
	while (!(MAXreg_rd( rUSBIRQ) & bmOSCOKIRQ)) {
		tmp++;
		if (tmp == 0) {
			printf("reset timeout!");
		}
	}
}
BOOL Vbus_power(BOOL action) {
	return (1);
}
void MAX_busprobe(void) {
	BYTE bus_sample;
	bus_sample = MAXreg_rd( rHRSL);
	bus_sample &= ( bmJSTATUS | bmKSTATUS);
	switch (bus_sample) {
	case ( bmJSTATUS):
		if (usb_task_state != USB_ATTACHED_SUBSTATE_WAIT_RESET_COMPLETE) {
			if (!(MAXreg_rd( rMODE) & bmLOWSPEED)) {
				MAXreg_wr( rMODE, MODE_FS_HOST);
				printf("Starting in full speed\n");
			} else {
				MAXreg_wr( rMODE, MODE_LS_HOST);
				printf("Starting in low speed\n");
			}
			usb_task_state = ( USB_STATE_ATTACHED);
		}
		break;
	case ( bmKSTATUS):
		if (usb_task_state != USB_ATTACHED_SUBSTATE_WAIT_RESET_COMPLETE) {
			if (!(MAXreg_rd( rMODE) & bmLOWSPEED)) {
				MAXreg_wr( rMODE, MODE_LS_HOST);
				printf("Starting in low speed\n");
			} else {
				MAXreg_wr( rMODE, MODE_FS_HOST);
				printf("Starting in full speed\n");
			}
			usb_task_state = ( USB_STATE_ATTACHED);
		}
		break;
	case ( bmSE1):
		usb_task_state = ( USB_DETACHED_SUBSTATE_ILLEGAL);
		break;
	case ( bmSE0):
		if (!((usb_task_state & USB_STATE_MASK) == USB_STATE_DETACHED))
			usb_task_state = ( USB_DETACHED_SUBSTATE_INITIALIZE);
		else {
			MAXreg_wr( rMODE, MODE_FS_HOST);
			usb_task_state = ( USB_DETACHED_SUBSTATE_WAIT_FOR_DEVICE);
		}
		break;
	}
}
void MAX3421E_init(void) {
	MAXreg_wr( rPINCTL, (bmFDUPSPI + bmINTLEVEL + bmGPXB));
	MAX3421E_reset();
	Vbus_power( OFF);
	MAXreg_wr( rGPINIEN, bmGPINIEN7);
	Vbus_power( ON);
	MAXreg_wr( rMODE, bmDPPULLDN | bmDMPULLDN | bmHOST | bmSEPIRQ);
	MAXreg_wr( rHIEN, bmCONDETIE);
	MAXreg_wr(rHCTL, bmSAMPLEBUS);
	MAX_busprobe();
	MAXreg_wr( rHIRQ, bmCONDETIRQ);
	MAXreg_wr( rCPUCTL, 0x01);
}
void MAX3421E_Task(void) {
	if ( IORD_ALTERA_AVALON_PIO_DATA(PIO_USB_IRQ_BASE) == 0) {
		printf("MAX interrupt\n\r");
		MaxIntHandler();
	}
	if ( IORD_ALTERA_AVALON_PIO_DATA(PIO_USB_GPX_BASE) == 1) {
		printf("GPX interrupt\n\r");
		MaxGpxHandler();
	}
}
void MaxIntHandler(void) {
	BYTE HIRQ;
	BYTE HIRQ_sendback = 0x00;
	HIRQ = MAXreg_rd( rHIRQ);
	printf("IRQ: %x\n", HIRQ);
	if (HIRQ & bmFRAMEIRQ) {
		HIRQ_sendback |= bmFRAMEIRQ;
	}
	if (HIRQ & bmCONDETIRQ) {
		MAX_busprobe();
		HIRQ_sendback |= bmCONDETIRQ;
	}
	if (HIRQ & bmSNDBAVIRQ)
	{
		MAXreg_wr(rSNDBC, 0x00);
	}
	if (HIRQ & bmBUSEVENTIRQ) {
		usb_task_state++;
		HIRQ_sendback |= bmBUSEVENTIRQ;
	}
	MAXreg_wr( rHIRQ, HIRQ_sendback);
}
void MaxGpxHandler(void) {
	BYTE GPINIRQ;
	GPINIRQ = MAXreg_rd( rGPINIRQ);
}
