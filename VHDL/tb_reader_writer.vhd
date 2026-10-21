-- Simulation-only loopback: file_reader drives file_writer without a DUT.
-- Set both file paths below before running in a local simulator.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_reader_writer is
end entity;

architecture test of tb_reader_writer is

    constant CLK_PERIOD : time := 10 ns; -- 100 MHz clock.
    constant DATA_WIDTH : integer := 16; -- Signed bit width of each I/Q component.

    signal clk     : std_logic := '0';
    signal rst     : std_logic := '1';

    -- Shared sample bus: Q in the upper half, I in the lower half.
    -- There is no ready/backpressure signal; the writer accepts every valid sample.
    signal tdata   : std_logic_vector(2*DATA_WIDTH-1 downto 0);
    signal tvalid  : std_logic;

begin

    -- Generate the clock for a fixed 2 ms, independently of input-file length.
    clk_process : process
    begin
        while now < 2 ms loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait; -- Stop clock activity; no explicit simulator-stop call is made.
    end process;

    -- Hold the asynchronous active-high reset for the initial 30 ns.
    rst_process : process
    begin
        rst <= '1';
        wait for 30 ns;
        rst <= '0';
        wait;
    end process;

    -- Read one I/Q pair every 10 rising edges after reset (100 ns per pair).
    reader_inst : entity work.file_reader
        generic map (
            FILENAME    => "D:/Git5/input_data.txt", -- Replace with the input file path.
            DATA_WIDTH  => DATA_WIDTH,
            INTERVAL    => 10
        )
        port map (
            clk     => clk,
            rst     => rst,
            tdata   => tdata,
            tvalid  => tvalid
        );

    -- The writer sees the reader's registered outputs on the next rising edge.
    -- Insert a DUT here by connecting its output data and valid to the writer.
    writer_inst : entity work.file_writer
        generic map (
            FILENAME    => "D:/Git5/output_data.txt", -- Replace with the output file path.
            DATA_WIDTH  => DATA_WIDTH
        )
        port map (
            clk     => clk,
            rst     => rst,
            tdata   => tdata,
            tvalid  => tvalid
        );

end architecture;
