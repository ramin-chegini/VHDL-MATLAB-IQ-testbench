# VHDL and MATLAB I/Q File Testbench

Exchange signed integer I/Q samples between MATLAB scripts and a VHDL simulation using plain text files. The example testbench connects a file reader directly to a file writer; a design under test (DUT) can be inserted between them.

The VHDL file I/O and testbench are for simulation only and are not synthesizable hardware. MATLAB is used before and after simulation; this project does not provide live MATLAB/VHDL co-simulation.

## Repository contents

```text
VHDL/
    File_reader.vhd          Read I/Q pairs and produce packed valid samples.
    File_writer.vhd          Write packed valid samples as I/Q pairs.
    tb_reader_writer.vhd     Connect the reader to the writer.
    input_data.txt           Example input containing two complex samples.
Matlab/
    Write_complex_to_txt.m   Export a complex row vector as rounded integers.
    Read_complex_from_txt.m  Import I/Q pairs, display them, and plot I against Q.
ReadMe.md
```

Use the exact filename capitalization above on case-sensitive systems. The MATLAB files are scripts, not functions.

## Text format and sample bus

Each sample occupies two lines: the real component I first, followed by the imaginary component Q. Use a single decimal integer per line, with no header, separators, or blank lines.

```text
100
-50
200
-25
```

This represents the MATLAB row vector `[100 - 50i, 200 - 25i]`.

The VHDL bus has `2 * DATA_WIDTH` bits:

| Bus slice | Component | Encoding |
| --- | --- | --- |
| `tdata(2*DATA_WIDTH-1 downto DATA_WIDTH)` | Q | Signed two's complement |
| `tdata(DATA_WIDTH-1 downto 0)` | I | Signed two's complement |

For a component width of `W`, keep each integer in the range `-2^(W-1)` through `2^(W-1)-1`. The supplied testbench uses 16 bits per component, so the range is -32768 through 32767. VHDL text conversion also relies on the simulator's `integer` range. The scripts and VHDL modules do not provide automatic scaling or saturation.

## Prepare a local workflow

You need MATLAB and a VHDL simulator that supports `std.textio`, `ieee.numeric_std`, and `ieee.std_logic_textio`. No simulator project or automated run script is included.

The supplied paths are examples from the original environment and must be adjusted before use:

| Location | Current path | Purpose |
| --- | --- | --- |
| `Matlab/Write_complex_to_txt.m` | `./complex_output.txt` | MATLAB export destination |
| `Matlab/Read_complex_from_txt.m` | `./complex_output.txt` | MATLAB import source |
| Testbench reader `FILENAME` | `D:/Git5/input_data.txt` | Input used by the instantiated reader |
| Testbench writer `FILENAME` | `D:/Git5/output_data.txt` | Output used by the instantiated writer |
| Standalone reader default `FILENAME` | `D:\Git5\File_reader_writer\File_reader_writer.srcs\sim_1\new\data.txt` | Default when the reader generic is not overridden |
| Standalone writer default `FILENAME` | `D:/output_data.txt` | Default when the writer generic is not overridden |

For a consistent round trip, use the repository's `VHDL/input_data.txt` as the MATLAB export destination and testbench reader input, and `VHDL/output_data.txt` as the testbench writer output and MATLAB import source. Absolute paths avoid differences between MATLAB's current folder and the simulator's working directory. Create destination directories beforehand. Exporting to the tracked example input will overwrite its contents.

1. Edit `complex_signal` in `Matlab/Write_complex_to_txt.m` with a complex **row vector**. Set `filename` to the intended VHDL input file. The script rounds fractional components and overwrites that file.
2. Set the two `FILENAME` generic mappings in `VHDL/tb_reader_writer.vhd` to the input and output paths. Keep reader and writer `DATA_WIDTH` values equal; the testbench already maps both to one constant.
3. For a future simulation, compile `VHDL/File_reader.vhd` and `VHDL/File_writer.vhd` into the `work` library before `VHDL/tb_reader_writer.vhd`. Select `tb_reader_writer` as the simulation top level.
4. Set `filename` in `Matlab/Read_complex_from_txt.m` to the writer's output file when importing simulation results. Its default instead reads the MATLAB export file, which can be used independently of VHDL.

The two MATLAB scripts share workspace variable names, so importing samples replaces variables created during export. Keep a separate copy of the original vector if you want to compare results manually.

## VHDL behavior

### Reader

- `DATA_WIDTH` defaults to 23 in the standalone entity; the supplied testbench overrides it to 16.
- `INTERVAL` defaults to 10 and must be positive. The first read attempt occurs on the `INTERVAL`-th rising clock edge after reset is released, with subsequent attempts spaced by that interval.
- A complete I/Q pair updates the registered `tdata` output and asserts `tvalid` for one clock cycle. With `INTERVAL = 1`, consecutive valid samples can keep `tvalid` high on successive cycles.
- Between samples and after end of file, `tdata` retains its last value and `tvalid` is low. A final I value without a matching Q is consumed without producing a valid sample.
- The active-high asynchronous reset clears the output registers and interval counter. It does not rewind the input file, which opens at elaboration.

### Writer

- `DATA_WIDTH` defaults to 16. Each rising clock edge with `tvalid = '1'` writes I and then Q as decimal lines.
- The output file opens in `write_mode` at elaboration, creating or truncating it. Reset suppresses writes without clearing or reopening the file.
- There is no `tready` signal or backpressure. Any inserted DUT must provide correctly aligned output data and valid signals.

### Supplied loopback testbench

The clock period is 10 ns (100 MHz), reset is held for 30 ns, and the reader interval is 10 cycles (100 ns between pairs). Because reader outputs are registered, the writer consumes each pair on the following rising edge.

The clock runs for a fixed 2 ms rather than stopping at end of file. The testbench then waits without an explicit simulator-stop call; simulator completion behavior depends on the tool. Increase the clock duration for larger input files or additional DUT latency. This example has no automatic scoreboard or assertions that compare input and output.

## Scope of the documentation update

Source comments and this README describe the existing implementation. No tests, compilation, MATLAB execution, or VHDL simulation were performed for this documentation update; simulator compatibility and runtime behavior have not been verified by it.

