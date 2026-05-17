library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Library UNISIM;
use UNISIM.vcomponents.all;
Library xpm;
use xpm.vcomponents.all;

entity gain_thing is
    generic(
        INPUT_DATA_WIDTH  : positive;
        GAIN_DATA_WIDTH   : positive;
        OUTPUT_DATA_WIDTH : positive
    );
    port (
        clk               : in  std_logic;
        rstn              : in  std_logic;
        --
        input_data        : in  std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);
        input_data_valid  : in  std_logic;
        gain_data         : in  std_logic_vector(GAIN_DATA_WIDTH-1 downto 0);
        output_data       : out std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);
        output_data_valid : out std_logic
    );
end gain_thing;

architecture rtl of gain_thing is
    
    signal input_data_z : std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);

    signal input_data_r  : signed(INPUT_DATA_WIDTH-1 downto 0);
    signal input_data_rr : signed(INPUT_DATA_WIDTH-1 downto 0);
    signal gain_data_r   : signed(GAIN_DATA_WIDTH-1 downto 0);
    signal gain_data_rr  : signed(GAIN_DATA_WIDTH-1 downto 0);
    signal mult_data     : signed(INPUT_DATA_WIDTH+GAIN_DATA_WIDTH-1 downto 0);
    signal mult_data_r   : signed(INPUT_DATA_WIDTH+GAIN_DATA_WIDTH-1 downto 0);

    signal data_valid_r    : std_logic;
    signal data_valid_rr   : std_logic;
    signal data_valid_rrr  : std_logic;
    signal data_valid_rrrr : std_logic;

begin

    input_data_z <= input_data when (input_data_valid='1') else (others => '0');
    --
    process(clk)
    begin
        if(rising_edge(clk)) then
            input_data_r    <= signed(input_data_z);
            input_data_rr   <= input_data_r;
            gain_data_r     <= signed(gain_data);
            gain_data_rr    <= gain_data_r;
            --
            mult_data   <= input_data_rr*gain_data_rr;
            mult_data_r <= mult_data;
            --
            data_valid_r    <= input_data_valid;
            data_valid_rr   <= data_valid_r;
            data_valid_rrr  <= data_valid_rr;
            data_valid_rrrr <= data_valid_rrr;
            --
            output_data       <= std_logic_vector(mult_data_r(30 downto 15));
            output_data_valid <= data_valid_rrrr;
            --
            if(rstn='0') then
                data_valid_r    <= '0';
                data_valid_rr   <= '0';
                data_valid_rrr  <= '0';
                data_valid_rrrr <= '0';
            end if;
        end if;
    end process;

end rtl;