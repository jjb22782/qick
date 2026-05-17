module tb_top();

reg s0_axis_aresetn;
reg s0_axis_aclk;
reg aresetn;
reg aclk;

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

reg [31:0] s0_axis_tdata_i;
reg s0_axis_tvalid_i;
wire s0_axis_tready_o;

reg [159:0] s1_axis_tdata_i;
reg s1_axis_tvalid_i;
wire s1_axis_tready_o;

reg m_axis_tready_i;
wire m_axis_tvalid_o;
wire [255:0] m_axis_tdata_o;

// SIGNAL GEN TOP
signal_gen_top #(
		.N		(16),
		.N_DDS	(16)
	)
signal_gen_top_i (
    .aresetn(aresetn),
    .aclk(aclk),
    // AXIS Slave to load memory samples.
    .s0_axis_aresetn  (s0_axis_aresetn),
    .s0_axis_aclk     (s0_axis_aclk),
    .s0_axis_tdata_i  (s0_axis_tdata_i),
    .s0_axis_tvalid_i (s0_axis_tvalid_i),
    .s0_axis_tready_o (s0_axis_tready_o),
    // AXIS Slave to queue waveforms.
    .s1_axis_tdata_i   (s1_axis_tdata_i),
    .s1_axis_tvalid_i  (s1_axis_tvalid_i),
    .s1_axis_tready_o  (s1_axis_tready_o),
    // M_AXIS for output.
    .m_axis_tready_i  (m_axis_tready_i),
    .m_axis_tvalid_o  (m_axis_tvalid_o),
    .m_axis_tdata_o   (m_axis_tdata_o),
    // Registers.
    .START_ADDR_REG(0),
    .WE_REG(0)
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

    for(ii=0; ii<2**12; ii=ii+1) begin
        half_word_a = ii;
        half_word_b = 0;
        s0_axis_tdata_i  <= {half_word_b,half_word_a};
        s0_axis_tvalid_i <= 1;
        #10;
    end
    
    s0_axis_tvalid_i <= 0;
	#10000;
end

reg [15:0] fill_a;
reg [15:0] length;
reg [15:0] fill_b;
reg [15:0] gain;
reg [95:0] fill_c;

initial begin
	aresetn          <= 0;
    s1_axis_tdata_i  <= 0;
    s1_axis_tvalid_i <= 0;
    m_axis_tready_i  <= 0;
	#100;
    aresetn          <= 1;
    #100000;

    fill_a           = 0;
    fill_b           = 0;
    fill_c           = 0;
    length           = 2**12/16;
    gain             = 2**15-1;
    s1_axis_tdata_i  <= {fill_a,length,fill_b,gain,fill_c};
    s1_axis_tvalid_i <= 1;
    m_axis_tready_i  <= 1;
    #2;
    s1_axis_tvalid_i <= 0;
    #100000;
    
    fill_a           = 0;
    fill_b           = 0;
    fill_c           = 0;
    length           = 2**12/16;
    gain             = 2**15-1;
    s1_axis_tdata_i  <= {fill_a,length,fill_b,gain,fill_c};
    s1_axis_tvalid_i <= 1;
    m_axis_tready_i  <= 1;
    #2;
    s1_axis_tvalid_i <= 0;
    #100000;
end

endmodule

