function [fStart_kHz, fEnd_kHz, fMin_kHz, fMax_kHz] = ridgeStartEndFreqFromSpec(x, fs, opts)
%RIDGESTARTENDFREQFROMSPEC Estimate start/end/min/max ridge frequency (kHz)
% within opts.harmBand_kHz using a spectrogram ridge.
%
% - fStart/fEnd are time-ordered (first/last "active" ridge bins).
% - fMin/fMax are min/max over active ridge bins (for bandwidth).

x = double(x(:));
if numel(x) < 32
    fStart_kHz = NaN; fEnd_kHz = NaN; fMin_kHz = NaN; fMax_kHz = NaN;
    return;
end

win  = min(opts.specWin, numel(x));
ovl  = min(opts.specOvl, win-1);
nfft = max(opts.specNfft, 2^nextpow2(win));

[S,F,~] = spectrogram(x, win, ovl, nfft, fs, 'yaxis');
SdB = 20*log10(abs(S)+eps);
FkHz = F/1000;

band = (FkHz >= opts.harmBand_kHz(1)) & (FkHz <= opts.harmBand_kHz(2));
if ~any(band)
    fStart_kHz = NaN; fEnd_kHz = NaN; fMin_kHz = NaN; fMax_kHz = NaN;
    return;
end

Sb = SdB(band,:);
Fb = FkHz(band);

% Ridge: per time-bin peak frequency and its power
[pCol, iCol] = max(Sb, [], 1);
fRidge = Fb(iCol);

% Active bins: within 12 dB of max ridge power
pMax = max(pCol);
active = pCol >= (pMax - 12);

% If too strict, fall back to all bins
if ~any(active)
    active = true(size(pCol));
end

idx = find(active);
fStart_kHz = fRidge(idx(1));
fEnd_kHz   = fRidge(idx(end));

fMin_kHz = min(fRidge(active));
fMax_kHz = max(fRidge(active));
end