function contrastStretch(ax, SdB)
v1 = prctile(SdB(:), 10);
v2 = prctile(SdB(:), 99);
if isfinite(v1) && isfinite(v2) && v2 > v1
    caxis(ax, [v1 v2]);
end
end