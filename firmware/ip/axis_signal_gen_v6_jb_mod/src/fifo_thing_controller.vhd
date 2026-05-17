library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Library UNISIM;
use UNISIM.vcomponents.all;
Library xpm;
use xpm.vcomponents.all;

use ieee.numeric_std.all;

entity fifo_thing_controller is
    generic(
        INPUT_DATA_WIDTH                  : positive := 32;
        DAC_DATA_WIDTH                    : positive := 16;
        OUTPUT_DATA_WIDTH                 : positive := 256;
        CONTROLREG_NUM_SAMPLES_DATA_WIDTH : positive := 16;
        CONTROLREG_GAIN_DATA_WIDTH        : positive := 16
    );
    port (
        controlreg_num_samples : in std_logic_vector(CONTROLREG_NUM_SAMPLES_DATA_WIDTH-1 downto 0);
        controlreg_gain        : in std_logic_vector(CONTROLREG_GAIN_DATA_WIDTH-1 downto 0);
        controlreg_start_bit   : in std_logic;
        WE_REG                 : in std_logic;
        -- AXIS Slave to load memory samples.
        s0_axis_aresetn  : in  std_logic;
        s0_axis_aclk     : in  std_logic;
        s0_axis_tdata_i  : in  std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);
        s0_axis_tvalid_i : in  std_logic;
        s0_axis_tready_o : out std_logic;
        -- M_AXIS for output.
        m_axis_aresetn   : in  std_logic;
        m_axis_aclk      : in  std_logic;
        m_axis_aclk_d2   : in  std_logic;
        m_axis_tready_i  : in  std_logic;
        m_axis_tvalid_o  : out std_logic;
        m_axis_tdata_o   : out std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0)
    );
end fifo_thing_controller;

architecture rtl of fifo_thing_controller is

    constant INTERMEDIATE_DATA_WIDTH : positive := DAC_DATA_WIDTH*2;
    constant NUM_PARALLEL_FIFOS      : positive := OUTPUT_DATA_WIDTH/DAC_DATA_WIDTH;
    constant FIFO_DEPTH              : positive := 2**15;

    -- RST
    signal s0_axis_areset : std_logic;
    signal m_axis_areset  : std_logic;
    signal soft_reset     : std_logic;
    signal soft_reset_counter : unsigned(3 downto 0);
    signal WE_REG_z1      : std_logic;
    signal WE_REG_z2      : std_logic;
    signal WE_REG_z3      : std_logic;

    -- FIFO INPUT
    type  fifo_data_in_t is array (0 to NUM_PARALLEL_FIFOS-1) of std_logic_vector(DAC_DATA_WIDTH-1 downto 0);
    signal fifo_data_in       : fifo_data_in_t;
    signal fifo_data_write_en : std_logic_vector(NUM_PARALLEL_FIFOS-1 downto 0);
    signal fifo_in_count      : unsigned(3 downto 0);

    -- FIFO_CONTROL
    type t_input_fifo_state is (I_INIT, I_READ_EN);
    signal intermediate_fifo_read_en           : std_logic;
    signal intermediate_fifo_read_en_state     : t_input_fifo_state;
    signal intermediate_fifo_read_en_count     : unsigned(CONTROLREG_NUM_SAMPLES_DATA_WIDTH-1 downto 0);
    signal input_fifo_num_samples       : std_logic_vector(CONTROLREG_NUM_SAMPLES_DATA_WIDTH-1 downto 0);
    signal input_fifo_num_samples_count : unsigned(CONTROLREG_NUM_SAMPLES_DATA_WIDTH-1 downto 0);
    signal input_fifo_start_bit         : std_logic;
    --
    type t_output_fifo_state is (O_INIT, O_READY, O_READ_EN);
    signal output_fifo_read_en           : std_logic;
    signal output_fifo_read_en_state     : t_output_fifo_state;
    signal output_fifo_num_samples       : std_logic_vector(CONTROLREG_NUM_SAMPLES_DATA_WIDTH-1 downto 0);
    signal output_fifo_num_samples_count : unsigned(CONTROLREG_NUM_SAMPLES_DATA_WIDTH-1 downto 0);
    signal output_fifo_start_bit         : std_logic;
    signal output_fifo_empty             : std_logic_vector(NUM_PARALLEL_FIFOS-1 downto 0);

    -- FIFO OUTPUT
    type  fifo_data_out_t is array (0 to NUM_PARALLEL_FIFOS-1) of std_logic_vector(DAC_DATA_WIDTH-1 downto 0);
    signal fifo_data_out       : fifo_data_out_t;
    signal fifo_data_out_valid : std_logic_vector(NUM_PARALLEL_FIFOS-1 downto 0);
    signal fifo_data_with_gain_out       : fifo_data_out_t;
    signal fifo_data_with_gain_out_valid : std_logic_vector(NUM_PARALLEL_FIFOS-1 downto 0);

begin

    process(m_axis_aclk)
    begin
        if(rising_edge(m_axis_aclk)) then
            WE_REG_z1 <= WE_REG;
            WE_REG_z2 <= WE_REG_z1;
            WE_REG_z3 <= WE_REG_z2;
            if(WE_REG_z3='0' and WE_REG_z2='1') then
                soft_reset_counter <= "1111";
            elsif(soft_reset_counter /= "0000") then
                soft_reset_counter <= soft_reset_counter - 1;
            end if;
            --
            if(soft_reset_counter = "0000") then
                soft_reset <= '0';
            else
                soft_reset <= '1';
            end if;
            --
            if(m_axis_aresetn='0') then
                WE_REG_z1          <= '0';
                WE_REG_z2          <= '0';
                WE_REG_z3          <= '0';
                soft_reset         <= '0';
                soft_reset_counter <= "0000";
            end if;
        end if;
    end process;
    
    ---------------------
    -- INVERTED RESETS --
    ---------------------
    s0_axis_areset <= (not s0_axis_aresetn);
    m_axis_areset  <= (not m_axis_aresetn);

    -------------------
    -- INPUT CONTROL --
    -------------------
    process(s0_axis_aclk)
    begin
        if(rising_edge(s0_axis_aclk)) then
            s0_axis_tready_o   <= '1';
            fifo_data_write_en <= (others => '0');
            --
            if(s0_axis_tvalid_i='1') then
                if(fifo_in_count = (fifo_in_count'range => '1')) then
                    fifo_in_count <= (others => '0');
                else
                    fifo_in_count <= fifo_in_count + 1;
                end if;
            end if;
            --
            for ii in 0 to NUM_PARALLEL_FIFOS-1 loop
                if(ii=to_integer(fifo_in_count) and s0_axis_tvalid_i='1') then
                    fifo_data_write_en(ii) <= '1';
                end if;
                --
                fifo_data_in(ii) <= s0_axis_tdata_i(DAC_DATA_WIDTH-1 downto 0);
            end loop;
            --
            if(s0_axis_aresetn='0') then
                s0_axis_tready_o   <= '0';
                fifo_in_count      <= (others => '0');
                fifo_data_write_en <= (others => '0');
            end if;
        end if;
    end process;

    --------------------------
    -- INTERMEDIATE CONTROL --
    --------------------------
    xpm_cdc_array_single_inst : xpm_cdc_array_single
        generic map (
            WIDTH => CONTROLREG_NUM_SAMPLES_DATA_WIDTH
        )
        port map (
            dest_out => input_fifo_num_samples,
            dest_clk => m_axis_aclk_d2,
            src_clk  => m_axis_aclk,
            src_in   => controlreg_num_samples
        );
    xpm_cdc_single_inst : xpm_cdc_single
        port map (
            dest_out => input_fifo_start_bit,
            dest_clk => m_axis_aclk_d2,
            src_clk  => m_axis_aclk,
            src_in   => controlreg_start_bit
        );
    process(m_axis_aclk_d2)
    begin
        if(rising_edge(m_axis_aclk_d2)) then
            intermediate_fifo_read_en    <= '0';
            input_fifo_num_samples_count <= (others => '0');
            case(intermediate_fifo_read_en_state) is
                when I_INIT =>
                    if(input_fifo_start_bit='1') then
                        intermediate_fifo_read_en_state <= I_READ_EN;
                    end if;
                --
                when I_READ_EN =>
                    intermediate_fifo_read_en    <= '1';
                    input_fifo_num_samples_count <= input_fifo_num_samples_count+1;
                    if(unsigned('0'&input_fifo_num_samples(15 downto 1)) = input_fifo_num_samples_count) then
                        intermediate_fifo_read_en       <= '0';
                        intermediate_fifo_read_en_state <= I_INIT;
                    end if;
                --
                when others => null;
            end case;
            -- RESET
            if(m_axis_aresetn='0') then
                intermediate_fifo_read_en_state <= I_INIT;
            end if;
        end if;
    end process;

    --------------------
    -- OUTPUT CONTROL --
    --------------------
    process(m_axis_aclk)
    begin
        if(rising_edge(m_axis_aclk)) then
            output_fifo_start_bit         <= controlreg_start_bit; -- DON'T HAVE TO USE XPM_CDC. CONTROL REG IS ON M_AXIS_ACLK.
            output_fifo_num_samples       <= controlreg_num_samples; -- DON'T HAVE TO USE XPM_CDC. CONTROL REG IS ON M_AXIS_ACLK.
            output_fifo_read_en           <= '0';
            output_fifo_num_samples_count <= (others => '0');
            case(output_fifo_read_en_state) is
                when O_INIT =>
                    if(output_fifo_start_bit='1') then
                        output_fifo_read_en_state <= O_READY;
                    end if;
                --
                when O_READY =>
                    if(output_fifo_empty=(output_fifo_empty'range => '0')) then
                        output_fifo_read_en_state <= O_READ_EN;
                    end if;
                --
                when O_READ_EN =>
                    output_fifo_read_en           <= '1';
                    output_fifo_num_samples_count <= output_fifo_num_samples_count+1;
                    if(unsigned(output_fifo_num_samples) = output_fifo_num_samples_count) then
                        output_fifo_read_en       <= '0';
                        output_fifo_read_en_state <= O_INIT;
                    end if;
                --
                when others => null;
            end case;
            -- RESET
            if(m_axis_aresetn='0') then
                output_fifo_read_en_state <= O_INIT;
            end if;
        end if;
    end process;

    ---------------
    -- GEN FIFOS --
    ---------------
    fifo_gen : for ii in 0 to NUM_PARALLEL_FIFOS-1 generate
    begin
        inst_fifo_thing : entity work.fifo_thing
            generic map (
                INPUT_DATA_WIDTH        => DAC_DATA_WIDTH,
                INTERMEDIATE_DATA_WIDTH => INTERMEDIATE_DATA_WIDTH,
                OUTPUT_DATA_WIDTH       => DAC_DATA_WIDTH,
                FIFO_DEPTH              => FIFO_DEPTH
            )
            port map (
                -- INPUT CONTROL
                clk_input_fifo             => s0_axis_aclk,
                rst_input_fifo             => s0_axis_areset,
                input_fifo_data_in         => fifo_data_in(ii),--: in  std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);
                input_fifo_write_en        => fifo_data_write_en(ii),--: in  std_logic;
                -- INTERMEDIATE CONTROL
                clk_output_fifo_d2         => m_axis_aclk_d2,
                intermediate_fifo_read_en  => intermediate_fifo_read_en,--: in  std_logic;
                soft_reset                 => soft_reset,
                -- OUTPUT CONTROL
                clk_output_fifo            => m_axis_aclk,
                rst_output_fifo            => m_axis_areset,
                output_fifo_read_en        => output_fifo_read_en,--: in  std_logic;
                output_fifo_empty          => output_fifo_empty(ii),--: out std_logic;
                output_fifo_data_out       => fifo_data_out(ii),
                output_fifo_data_out_valid => fifo_data_out_valid(ii)
            );
        --
        inst_gain_thing : entity work.gain_thing
            generic map(
                INPUT_DATA_WIDTH  => DAC_DATA_WIDTH,
                GAIN_DATA_WIDTH   => CONTROLREG_GAIN_DATA_WIDTH,
                OUTPUT_DATA_WIDTH => DAC_DATA_WIDTH
            )
            port map(
                clk               => m_axis_aclk,
                rstn              => m_axis_aresetn,
                --
                input_data        => fifo_data_out(ii),
                input_data_valid  => fifo_data_out_valid(ii),
                gain_data         => controlreg_gain,
                output_data       => fifo_data_with_gain_out(ii),
                output_data_valid => fifo_data_with_gain_out_valid(ii)
            );
        --
        m_axis_tdata_o(DAC_DATA_WIDTH-1+(ii*DAC_DATA_WIDTH) downto (ii*DAC_DATA_WIDTH)) <= fifo_data_with_gain_out(ii);
    end generate;
    m_axis_tvalid_o <= fifo_data_with_gain_out_valid(0);

end rtl;