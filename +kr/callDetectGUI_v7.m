function [calls, detInfo] = callDetectGUI_v7(sig, fs, opts, meta)
%CALLDETECTGUI_V7 Modular GUI entry point (now includes meta for export-preview table).

if nargin < 4 || isempty(meta)
    meta = struct('bat',"", 'date',"", 'trial',"");
end

if ~isnumeric(sig) || size(sig,2) ~= 3
    error('sig must be Nsamp x 3 numeric: [rear,left,right].');
end
if ~isscalar(fs) || ~isfinite(fs) || fs <= 0
    error('fs must be a positive finite scalar.');
end

% Build initial state (detection happens ONCE here)
app = krgui.initState_v7(sig, fs, opts, meta);

% Build UI (two windows) and store handles into app
app = krgui.buildUI_v7(app);

% Wire callbacks
krgui.wireCallbacks_v7(app.mainFig);

% Initial draw
krgui.redrawAll_v7(app.mainFig);

% Block until OK/Cancel
uiwait(app.mainFig);

% If figures were closed unexpectedly
if ~ishandle(app.mainFig)
    calls = struct([]);
    detInfo = struct('accepted',false);
    return;
end

% Pull final app state
app = guidata(app.mainFig);

% Build outputs
[calls, detInfo] = krgui.buildOutputs_v7(app);

% Close windows
krgui.safeClose_v7(app);
end