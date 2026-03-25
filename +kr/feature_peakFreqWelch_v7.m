function peakFreq_kHz = feature_peakFreqWelch_v7(x, fs, opts)
%FEATURE_PEAKFREQWELCH_V7 Peak frequency from Welch PSD in first harmonic band.

harmBand_Hz = opts.harmBand_kHz * 1000;
[F_kHz, P] = kr.pwelchBand(x, fs, harmBand_Hz);
if isempty(F_kHz)
    peakFreq_kHz = NaN;
    return;
end
[~, iMax] = max(P);
peakFreq_kHz = F_kHz(iMax);
end