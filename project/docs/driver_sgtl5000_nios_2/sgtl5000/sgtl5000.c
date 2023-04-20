//SGTL5000 register control with the Intel FPGA I2C peripheral
//Written by Zuofu Cheng for ECE 385

#include "sgtl5000.h"
#include "altera_avalon_i2c.h"
#include "altera_avalon_i2c_regs.h"

WORD SGTL5000_Reg_Rd (ALT_AVALON_I2C_DEV_t* dev, WORD ADDR)
{
	BYTE buffer[2];
	WORD value;
	buffer[0] = (ADDR & 0xFF00) >> 8;
	buffer[1] = (ADDR & 0x00FF);

	ALT_AVALON_I2C_STATUS_CODE status=alt_avalon_i2c_master_tx_rx(dev,buffer,2,buffer,2,0);

	if (status != ALT_AVALON_I2C_SUCCESS){
		printf ("SGTL5000 I2C error, address: %x", ADDR);
		while (1)
		{
			//hang here
		}
	}
	value = (buffer[0] << 8) | buffer[1];
	return value;
}

WORD SGTL5000_Reg_Wr (ALT_AVALON_I2C_DEV_t* dev, WORD ADDR, WORD DATA)
{
	BYTE buffer[4];
	buffer[0] = (ADDR & 0xFF00) >> 8;
	buffer[1] = (ADDR & 0x00FF);
	buffer[2] = (DATA & 0xFF00) >> 8;
	buffer[3] = (DATA & 0x00FF);


	ALT_AVALON_I2C_STATUS_CODE status=alt_avalon_i2c_master_tx(dev,buffer,4,0);

	if (status != ALT_AVALON_I2C_SUCCESS){
		printf ("SGTL5000 I2C error, address: %x", ADDR);
		while (1)
		{
			//hang here
		}
	}
	return DATA;
}
