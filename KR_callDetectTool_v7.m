function KR_callDetectTool_v7()
% KR_callDetectTool_v7 (modularized v7)
% - Detect calls using REAR channel only
% - Edit call start/end in REAR waveform (draggable bounds)
% - Add/Toggle/Delete supported in GUI
% - Export computes first-harmonic features + per-channel timing/amp (if channels exist)
%
% Audio MAT must contain:
%   sig: [Nsamp x 1] OR [Nsamp x 2] OR [Nsamp x 3]
%   fs : optional

% ---- Prompt metadata (so nobody edits code) ----
% ---- Metadata defaults (will be overridden by last-used config if present) ----
defaultMeta = struct();
defaultMeta.bat   = "bat1";
defaultMeta.date  = string(datetime('today','Format','yyyy-MM-dd'));
defaultMeta.trial = "01";
defaultMeta.condition = "";
defaultMeta.catchTrial = false;
defaultMeta.temperature_C = NaN;
defaultMeta.humidity_pct  = NaN;

% Load last-used meta (if available)
defaultMeta = krgui.loadLastMeta_v7(defaultMeta);

% Prompt user
[meta, ok] = krgui.promptMeta_v7(defaultMeta);
if ~ok
    return;
end

% Save last-used meta for next time
krgui.saveLastMeta_v7(meta);

fsDefault = 250000;
opts = kr.defaultOpts_v7();

[aFiles, aPath] = uigetfile('*.mat', ...
    'Select audio MAT file(s) containing "sig"', ...
    'MultiSelect','on');

if isequal(aFiles,0)
    return;
end
if ischar(aFiles)
    aFiles = {aFiles};
end

for i = 1:numel(aFiles)
    fullMat = fullfile(aPath, aFiles{i});
    S = load(fullMat);

    if ~isfield(S,'sig')
        warning('Skipping %s: no sig.', aFiles{i});
        continue;
    end

    % Normalize to Nx3 [rear,left,right]
    try
        sig = kr.normalizeSigTo3ch(S.sig);
    catch ME
        warning('Skipping %s: %s', aFiles{i}, ME.message);
        continue;
    end

    fs = fsDefault;
    if isfield(S,'fs') && ~isempty(S.fs)
        fs = double(S.fs);
    end

    % GUI (takes meta for preview table)
    [calls, detInfo] = kr.callDetectGUI_v7(sig, fs, opts, meta);

    [~, baseChar] = fileparts(aFiles{i});
    base = string(baseChar);

    outCalls = fullfile(aPath, base + "_calls.mat");
    save(outCalls,'calls','detInfo','fs','fullMat');

    if isfield(detInfo,'accepted') && detInfo.accepted && ~isempty(calls)
        
        %export to csv
        T = kr.deriveCallTable_full(sig, fs, calls, meta, opts);
        writetable(T, fullfile(aPath, base + "_calls.csv"));

        %export to SQLite database in the same folder
        toolRoot = fileparts(mfilename('fullpath'));          % folder where this .m file lives
        dbPath   = fullfile(toolRoot, "Bats.sqlite");
        krdb.exportTrial_v7(dbPath, meta, fs, fullMat, calls, T);


        % store table in calls mat for convenience
        detInfo.callTable = T; %#ok<NASGU>
        save(outCalls,'calls','detInfo','fs','fullMat');
    end
end
end