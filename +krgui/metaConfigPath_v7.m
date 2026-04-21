% function cfgPath = metaConfigPath_v7()
% %METACONFIGPATH_V7 Returns a stable file path for storing last-used meta.
% try
%     base = prefdir; % user-specific, persistent
% catch
%     base = pwd;
% end
% cfgPath = fullfile(base, 'KR_callDetectTool_v7_lastMeta.mat');
% end

function cfgPath = metaConfigPath_v7()
%METACONFIGPATH_V7 Returns a stable file path for storing last-used meta.
cfgPath = fullfile(fileparts(mfilename('fullpath')), 'KR_callDetectTool_v7_lastMeta.mat');
end