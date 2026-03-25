function autoMask = computeAutoKeepMask_v7(env_dB, noiseFloor_dB, thrAboveNoise_dB, onS, offS)
thr = noiseFloor_dB + thrAboveNoise_dB;

n = numel(onS);
autoMask = false(n,1);

N = numel(env_dB);
onS  = max(1, min(N, round(onS(:))));
offS = max(1, min(N, round(offS(:))));

for k = 1:n
    a = onS(k); b = offS(k);
    if b < a, tmp=a; a=b; b=tmp; end
    seg = env_dB(a:b);
    if ~isempty(seg)
        autoMask(k) = max(seg) > thr;
    end
end
end