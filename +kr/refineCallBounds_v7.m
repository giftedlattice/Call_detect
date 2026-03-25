function [on2, off2] = refineCallBounds_v7(env_dB, fs, on1, off1, noiseFloor_dB, thrAboveNoise_dB, opts)
%REFINECALLBOUNDS_V7 Refine a single call's on/off based on envelope + noise stats.
% Uses hysteresis + peak-relative threshold + end-hold stability.
%
% env_dB: full envelope in dB (rear)
% on1/off1: initial bounds (samples)
%
% Returns refined on2/off2 (samples). Safe-clamped.

N = numel(env_dB);
on1  = max(1, min(N, round(on1)));
off1 = max(1, min(N, round(off1)));
if off1 < on1
    tmp = on1; on1 = off1; off1 = tmp;
end

% thresholds
thrHi = noiseFloor_dB + thrAboveNoise_dB;
thrLo = noiseFloor_dB + max(0, thrAboveNoise_dB - opts.refineHysteresis_dB);

% search window around initial bounds
padS = max(0, round((opts.refinePad_ms/1000)*fs));
a = max(1, on1 - padS);
b = min(N, off1 + padS);

seg = env_dB(a:b);
if isempty(seg)
    on2 = on1; off2 = off1;
    return;
end

% local peak within candidate
peak_dB = max(seg);
thrRel  = peak_dB - opts.refinePeakDrop_dB;

thrUse = max(thrLo, thrRel);

% --- refine ON: find last sample below threshold before the "main energy"
% Start from initial on1, walk backward until below thrUse
on2 = on1;
while on2 > a && env_dB(on2) > thrUse
    on2 = on2 - 1;
end
% move forward to first above threshold (so onset is on first above)
while on2 < off1 && env_dB(on2) <= thrUse
    on2 = on2 + 1;
end

% --- refine OFF with end-hold: need consecutive below-thr samples
holdS = max(1, round((opts.refineEndHold_ms/1000)*fs));

off2 = off1;
% move forward while above threshold
while off2 < b && env_dB(off2) > thrUse
    off2 = off2 + 1;
end
% now enforce "hold below" criterion:
% find first index where there are holdS samples below thrUse
j = off2;
while j + holdS - 1 <= b
    if all(env_dB(j:(j+holdS-1)) <= thrUse)
        off2 = j; % boundary at first stable-below position
        break;
    end
    j = j + 1;
end
% move back to last above-threshold sample if you prefer inclusive "last in-call sample"
% Here we keep off2 as the first stable-below sample; UI can interpret it consistently.
% If you want inclusive last in-call sample:
off2 = max(on2, off2 - 1);

% clamp
on2 = max(1, min(N, on2));
off2 = max(1, min(N, off2));
if off2 < on2
    off2 = on2;
end
end