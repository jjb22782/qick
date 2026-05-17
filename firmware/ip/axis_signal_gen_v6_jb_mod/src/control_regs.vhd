--Format of waveform interface:
-- |------------|-------|---------|------|------------|------------|------------|-----------|----------|----------|----------|---------|
-- | 159 .. 149 |   148 |     147 |  146 | 145 .. 144 | 143 .. 128 | 127 .. 112 | 111 .. 96 | 95 .. 80 | 79 .. 64 | 63 .. 32 | 31 .. 0 |
-- |------------|-------|---------|------|------------|------------|------------|-----------|----------|----------|----------|---------|
-- |       xxxx | phrst | stdysel | mode |     outsel |      nsamp |       xxxx |      gain |     xxxx |     addr |    phase |    freq |
-- |------------|-------|---------|------|------------|------------|------------|-----------|----------|----------|----------|---------|
-- freq 	: 32 bits
-- phase 	: 32 bits
-- addr 	: 16 bits
-- gain 	: 16 bits
-- nsamp 	: 16 bits
-- outsel 	: 2 bits
-- mode 	: 1 bit
-- stdysel 	: 1 bit
-- phrst	: 1 bit

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_regs is
    generic(
        FIFO_DATA_WIDTH                   : positive := 160;
        CONTROLREG_NUM_SAMPLES_DATA_WIDTH : positive := 16;
        CONTROLREG_GAIN_DATA_WIDTH        : positive := 16
    );
    port (
        rstn                    : in  std_logic;
        clk                     : in  std_logic;
        -- AXIS Slave to load memory samples.
        rd_en                   : out std_logic;
        empty                   : in  std_logic;
        dout                    : in  std_logic_vector(FIFO_DATA_WIDTH-1 downto 0);
        -- M_AXIS for output.
        controlreg_num_samples : out std_logic_vector(CONTROLREG_NUM_SAMPLES_DATA_WIDTH-1 downto 0);
        controlreg_gain        : out std_logic_vector(CONTROLREG_GAIN_DATA_WIDTH-1 downto 0);
        controlreg_start_bit   : out std_logic
    );
end control_regs;

architecture rtl of control_regs is

    type t_state is (INIT, READ_EN, WAIT1, WAIT2, WAIT3, WAIT4, WAIT5, WAIT6);
    signal state : t_state;

begin

    -- WAIT STATES EXIST BECAUSE FOR XPM_CDC_PULSE:
    -- "For proper operation, the input data must be sampled two or more times by the destination clock."
    -- PERHAPS THE NUMBER OF WAIT STATES IS OVERKILL... BUT BETTER SAFE THAN SORRY?
    process(clk)
    begin
        if(rising_edge(clk)) then
            case(state) is
                when INIT =>
                    state                  <= READ_EN;
                    controlreg_start_bit   <= '0';
                    rd_en                  <= '0';
                --
                when READ_EN =>
                    controlreg_start_bit <= '0';
                    if(empty = '0') then
                        state <= WAIT1;
                        rd_en <= '1';
                    end if;
                --
                when WAIT1 =>
                    state <= WAIT2;
                    rd_en <= '0';
                --
                when WAIT2 =>
                    controlreg_num_samples <= dout(143 downto 128);
                    controlreg_gain        <= dout(111 downto 96);
                    controlreg_start_bit   <= '1';
                    state                  <= WAIT3;
                --
                when WAIT3 =>
                    state <= WAIT4;
                --
                when WAIT4 =>
                    state <= WAIT5;
                --
                when WAIT5 =>
                    state <= WAIT6;
                --
                when WAIT6 => 
                    state <= READ_EN;
                --
                when others => null;
            end case;
            -- RESET
            if(rstn='0') then
                state <= INIT;
            end if;
        end if;    
    end process;

end rtl;