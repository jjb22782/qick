library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Library UNISIM;
use UNISIM.vcomponents.all;
Library xpm;
use xpm.vcomponents.all;

entity fifo_thing is
    generic(
        INPUT_DATA_WIDTH        : positive;
        INTERMEDIATE_DATA_WIDTH : positive;
        OUTPUT_DATA_WIDTH       : positive;
        FIFO_DEPTH              : positive
    );
    port (
        -- INPUT CONTROL
        clk_input_fifo             : in  std_logic;
        rst_input_fifo             : in  std_logic;
        input_fifo_data_in         : in  std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);
        input_fifo_write_en        : in  std_logic;
        -- INTERMEDIATE CONTROL
        clk_output_fifo_d2         : in  std_logic;
        intermediate_fifo_read_en  : in  std_logic;
        soft_reset                 : in  std_logic;
        -- OUTPUT CONTROL
        clk_output_fifo            : in  std_logic;
        rst_output_fifo            : in  std_logic;
        output_fifo_read_en        : in  std_logic;
        output_fifo_empty          : out std_logic;
        output_fifo_data_out       : out std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);
        output_fifo_data_out_valid : out std_logic
    );
end fifo_thing;

architecture rtl of fifo_thing is

    signal input_fifo_empty          : std_logic;
    signal input_fifo_read_en        : std_logic;
    signal input_fifo_data_out       : std_logic_vector(INTERMEDIATE_DATA_WIDTH-1 downto 0);
    signal input_fifo_data_out_valid : std_logic;
    --
    signal rst_output_fifo_r : std_logic;
    signal intermediate_fifo_rst : std_logic;
    signal intermediate_fifo_data_in       : std_logic_vector(INTERMEDIATE_DATA_WIDTH-1 downto 0);
    signal intermediate_fifo_write_en : std_logic;
    signal intermediate_fifo_data_out       : std_logic_vector(INTERMEDIATE_DATA_WIDTH-1 downto 0);
    signal intermediate_fifo_data_out_valid : std_logic;
    --
    signal output_fifo_data_in  : std_logic_vector(INTERMEDIATE_DATA_WIDTH-1 downto 0);
    signal output_fifo_write_en : std_logic;
    --
    signal rst_output_fifo_r2 : std_logic;
    signal rst_output_fifo_rr : std_logic;

begin

    ----------------
    -- INPUT FIFO --
    ----------------
    input_fifo : xpm_fifo_async
    generic map (
        FIFO_MEMORY_TYPE  => "auto", -- String
        FIFO_READ_LATENCY => 2, -- DECIMAL
        FIFO_WRITE_DEPTH  => 32, -- DECIMAL
        READ_DATA_WIDTH   => INTERMEDIATE_DATA_WIDTH, -- DECIMAL
        READ_MODE         => "std", -- String
        USE_ADV_FEATURES  => "1000", -- String
        WRITE_DATA_WIDTH  => INPUT_DATA_WIDTH -- DECIMAL
    )
    port map (
        almost_empty  => open,
        almost_full   => open,
        data_valid    => input_fifo_data_out_valid,
        dbiterr       => open,
        dout          => input_fifo_data_out, 
        empty         => input_fifo_empty,
        full          => open,
        overflow      => open,
        prog_empty    => open,
        prog_full     => open,
        rd_data_count => open,
        rd_rst_busy   => open,
        sbiterr       => open,
        underflow     => open,
        wr_ack        => open,
        wr_data_count => open,
        wr_rst_busy   => open,
        din           => input_fifo_data_in,
        injectdbiterr => '0',
        injectsbiterr => '0',
        rd_clk        => clk_output_fifo_d2,
        rd_en         => input_fifo_read_en,
        rst           => rst_input_fifo, -- 1-bit input: Reset: Must be synchronous to wr_clk.
        sleep         => '0',
        wr_clk        => clk_input_fifo,
        wr_en         => input_fifo_write_en
    );
    input_fifo_read_en <= not input_fifo_empty;

    ---------
    -- MUX --
    ---------
    process(clk_output_fifo_d2)
    begin
        if(rising_edge(clk_output_fifo_d2)) then
            if(input_fifo_data_out_valid='1') then
                intermediate_fifo_data_in <= input_fifo_data_out;
            else
                intermediate_fifo_data_in <= intermediate_fifo_data_out;
            end if;
            intermediate_fifo_write_en <= input_fifo_data_out_valid or intermediate_fifo_data_out_valid;
        end if;
    end process;

    ----------------------
    -- BULK OF THE FIFO --
    ----------------------
    process(clk_output_fifo_d2)
    begin
        if(rising_edge(clk_output_fifo_d2)) then
            rst_output_fifo_r     <= rst_output_fifo or soft_reset;
            intermediate_fifo_rst <= rst_output_fifo_r;
        end if;
    end process;
    --
    intermediate_fifo : xpm_fifo_async
    generic map (
        FIFO_MEMORY_TYPE  => "auto", -- String
        FIFO_READ_LATENCY => 16, -- DECIMAL
        FIFO_WRITE_DEPTH  => FIFO_DEPTH, -- DECIMAL
        READ_DATA_WIDTH   => INTERMEDIATE_DATA_WIDTH, -- DECIMAL
        READ_MODE         => "std", -- String
        USE_ADV_FEATURES  => "1000", -- String
        WRITE_DATA_WIDTH  => INTERMEDIATE_DATA_WIDTH -- DECIMAL
    )
    port map (
        almost_empty  => open,
        almost_full   => open,
        data_valid    => intermediate_fifo_data_out_valid,
        dbiterr       => open,
        dout          => intermediate_fifo_data_out, 
        empty         => open,
        full          => open,
        overflow      => open,
        prog_empty    => open,
        prog_full     => open,
        rd_data_count => open,
        rd_rst_busy   => open,
        sbiterr       => open,
        underflow     => open,
        wr_ack        => open,
        wr_data_count => open,
        wr_rst_busy   => open,
        din           => intermediate_fifo_data_in,
        injectdbiterr => '0',
        injectsbiterr => '0',
        rd_clk        => clk_output_fifo_d2,
        rd_en         => intermediate_fifo_read_en,
        rst           => intermediate_fifo_rst, -- 1-bit input: Reset: Must be synchronous to wr_clk.
        sleep         => '0',
        wr_clk        => clk_output_fifo_d2,
        wr_en         => intermediate_fifo_write_en
    );

    ------------------
    -- INTERMEDIATE --
    ------------------
    process(clk_output_fifo_d2)
    begin
        if(rising_edge(clk_output_fifo_d2)) then
            output_fifo_data_in  <= intermediate_fifo_data_out;
            output_fifo_write_en <= intermediate_fifo_data_out_valid;
        end if;
    end process;

    -----------------
    -- OUTPUT FIFO -- MOSTLY A DATA WIDTH AND RATE CONVERTER
    -----------------
    process(clk_output_fifo_d2)
    begin
        if(rising_edge(clk_output_fifo_d2)) then
            rst_output_fifo_r2 <= rst_output_fifo;
            rst_output_fifo_rr <= rst_output_fifo_r2;
        end if;
    end process;
    output_fifo : xpm_fifo_async
    generic map (
        FIFO_MEMORY_TYPE  => "auto", -- String
        FIFO_READ_LATENCY => 2, -- DECIMAL
        FIFO_WRITE_DEPTH  => 16, -- DECIMAL
        READ_DATA_WIDTH   => OUTPUT_DATA_WIDTH, -- DECIMAL
        READ_MODE         => "std", -- String
        USE_ADV_FEATURES  => "1000", -- String
        WRITE_DATA_WIDTH  => INTERMEDIATE_DATA_WIDTH -- DECIMAL
    )
    port map (
        almost_empty  => open,
        almost_full   => open,
        data_valid    => output_fifo_data_out_valid,
        dbiterr       => open,
        dout          => output_fifo_data_out,
        empty         => output_fifo_empty,
        full          => open,
        overflow      => open,
        prog_empty    => open,
        prog_full     => open,
        rd_data_count => open,
        rd_rst_busy   => open,
        sbiterr       => open,
        underflow     => open,
        wr_ack        => open,
        wr_data_count => open,
        wr_rst_busy   => open,
        din           => output_fifo_data_in,
        injectdbiterr => '0',
        injectsbiterr => '0',
        rd_clk        => clk_output_fifo,
        rd_en         => output_fifo_read_en,
        rst           => rst_output_fifo_rr,
        sleep         => '0',
        wr_clk        => clk_output_fifo_d2,
        wr_en         => output_fifo_write_en
    );

end rtl;