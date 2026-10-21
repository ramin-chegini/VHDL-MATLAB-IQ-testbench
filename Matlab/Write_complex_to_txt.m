% WRITE_COMPLEX_TO_TXT Export a complex row vector as decimal I/Q line pairs.
% This script writes I0, Q0, I1, Q1, ... with one rounded integer per line.
% Keep values within the signed DATA_WIDTH-bit range configured in VHDL.

% Replace this example row vector with the samples to send to the VHDL reader.
complex_signal = [100 - 50i, 200 - 25i, 300 + 75i];

% Relative paths resolve from MATLAB's current folder, not this script's folder.
% Point the VHDL reader at this same file. An existing file will be overwritten.
filename = './complex_output.txt';

% Split the real (in-phase) and imaginary (quadrature) components.
I = real(complex_signal);
Q = imag(complex_signal);

% Column-major reshape alternates the rows of [I; Q]: I0, Q0, I1, Q1, ...
interleaved = reshape([I; Q], [], 1);


% Open a text stream and fail clearly if the destination cannot be opened.
fid = fopen(filename, 'w');
if fid == -1
    error('Could not open file for writing.');
end

% Round fractional components to integers; no scaling or saturation is applied.
for k = 1:length(interleaved)
    fprintf(fid, '%d\n', round(interleaved(k)));
end

fclose(fid); % Close the stream so the complete file is available to the reader.

disp(['Wrote ', num2str(length(interleaved)), ' lines to file.']);
