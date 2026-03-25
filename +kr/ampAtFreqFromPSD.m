function amp = ampAtFreqFromPSD(x, fs, bandHz, fTarget_kHz)
% PSD value (linear) at fTarget_kHz by interpolating within the band.
[F_kHz, P] = kr.pwelchBand(x, fs, bandHz);
if isempty(F_kHz)
    amp = NaN;
    return;
end
amp = interp1(F_kHz, P, fTarget_kHz, 'linear', 'extrap');
end