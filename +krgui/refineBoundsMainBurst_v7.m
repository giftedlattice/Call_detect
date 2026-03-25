function [on2, off2] = refineBoundsMainBurst_v7(env_dB, fs, on1, off1, opts)
%REFINEBOUNDSMAINBURST_V7 Refine bounds to the MAIN burst, trimming echo tail.
% Uses envelope (dB), peak-relative thresholds, and a quiet-hold rule.
%
% on1/off1: candidate bounds (samples)
% on2/off2: refined bounds (samples), inclusive off2

N = numel(env_dB);

on1  = max(1, min(N, round(on1)));
off1 = max(1, min(N, round(off1)));
if off1 < on1
    tmp = on1; on1 = off1; off1 = tmp;
end

padS = max(0, round((opts.boundRefine_pad_ms/1000) * fs));
a = max(1, on1 - padS);
b = min(N, off1 + padS);

seg = env_dB(a:b);
if isempty(seg)
    on2 = on1; off2 = off1;
    return;
end

% Main peak within the padded window
[peak_dB, iPk] = max(seg);
pkS = a + iPk - 1;

% Thresholds relative to peak
thrEnd  = peak_dB - opts.boundRefine_dropFromPeak_dB;
thrOn   = peak_dB - opts.boundRefine_startDrop_dB;

quietS = max(1, round((opts.boundRefine_quiet_ms/1000) * fs));

% --------------------
% Refine START: walk left from peak to find onset crossing
% --------------------
on2 = on1;
j = pkS;
while j > a && env_dB(j) > thrOn
    j = j - 1;
end
% move forward to first above thrOn
while j < pkS && env_dB(j) <= thrOn
    j = j + 1;
end
on2 = max(on1, j); % never earlier than candidate start

% --------------------
% Refine END: walk right from peak; end when it stays quiet
% --------------------
off2 = off1;
j = pkS;

% first, move right until we drop below thrEnd
while j < b && env_dB(j) > thrEnd
    j = j + 1;
end

% now require "quiet hold" below thrEnd to confirm main burst ended
found = false;
while (j + quietS - 1) <= b
    if all(env_dB(j:(j+quietS-1)) <= thrEnd)
        found = true;
        break;
    end
    j = j + 1;
end

if found
    % inclusive end is last sample above threshold before quiet window
    off2 = max(on2, j - 1);
else
    % fallback: keep candidate off if we never found a stable quiet region
    off2 = off1;
end

% Final clamps
on2  = max(1, min(N, on2));
off2 = max(1, min(N, off2));
if off2 < on2
    off2 = on2;
end
end