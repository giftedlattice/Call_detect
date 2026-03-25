function [onS, offS] = scrubBounds_v7(onS, offS, N)
onS  = onS(:); offS = offS(:);

if isempty(onS) || isempty(offS)
    onS = onS([]); offS = offS([]);
    return;
end

m = min(numel(onS), numel(offS));
onS  = onS(1:m);
offS = offS(1:m);

onS  = max(1, min(N, round(onS)));
offS = max(1, min(N, round(offS)));

swap = offS < onS;
if any(swap)
    tmp = onS(swap);
    onS(swap) = offS(swap);
    offS(swap) = tmp;
end
end