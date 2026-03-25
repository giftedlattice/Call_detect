function [onS, offS] = detectCalls_dB(env_dB, fs, noiseFloor_dB, thrAboveNoise_dB, opts)
thr = noiseFloor_dB + thrAboveNoise_dB;
above = env_dB > thr;

onS  = find(diff([false; above]) == 1);
offS = find(diff([above; false]) == -1);

% merge gaps
mergeGap = round((opts.mergeGap_ms/1000)*fs);
k = 1;
while k < numel(onS)
    if onS(k+1) - offS(k) <= mergeGap
        offS(k) = offS(k+1);
        onS(k+1) = [];
        offS(k+1) = [];
    else
        k = k + 1;
    end
end

% min duration
minDur = round((opts.minCallDur_ms/1000)*fs);
keep = (offS - onS) >= minDur;
onS  = onS(keep);
offS = offS(keep);

% min separation (based on onset-to-onset)
minSep = round((opts.minCallSep_ms/1000)*fs);
if ~isempty(onS)
    keep2 = true(size(onS));
    last = onS(1);
    for i = 2:numel(onS)
        if (onS(i) - last) < minSep
            keep2(i) = false;
        else
            last = onS(i);
        end
    end
    onS  = onS(keep2);
    offS = offS(keep2);
end
end