function [F_kHz, P] = pwelchBand(x, fs, bandHz)
% Returns frequency vector (kHz) and PSD (linear power) within bandHz.
% Robust to short segments.

x = double(x(:));
N = numel(x);

% Need enough samples to compute a meaningful PSD
if N < 32
    F_kHz = []; P = [];
    return;
end

% Choose a window that never exceeds the segment length
win = min(512, max(32, 2^floor(log2(N))));
win = min(win, N);

% Overlap must be < win
ovl = floor(0.75*win);
ovl = min(ovl, win-1);

% nfft >= win
nfft = max(256, 2^nextpow2(win));

[Pxx,F] = pwelch(x, win, ovl, nfft, fs);

idx = (F >= bandHz(1)) & (F <= bandHz(2));
F_kHz = F(idx)/1000;
P = Pxx(idx);
end