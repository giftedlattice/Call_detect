function onAddButton_v7(mainFig)
%onAddButton_v7 Add a call by entering a peak time (seconds).

app = guidata(mainFig);

defaultT = '';
if ~isempty(app.state.calls_on)
    k = max(1, min(app.state.selectedIdx, numel(app.state.calls_on)));
    defaultT = sprintf('%.6f', (app.state.calls_on(k)-1)/app.fs);
end

answ = inputdlg({'Enter peak time (seconds):'}, 'Add call', [1 50], {defaultT});
if isempty(answ)
    return;
end

tPeak = str2double(strtrim(answ{1}));
if ~isfinite(tPeak)
    try
        app.txtSel.String = "Add canceled: invalid time.";
        guidata(mainFig, app);
    catch
    end
    return;
end

sClick = round(tPeak * app.fs) + 1;
sClick = max(1, min(numel(app.env_dB), sClick));

pkWin_ms = 1.0;
pkWinS = max(1, round((pkWin_ms/1000)*app.fs));
aPk = max(1, sClick - pkWinS);
bPk = min(numel(app.env_dB), sClick + pkWinS);
[~, iPk] = max(app.env_dB(aPk:bPk));
sPk = aPk + iPk - 1;

thr = app.noiseFloor_dB + app.state.thrAboveNoise_dB;

on = sPk;
while on > 1 && app.env_dB(on) > thr
    on = on - 1;
end

off = sPk;
while off < numel(app.env_dB) && app.env_dB(off) > thr
    off = off + 1;
end

if isfield(app.opts,'boundRefine_enable') && app.opts.boundRefine_enable
    [on, off] = krgui.refineBoundsMainBurst_v7(app.env_dB, app.fs, on, off, app.opts);
end

% Append to candidate pool + force keep
app.state.calls_on_fixed(end+1)   = on;
app.state.calls_off_fixed(end+1)  = off;
app.state.manualKeep_fixed(end+1) = true;

% Extend manual freq override arrays
app.state.startFreq_manual_fixed_kHz(end+1) = NaN;
app.state.endFreq_manual_fixed_kHz(end+1)   = NaN;

% If bw mask exists, extend it for this new call
if isfield(app.state,'bwOk_fixed') && ~isempty(app.state.bwOk_fixed)
    segR = app.rear(on:off);
    r = kr.feature_ridgeFreqs_v7(segR, app.fs, app.opts);
    bw = r.max_kHz - r.min_kHz;

    minBW = 0;
    if isfield(app.opts,'autoThr_minBandwidth_kHz')
        minBW = app.opts.autoThr_minBandwidth_kHz;
    end
    app.state.bwOk_fixed(end+1) = isfinite(bw) && (bw > minBW);
end

% Sort candidate pool and keep masks aligned
[app.state.calls_on_fixed, ord] = sort(app.state.calls_on_fixed(:));
app.state.calls_off_fixed  = app.state.calls_off_fixed(ord);
app.state.manualKeep_fixed = app.state.manualKeep_fixed(ord);

if isfield(app.state,'bwOk_fixed') && ~isempty(app.state.bwOk_fixed)
    app.state.bwOk_fixed = app.state.bwOk_fixed(ord);
end

app.state.startFreq_manual_fixed_kHz = app.state.startFreq_manual_fixed_kHz(ord);
app.state.endFreq_manual_fixed_kHz   = app.state.endFreq_manual_fixed_kHz(ord);

[app.state.calls_on_fixed, app.state.calls_off_fixed] = krgui.scrubBounds_v7( ...
    app.state.calls_on_fixed, app.state.calls_off_fixed, app.Nsamp);

app.state.autoKeep_fixed = krgui.computeAutoKeepMask_v7( ...
    app.env_dB, app.noiseFloor_dB, app.state.thrAboveNoise_dB, ...
    app.state.calls_on_fixed, app.state.calls_off_fixed);

[app.state.calls_on, app.state.calls_off, app.state.dispToFixed] = krgui.applyFilter_v7(app.state);

newFixedIdx = find(app.state.manualKeep_fixed, 1, 'last');
newDispIdx  = find(app.state.dispToFixed == newFixedIdx, 1, 'first');
if ~isempty(newDispIdx)
    app.state.selectedIdx = newDispIdx;
end

guidata(mainFig, app);
krgui.redrawAll_v7(mainFig);
end