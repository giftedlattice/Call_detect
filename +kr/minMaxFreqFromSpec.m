function [fMin_kHz, fMax_kHz] = minMaxFreqFromSpec(x, fs, opts)
% Min/max frequency from spectrogram ridge within first harmonic.
% Uses opts.specWin/specOvl/specNfft and opts.harmBand_kHz.

x = double(x(:));
if numel(x) < 32
    fMin_kHz = NaN; 
    fMax_kHz = NaN;
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
    fMin_kHz = NaN; 
    fMax_kHz = NaN;
    return;
end

Sb = SdB(band,:);
Fb = FkHz(band);

[pCol, iCol] = max(Sb, [], 1);
fRidge = Fb(iCol);

pMax = max(pCol);
keep = pCol >= (pMax - 12); % dB-down threshold
if ~any(keep)
    keep = true(size(pCol));
end

fMin_kHz = min(fRidge(keep));
fMax_kHz = max(fRidge(keep));
end