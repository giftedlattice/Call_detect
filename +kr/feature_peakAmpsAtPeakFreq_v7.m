function amps = feature_peakAmpsAtPeakFreq_v7(segR, segL, segRR, fs, opts, fPeak_kHz)
%FEATURE_PEAKAMPSATPEAKFREQ_V7 PSD value at rear peak frequency for each channel.
% Robust to NaN-filled channels: returns NaN if channel has no finite samples.

harmBand_Hz = opts.harmBand_kHz * 1000;

amps = struct('rear',NaN,'left',NaN,'right',NaN);

% Rear should exist
if any(isfinite(segR))
    amps.rear = kr.ampAtFreqFromPSD(segR, fs, harmBand_Hz, fPeak_kHz);
end

if any(isfinite(segL))
    amps.left = kr.ampAtFreqFromPSD(segL, fs, harmBand_Hz, fPeak_kHz);
end

if any(isfinite(segRR))
    amps.right = kr.ampAtFreqFromPSD(segRR, fs, harmBand_Hz, fPeak_kHz);
end
end