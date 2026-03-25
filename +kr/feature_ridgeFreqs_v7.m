function out = feature_ridgeFreqs_v7(x, fs, opts)
%FEATURE_RIDGEFREQS_V7 Ridge-based frequency features in first harmonic band.
%
% Returns struct:
%   start_kHz, end_kHz, min_kHz, max_kHz
%
% Main output convention:
%   start_kHz = ridge frequency at the FIRST spectrogram time bin
%   end_kHz   = ridge frequency at the LAST spectrogram time bin
%
% Bandwidth support:
%   min_kHz / max_kHz are computed across active ridge bins only

out = struct( ...
    'start_kHz', NaN, ...
    'end_kHz',   NaN, ...
    'min_kHz',   NaN, ...
    'max_kHz',   NaN);

x = double(x(:));
if numel(x) < 32
    return;
end

% Default if not provided
if ~isfield(opts,'ridgeActiveDrop_dB')
    opts.ridgeActiveDrop_dB = 12;
end

win  = min(opts.specWin, numel(x));
ovl  = min(opts.specOvl, win-1);
nfft = max(opts.specNfft, 2^nextpow2(win));

[S,F,~] = spectrogram(x, win, ovl, nfft, fs, 'yaxis');
SdB = 20*log10(abs(S) + eps);
FkHz = F / 1000;

band = (FkHz >= opts.harmBand_kHz(1)) & (FkHz <= opts.harmBand_kHz(2));
if ~any(band)
    return;
end

Sb = SdB(band, :);
Fb = FkHz(band);

if isempty(Sb) || size(Sb,2) < 1
    return;
end

% Ridge frequency in each spectrogram time column
[pCol, iCol] = max(Sb, [], 1);
fRidge = Fb(iCol);

% Main outputs:
% use first and last spectrogram columns of the detected call
out.start_kHz = fRidge(1);
out.end_kHz   = fRidge(end);

% Active bins for min/max ridge span
pMax = max(pCol);
active = pCol >= (pMax - opts.ridgeActiveDrop_dB);
if ~any(active)
    active = true(size(pCol));
end

out.min_kHz = min(fRidge(active));
out.max_kHz = max(fRidge(active));
end