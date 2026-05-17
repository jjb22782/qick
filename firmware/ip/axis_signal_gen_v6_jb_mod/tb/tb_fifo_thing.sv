module tb_fifo_thing();

reg s0_axis_aresetn;
reg s0_axis_aclk;
reg aresetn;
reg aclk;
reg aclk_d2;

always begin
	s0_axis_aclk <= 0;
	#5;
	s0_axis_aclk <= 1;
	#5;
end
always begin
	aclk <= 0;
	#1;
	aclk <= 1;
	#1;
end
always begin
	aclk_d2 <= 0;
	#2;
	aclk_d2 <= 1;
	#2;
end

reg [15:0] control_reg_num_samples;
reg control_reg_start_bit;

reg [31:0] s0_axis_tdata_i;
reg s0_axis_tvalid_i;
wire s0_axis_tready_o;

reg m_axis_tready_i;
wire m_axis_tvalid_o;
wire [255:0] m_axis_tdata_o;

// DATA FIFO
fifo_thing_controller #(
    .INPUT_DATA_WIDTH       (32),
    .DAC_DATA_WIDTH         (16),
    .OUTPUT_DATA_WIDTH      (256),
    .NUM_SAMPLES_DATA_WIDTH (16)
)
data_fifo_i (
    .control_reg_num_samples(control_reg_num_samples),
    .control_reg_start_bit(control_reg_start_bit),
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

integer ii;
reg [15:0] half_word_a;
reg [15:0] half_word_b;

initial begin
	s0_axis_aresetn  <= 0;
    s0_axis_tdata_i  <= 0;
    s0_axis_tvalid_i <= 0;
    #100;
    s0_axis_aresetn  <= 1;
    #1000;

    for(ii=0; ii<16*16; ii=ii+1) begin
        half_word_a = 2*ii;
        half_word_b = 2*ii+1;
        s0_axis_tdata_i  <= {half_word_b,half_word_a};
        s0_axis_tvalid_i <= 1;
        #10;
    end
    
    s0_axis_tvalid_i <= 0;
	#10000;
end

initial begin
	aresetn                 <= 0;
    control_reg_num_samples <= 0;
    control_reg_start_bit   <= 0;
    m_axis_tready_i         <= 0;
	#100;
    aresetn                 <= 1;
    #1000;

    #10000;

    control_reg_num_samples <= 16;
    control_reg_start_bit   <= 1;
    m_axis_tready_i         <= 1;
    #6;

    control_reg_start_bit   <= 0;
    #10000;
end

endmodule

