function conds = loadConditions_v7(defaultList)
%LOADCONDITIONS_V7 Load saved condition list from config file.
% Returns string column vector. Silent fallback if not present.

if nargin < 1 || isempty(defaultList)
    defaultList = [""];
end

conds = string(defaultList(:));
cfgPath = krgui.metaConfigPath_v7();

if exist(cfgPath,'file') ~= 2
    return;
end

try
    S = load(cfgPath);
    if isfield(S,'conditionsList')
        c = string(S.conditionsList(:));
        c = unique(c, 'stable');
        if ~isempty(c)
            conds = c;
        end
    end
catch
    % ignore
end

if isempty(conds)
    conds = string(defaultList(:));
end
end