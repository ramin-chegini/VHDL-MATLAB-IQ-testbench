% READ_COMPLEX_FROM_TXT Reconstruct a complex row vector from decimal I/Q pairs.
% Expected layout: I0, Q0, I1, Q1, ... with one integer on each line.

% Relative paths resolve from MATLAB's current folder. For the VHDL round trip,
% change this path to the file produced by file_writer.
filename = './complex_output.txt';

% Load a headerless, single-column numeric text file.
data = dlmread(filename);

% Each complex sample requires two values; reject an unmatched component.
if mod(length(data), 2) ~= 0
    error('The input file must contain an even number of lines (I/Q pairs).');
end

% Column-major reshape places each consecutive I/Q pair in a separate column.
data_reshaped = reshape(data, 2, []);

% MATLAB line numbering starts at 1: I is on odd lines, Q is on even lines.
I = data_reshaped(1, :);  % Lines 1, 3, 5, ...
Q = data_reshaped(2, :);  % Lines 2, 4, 6, ...

% Reconstruct the complex row vector without normalization or rescaling.
complex_signal = complex(I, Q);  % I + j*Q

% Display the reconstructed samples in the command window.
disp('Complex signal:');
disp(complex_signal);

% Plot I against Q. Connecting lines show the sample order in the input file.
figure;
plot(real(complex_signal), imag(complex_signal), 'o-');
xlabel('In-phase (I)');
ylabel('Quadrature (Q)');
title('Constellation Diagram');
grid on;
