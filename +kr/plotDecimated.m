function plotDecimated(t, y, maxN)
if numel(y) > maxN
    idx = round(linspace(1, numel(y), maxN));
    plot(t(idx), y(idx), 'k');
else
    plot(t, y, 'k');
end
end