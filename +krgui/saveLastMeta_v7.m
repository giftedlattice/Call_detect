function saveLastMeta_v7(meta)
%SAVELASTMETA_V7 Save meta to config file while preserving conditionsList.

cfgPath = krgui.metaConfigPath_v7();

% Load existing pieces (if present)
metaLast = meta; %#ok<NASGU>
conditionsList = []; %#ok<NASGU>

try
    if exist(cfgPath,'file') == 2
        S = load(cfgPath);
        if isfield(S,'conditionsList')
            conditionsList = S.conditionsList; %#ok<NASGU>
        end
    end
catch
    % ignore
end

try
    if exist('conditionsList','var') && ~isempty(conditionsList)
        save(cfgPath, 'metaLast', 'conditionsList');
    else
        save(cfgPath, 'metaLast');
    end
catch ME
    warning('Could not save last meta config: %s', ME.message);
end
end