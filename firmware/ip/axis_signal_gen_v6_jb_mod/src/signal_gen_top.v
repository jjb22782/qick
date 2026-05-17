module signal_gen_top 
	(
		// Reset and clock.
    	aresetn				,
		aclk				,

    	// AXIS Slave to load memory samples.
    	s0_axis_aresetn	    ,
		s0_axis_aclk		,
		s0_axis_tdata_i		,
		s0_axis_tvalid_i	,
		s0_axis_tready_o	,

    	// AXIS Slave to queue waveforms.
		s1_axis_tdata_i		,
		s1_axis_tvalid_i	,
		s1_axis_tready_o	,

		// M_AXIS for output.
		m_axis_tready_i		,
		m_axis_tvalid_o		,
		m_axis_tdata_o		,

		// Registers.
		START_ADDR_REG		,
		WE_REG
	);

/**************/
/* Parameters */
/**************/
// Memory address size.
parameter N = 16;

// Number of parallel dds blocks.
parameter [31:0] N_DDS = 16;

/*********/
/* Ports */
/*********/
input					aresetn;
input					aclk;

input					s0_axis_aresetn;
input					s0_axis_aclk;
input 	[31:0]			s0_axis_tdata_i;
input					s0_axis_tvalid_i;
output					s0_axis_tready_o;

input 	[159:0]			s1_axis_tdata_i;
input					s1_axis_tvalid_i;
output					s1_axis_tready_o;

input					m_axis_tready_i;
output					m_axis_tvalid_o;
output	[N_DDS*16-1:0]	m_axis_tdata_o;

input   [31:0]  		START_ADDR_REG;
input           		WE_REG;

/********************/
/* Internal signals */
/********************/
wire                    aclk_d2;
// Fifo.
wire					fifo_wr_en;
wire	[159:0]			fifo_din;
wire					fifo_rd_en;
wire	[159:0]			fifo_dout;
wire					fifo_full;
wire					fifo_empty;
// Control Regs
wire [15:0]             controlreg_num_samples;
wire [15:0]             controlreg_gain;
wire                    controlreg_start_bit;

////////////////////

assign fifo_wr_en	    = s1_axis_tvalid_i;
assign fifo_din		    = s1_axis_tdata_i;
assign s1_axis_tready_o	= ~fifo_full;

// CONTROL FIFO.
fifo #(
	// Data width.
	.B	(160),
	// Fifo depth.
	.N	(16)
)
control_fifo_i ( 
	.rstn	(aresetn	),
	.clk 	(aclk		),
	// Write I/F.
	.wr_en 	(fifo_wr_en	),
	.din    (fifo_din	),
	// Read I/F.
	.rd_en 	(fifo_rd_en	),
	.dout  	(fifo_dout	),
	// Flags.
	.full   (fifo_full	),
	.empty  (fifo_empty	)
);

////////////////////

// CLOCK GEN
BUFGCE_DIV #(
    .BUFGCE_DIVIDE(2) // 1-8
)
BUFGCE_DIV_inst (
    .O(aclk_d2), // 1-bit output: Buffer
    .CE(1'b1), // 1-bit input: Buffer enable
    .CLR(1'b0), // 1-bit input: Asynchronous clear
    .I(aclk) // 1-bit input: Buffer
);

// CONTROL REGS
control_regs #(
    .FIFO_DATA_WIDTH                    (160),
    .CONTROLREG_NUM_SAMPLES_DATA_WIDTH (16),
    .CONTROLREG_GAIN_DATA_WIDTH        (16)
) 
control_regs_i (
	.rstn	(aresetn	),
	.clk 	(aclk		),
    // Read I/F.
	.rd_en 	(fifo_rd_en	),
	.dout  	(fifo_dout	),
    .empty  (fifo_empty	),
    //
    .controlreg_num_samples(controlreg_num_samples),
    .controlreg_gain(controlreg_gain),
    .controlreg_start_bit(controlreg_start_bit)
);

// DATA FIFO
fifo_thing_controller #(
    .INPUT_DATA_WIDTH       (32),
    .DAC_DATA_WIDTH         (16),
    .OUTPUT_DATA_WIDTH      (256),
    .CONTROLREG_NUM_SAMPLES_DATA_WIDTH (16),
    .CONTROLREG_GAIN_DATA_WIDTH(16)
)
data_fifo_i (
    .controlreg_num_samples(controlreg_num_samples),
    .controlreg_gain(controlreg_gain),
    .controlreg_start_bit(controlreg_start_bit),
    .WE_REG(WE_REG),
    // AXIS Slave to load memory samples.
    .s0_axis_aresetn  (s0_axis_aresetn),
    .s0_axis_aclk     (s0_axis_aclk),
    .s0_axis_tdata_i  (s0_axis_tdata_i),
    .s0_axis_tvalid_i (s0_axis_tvalid_i),
    .s0_axis_tready_o (s0_axis_tready_o),
    // M_AXIS for output.
    .m_axis_aresetn   (aresetn),
    .m_axis_aclk      (aclk),
    .m_axis_aclk_d2   (aclk_d2),
    .m_axis_tready_i  (m_axis_tready_i),
    .m_axis_tvalid_o  (m_axis_tvalid_o),
    .m_axis_tdata_o   (m_axis_tdata_o)
);

endmodule

