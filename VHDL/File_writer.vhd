-- Simulation-only sink: write each valid packed sample as decimal I, then Q.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity file_writer is
    generic (
        FILENAME    : string := "D:/output_data.txt"; -- Override for the local output file.
        DATA_WIDTH  : integer := 16 -- Signed bit width of each component.
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        tdata   : in  std_logic_vector(2*DATA_WIDTH-1 downto 0); -- Q (MSB) & I (LSB)
        tvalid  : in  std_logic -- Write on every rising edge for which this is high.
    );
end entity;

architecture behavioral of file_writer is

    -- Opening in write_mode at elaboration creates or truncates the output file.
    file out_file : text open write_mode is FILENAME;
    
begin

    process(clk, rst)
        variable outline  : line;
        variable int_i    : integer;
        variable int_q    : integer;
        variable signed_i : signed(DATA_WIDTH-1 downto 0);
        variable signed_q : signed(DATA_WIDTH-1 downto 0);
    begin
        if rst = '1' then
            -- Active-high reset suppresses writes; it does not clear or reopen the file.
        elsif rising_edge(clk) then
            if tvalid = '1' then
                -- Decode each half of the bus as a two's-complement signed value.
                signed_q := signed(tdata(2*DATA_WIDTH-1 downto DATA_WIDTH));
                signed_i := signed(tdata(DATA_WIDTH-1 downto 0));

                int_q := to_integer(signed_q);
                int_i := to_integer(signed_i);

                -- Write I on the first line of this pair.
                write(outline, int_i);
                writeline(out_file, outline);

                -- Write Q on the second line; writeline flushes the line buffer.
                write(outline, int_q);
                writeline(out_file, outline);
            end if;
        end if;
    end process;

end architecture;
