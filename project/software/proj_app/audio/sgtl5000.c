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
		while (1);
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
		while (1);
	}
	return DATA;
}

void SGTL5000_init () {

	ALT_AVALON_I2C_DEV_t *i2c_dev;
	i2c_dev = alt_avalon_i2c_open("/dev/i2c");
	alt_avalon_i2c_master_target_set(i2c_dev, 0xA);

	BYTE int_divisor = 180633600 / 12500000;
	WORD frac_divisor = (WORD)(((180633600.0f / 12500000.0f) - (float)int_divisor) * 2048.0f);

	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_PLL_CTRL, \
				int_divisor << SGTL5000_PLL_INT_DIV_SHIFT |
				frac_divisor << SGTL5000_PLL_FRAC_DIV_SHIFT);
	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_ANA_POWER, \
			SGTL5000_DAC_STEREO |
			SGTL5000_PLL_POWERUP |
			SGTL5000_VCOAMP_POWERUP | 
			SGTL5000_VAG_POWERUP |
			SGTL5000_ADC_STEREO |
			SGTL5000_REFTOP_POWERUP |
			SGTL5000_HP_POWERUP |
			SGTL5000_DAC_POWERUP |
			SGTL5000_CAPLESS_HP_POWERUP |
			SGTL5000_ADC_POWERUP);
	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_REF_CTRL, 0x004E);
	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_DIG_POWER,\
			SGTL5000_ADC_EN |
			SGTL5000_DAC_EN |
			SGTL5000_I2S_OUT_POWERUP |
			SGTL5000_I2S_IN_POWERUP);
	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_CLK_CTRL, \
			SGTL5000_SYS_FS_44_1k << SGTL5000_SYS_FS_SHIFT |
			SGTL5000_MCLK_FREQ_PLL << SGTL5000_MCLK_FREQ_SHIFT);
	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_I2S_CTRL, SGTL5000_I2S_MASTER);
	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_ANA_CTRL, \
			SGTL5000_ADC_SEL_LINE_IN << SGTL5000_ADC_SEL_SHIFT);
	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_SSS_CTRL, \
			SGTL5000_DAC_SEL_I2S_IN << SGTL5000_DAC_SEL_SHIFT |
			SGTL5000_I2S_OUT_SEL_ADC << SGTL5000_I2S_OUT_SEL_SHIFT);
	SGTL5000_Reg_Wr(i2c_dev, SGTL5000_CHIP_ADCDAC_CTRL, 0x0000);
}
