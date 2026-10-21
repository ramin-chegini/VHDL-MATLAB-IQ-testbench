-- Simulation-only source: read signed decimal I/Q pairs, one component per line.
-- Pack each complete pair with Q in the upper half and I in the lower half.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity file_reader is
    generic (
        FILENAME    : string := "D:\Git5\File_reader_writer\File_reader_writer.srcs\sim_1\new\data.txt"; -- Override for the local input file.
        DATA_WIDTH  : integer := 23; -- Signed bit width of each component.
        INTERVAL    : integer := 10  -- Positive number of clock cycles per read attempt.
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        tdata   : out std_logic_vector(2*DATA_WIDTH-1 downto 0); -- Q (MSBs) & I (LSBs)
        tvalid  : out std_logic -- Marks each complete pair; sampled on clock edges.
    );
end entity;

architecture behavioral of file_reader is

    -- Opened at elaboration; resetting the signals does not rewind the file.
    file data_file : text open read_mode is FILENAME;
    signal tdata_reg   : std_logic_vector(2*DATA_WIDTH-1 downto 0) := (others => '0');
    signal tvalid_reg  : std_logic := '0';
    signal clk_counter : integer := 0;

begin

    process(clk, rst)
        variable linebuf   : line;
        variable read_int_i : integer;
        variable read_int_q : integer;

    begin
        -- Active-high asynchronous reset restarts the interval counter.
        if rst = '1' then
            tdata_reg   <= (others => '0');
            tvalid_reg  <= '0';
            clk_counter <= 0;

        elsif rising_edge(clk) then
            -- The first read occurs on the INTERVAL-th rising edge after reset.
            if clk_counter = INTERVAL - 1 then
                clk_counter <= 0;

                if not endfile(data_file) then
                    -- Odd-numbered lines (1, 3, ...) contain the real component I.
                    readline(data_file, linebuf);
                    read(linebuf, read_int_i);

                    if not endfile(data_file) then
                        -- Even-numbered lines (2, 4, ...) contain the imaginary component Q.
                        readline(data_file, linebuf);
                        read(linebuf, read_int_q);

                        -- Input integers must fit the signed DATA_WIDTH-bit range.
                        -- Publish a sample only after both components have been read.
                        tdata_reg <= std_logic_vector(to_signed(read_int_q, DATA_WIDTH)) &
                                     std_logic_vector(to_signed(read_int_i, DATA_WIDTH));
                        tvalid_reg <= '1';
                    else
                        tvalid_reg <= '0'; -- Discard a trailing I without a matching Q.
                    end if;
                else
                    tvalid_reg <= '0'; -- End of file: retain the last tdata without valid.
                end if;

            else
                clk_counter <= clk_counter + 1;
                tvalid_reg  <= '0'; -- Between read attempts, retain the last tdata.
            end if;
        end if;
    end process;

    tdata  <= tdata_reg;
    tvalid <= tvalid_reg;

end architecture;
