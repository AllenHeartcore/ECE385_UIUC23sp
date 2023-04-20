//SGTL5000 register control with the Intel FPGA I2C peripheral
//Written by Zuofu Cheng for ECE 385
//Configured for Fs=44.1kHz, SGTL5000 as I2S master
//Line-in -> ADC -> I2S Out
//I2S In -> DAC -> Headphone Out


#include <stdio.h>
#include "system.h"
#include "altera_avalon_spi.h"
#include "altera_avalon_spi_regs.h"
#include "altera_avalon_pio_regs.h"
#include "altera_avalon_i2c.h"
#include "altera_avalon_i2c_regs.h"
#include "sys/alt_irq.h"
#include "sgtl5000/GenericTypeDefs.h"
#include "sgtl5000/sgtl5000.h"


void setLED(int LED)
{
	IOWR_ALTERA_AVALON_PIO_DATA(LEDS_PIO_BASE, (IORD_ALTERA_AVALON_PIO_DATA(LEDS_PIO_BASE) | (0x001 << LED)));
}

void clearLED(int LED)
{
	IOWR_ALTERA_AVALON_PIO_DATA(LEDS_PIO_BASE, (IORD_ALTERA_AVALON_PIO_DATA(LEDS_PIO_BASE) & ~(0x001 << LED)));

}

void printSignedHex0(signed char value)
{
	BYTE tens = 0;
	BYTE ones = 0;
	WORD pio_val = IORD_ALTERA_AVALON_PIO_DATA(HEX_DIGITS_PIO_BASE);
	if (value < 0)
	{
		setLED(11);
		value = -value;
	}
	else
	{
		clearLED(11);
	}
	//handled hundreds
	if (value / 100)
		setLED(13);
	else
		clearLED(13);

	value = value % 100;
	tens = value / 10;
	ones = value % 10;

	pio_val &= 0x00FF;
	pio_val |= (tens << 12);
	pio_val |= (ones << 8);

	IOWR_ALTERA_AVALON_PIO_DATA(HEX_DIGITS_PIO_BASE, pio_val);
}

void printSignedHex1(signed char value)
{
	BYTE tens = 0;
	BYTE ones = 0;
	DWORD pio_val = IORD_ALTERA_AVALON_PIO_DATA(HEX_DIGITS_PIO_BASE);
	if (value < 0)
	{
		setLED(10);
		value = -value;
	}
	else
	{
		clearLED(10);
	}
	//handled hundreds
	if (value / 100)
		setLED(12);
	else
		clearLED(12);

	value = value % 100;
	tens = value / 10;
	ones = value % 10;
	tens = value / 10;
	ones = value % 10;

	pio_val &= 0xFF00;
	pio_val |= (tens << 4);
	pio_val |= (ones << 0);

	IOWR_ALTERA_AVALON_PIO_DATA(HEX_DIGITS_PIO_BASE, pio_val);
}


int main()
{
	ALT_AVALON_I2C_DEV_t *i2c_dev; //pointer to instance structure
	//get a pointer to the Avalon i2c instance
	i2c_dev = alt_avalon_i2c_open("/dev/i2c_0"); //this has to reflect Platform Designer name
	if (NULL==i2c_dev)						     //check the BSP if unsure
	{
		printf("Error: Cannot find /dev/i2c_0\n");
		return 1;
	}
	printf ("I2C Test Program\n");

	alt_avalon_i2c_master_target_set(i2c_dev,0xA); //CODEC at address 0b0001010
	//print device ID (verify I2C is working)
	printf( "Device ID register: %x\n", SGTL5000_Reg_Rd (i2c_dev, SGTL5000_CHIP_ID));

	//configure PLL, input frequency is 12.5 MHz, output frequency is 180.6336 MHz if 44.1kHz is desired
	//or 196.608 MHz else
	BYTE int_divisor = 180633600/12500000;
	WORD frac_divisor = (WORD)(((180633600.0f/12500000.0f) - (float)int_divisor) * 2048.0f);
	printf( "Programming PLL with integer divisor: %d, fractional divisor %d\n", int_divisor, frac_divisor);
	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_PLL_CTRL, \
				int_divisor << SGTL5000_PLL_INT_DIV_SHIFT|
				frac_divisor << SGTL5000_PLL_FRAC_DIV_SHIFT);
	printf( "CHIP_PLL_CTRL register: %x\n", SGTL5000_Reg_Rd (i2c_dev, SGTL5000_CHIP_PLL_CTRL));

	//configure power control, disable internal VDDD, VDDIO=3.3V, VDDA=VDDD=1.8V (ext)
	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_ANA_POWER, \
			SGTL5000_DAC_STEREO|
			SGTL5000_PLL_POWERUP|
			SGTL5000_VCOAMP_POWERUP|
			SGTL5000_VAG_POWERUP|
			SGTL5000_ADC_STEREO|
			SGTL5000_REFTOP_POWERUP|
			SGTL5000_HP_POWERUP|
			SGTL5000_DAC_POWERUP|
			SGTL5000_CAPLESS_HP_POWERUP|
			SGTL5000_ADC_POWERUP);
	printf( "CHIP_ANA_POWER register: %x\n", SGTL5000_Reg_Rd (i2c_dev, SGTL5000_CHIP_ANA_POWER));

	//select internal ground bias to .9V (1.8V/2)
	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_REF_CTRL, 0x004E);
	printf( "CHIP_REF_CTRL register: %x\n", SGTL5000_Reg_Rd (i2c_dev, SGTL5000_CHIP_REF_CTRL));

	//enable core modules
	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_DIG_POWER,\
			SGTL5000_ADC_EN|
			SGTL5000_DAC_EN|
			//SGTL5000_DAP_POWERUP| //disable digital audio processor in CODEC
			SGTL5000_I2S_OUT_POWERUP|
			SGTL5000_I2S_IN_POWERUP);
	printf( "CHIP_DIG_POWER register: %x\n", SGTL5000_Reg_Rd (i2c_dev, SGTL5000_CHIP_DIG_POWER));


	//MCLK is 12.5 MHz, configure clocks to use PLL
	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_CLK_CTRL, \
			SGTL5000_SYS_FS_44_1k << SGTL5000_SYS_FS_SHIFT |
			SGTL5000_MCLK_FREQ_PLL << SGTL5000_MCLK_FREQ_SHIFT);
	printf( "CHIP_CLK_CTRL register: %x\n", SGTL5000_Reg_Rd (i2c_dev, SGTL5000_CHIP_CLK_CTRL));

	//Set as I2S master
	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_I2S_CTRL, SGTL5000_I2S_MASTER);
	printf( "CHIP_I2S_CTRL register: %x\n", SGTL5000_Reg_Rd (i2c_dev, SGTL5000_CHIP_I2S_CTRL));

	//ADC input from Line
	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_ANA_CTRL, \
			SGTL5000_ADC_SEL_LINE_IN << SGTL5000_ADC_SEL_SHIFT);
	printf( "CHIP_ANA_CTRL register: %x\n", SGTL5000_Reg_Rd (i2c_dev, SGTL5000_CHIP_ANA_CTRL));

	//ADC -> I2S out, I2S in -> DAC
	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_SSS_CTRL, \
			SGTL5000_DAC_SEL_I2S_IN << SGTL5000_DAC_SEL_SHIFT |
			SGTL5000_I2S_OUT_SEL_ADC << SGTL5000_I2S_OUT_SEL_SHIFT);
	printf( "CHIP_SSS_CTRL register: %x\n", SGTL5000_Reg_Rd (i2c_dev, SGTL5000_CHIP_SSS_CTRL));

	printf( "CHIP_ANA_CTRL register: %x\n", SGTL5000_Reg_Rd (i2c_dev, SGTL5000_CHIP_ANA_CTRL));

	//ADC -> I2S out, I2S in -> DAC
	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_ADCDAC_CTRL, 0x0000);
	printf( "CHIP_ADCDAC_CTRL register: %x\n", SGTL5000_Reg_Rd (i2c_dev, SGTL5000_CHIP_ADCDAC_CTRL));
	printf( "CHIP_PAD_STRENGTH register: %x\n", SGTL5000_Reg_Rd (i2c_dev, SGTL5000_CHIP_PAD_STRENGTH));


	return 0;
}
