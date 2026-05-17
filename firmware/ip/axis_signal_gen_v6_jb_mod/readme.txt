Set NUM_SAMPLES = THE_ACTUAL_NUM_SAMPLES_YOU_WANT/16 to start outputing the waveform you put into the FIFO.
Make sure to load FIFO first.
If AXI bus is a constraint, just do DMA operation multiple times to get all data inside FIFO.