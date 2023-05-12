# TrapoTempo: Rhythm on your Keyboard

## **[Demo Video](https://b23.tv/av613620432)**

## Running the Program
- Load `media/shukufuku.wav` into SDRAM address `0x0000_0000` using the *DE10-Lite Control Panel*
- Run `demo_batch/run.bat`. This programs the EDA netlist `TrapoTempo.sof` onto the FPGA and downloads the software `TrapoTempo.elf` onto the Nios II processor.

## Game States
- You start at IDLE. Press `ENTER` to enter CONFIG.
- At CONFIG, press `Left` or `Right` to select a character skill. Press `ENTER` to enter PLAY.
- You automatically enter REPORT if (1) you complete the song or (2) your life drops to 0.
- Press `Esc` at any time to return to IDLE.

### ***IMPORTANT:** Always reload `TrapoTempo.elf` before playing again.*
