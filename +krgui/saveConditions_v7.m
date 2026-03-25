function saveConditions_v7(conds)
%SAVECONDITIONS_V7 Save condition list into config file while preserving metaLast.

cfgPath = krgui.metaConfigPath_v7();

conds = string(conds(:));
conds = unique(conds, 'stable'); % preserve order, remove dupes

conditionsList = conds; %#ok<NASGU>
metaLast = []; %#ok<NASGU>

% Load existing metaLast (if present)
try
    if exist(cfgPath,'file') == 2
        S = load(cfgPath);
        if isfield(S,'metaLast')
            metaLast = S.metaLast; %#ok<NASGU>
        end
    end
catch
    % ignore
end

try
    if exist('metaLast','var') && ~isempty(metaLast)
        save(cfgPath, 'conditionsList', 'metaLast');
    else
        save(cfgPath, 'conditionsList');
    end
catch ME
    warning('Could not save conditions list: %s', ME.message);
end
end