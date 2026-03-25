function meta = loadLastMeta_v7(fallbackMeta)
%LOADLASTMETA_V7 Load last meta from disk, else return fallbackMeta.

if nargin < 1 || isempty(fallbackMeta)
    fallbackMeta = struct();
end

meta = fallbackMeta;
cfgPath = krgui.metaConfigPath_v7();

if exist(cfgPath, 'file') ~= 2
    return;
end

try
    S = load(cfgPath, 'metaLast');
    if isfield(S, 'metaLast') && isstruct(S.metaLast)
        meta = mergeMeta_(fallbackMeta, S.metaLast);
    end
catch
    % ignore corrupt file; keep fallback
end
end

function out = mergeMeta_(a, b)
out = a;
f = fieldnames(b);
for i = 1:numel(f)
    out.(f{i}) = b.(f{i});
end
end