function moveBound_v7(mainFig, roiHandle, which)

app = guidata(mainFig);
if isempty(app.state.calls_on)
    return;
end

kDisp = max(1, min(app.state.selectedIdx, numel(app.state.calls_on)));
fixedIdx = app.state.dispToFixed(kDisp);

pos = roiHandle.Position;
sNew = round(pos(1,1) * app.fs) + 1;
sNew = max(1, min(numel(app.rear), sNew));

% Use a separate minimum duration for MANUAL edits if provided.
minDur_ms = app.opts.minCallDur_ms;
if isfield(app.opts,'manualMinCallDur_ms') && ~isempty(app.opts.manualMinCallDur_ms)
    minDur_ms = app.opts.manualMinCallDur_ms;
end
minDurS = round((minDur_ms/1000) * app.fs);

onS  = app.state.calls_on_fixed(fixedIdx);
offS = app.state.calls_off_fixed(fixedIdx);

if which == "on"
    onS = min(sNew, offS - minDurS);
else
    offS = max(sNew, onS + minDurS);
end

app.state.calls_on_fixed(fixedIdx)  = onS;
app.state.calls_off_fixed(fixedIdx) = offS;

[app.state.calls_on_fixed, app.state.calls_off_fixed] = krgui.scrubBounds_v7( ...
    app.state.calls_on_fixed, app.state.calls_off_fixed, app.Nsamp);

% IMPORTANT:
% If time bounds change, old manual frequency picks are no longer guaranteed
% to belong to the new boundaries, so clear them for this call.
if isfield(app.state,'startFreq_manual_fixed_kHz') && ...
        numel(app.state.startFreq_manual_fixed_kHz) >= fixedIdx
    app.state.startFreq_manual_fixed_kHz(fixedIdx) = NaN;
end

if isfield(app.state,'endFreq_manual_fixed_kHz') && ...
        numel(app.state.endFreq_manual_fixed_kHz) >= fixedIdx
    app.state.endFreq_manual_fixed_kHz(fixedIdx) = NaN;
end

% NEW:
% Mark this candidate as manually edited so it survives filtering even if
% its new shorter bounds no longer pass automatic bandwidth/threshold tests.
if isfield(app.state,'manualEdited_fixed') && numel(app.state.manualEdited_fixed) >= fixedIdx
    app.state.manualEdited_fixed(fixedIdx) = true;
end

% Recompute bandwidth validity for this candidate after bounds change
if isfield(app.state,'bwOk_fixed') && numel(app.state.bwOk_fixed) >= fixedIdx
    a = app.state.calls_on_fixed(fixedIdx);
    b = app.state.calls_off_fixed(fixedIdx);

    if b > a
        segR = app.rear(a:b);
        r = kr.feature_ridgeFreqs_v7(segR, app.fs, app.opts);
        bw = r.max_kHz - r.min_kHz;

        minBW = 0;
        if isfield(app.opts,'autoThr_minBandwidth_kHz')
            minBW = app.opts.autoThr_minBandwidth_kHz;
        end

        app.state.bwOk_fixed(fixedIdx) = isfinite(bw) && (bw > minBW);
    else
        app.state.bwOk_fixed(fixedIdx) = false;
    end
end

app.state.autoKeep_fixed = krgui.computeAutoKeepMask_v7( ...
    app.env_dB, app.noiseFloor_dB, app.state.thrAboveNoise_dB, ...
    app.state.calls_on_fixed, app.state.calls_off_fixed);

[app.state.calls_on, app.state.calls_off, app.state.dispToFixed] = ...
    krgui.applyFilter_v7(app.state);

% Keep selection on the same fixed candidate if it is still visible.
newDispIdx = find(app.state.dispToFixed == fixedIdx, 1, 'first');
if ~isempty(newDispIdx)
    app.state.selectedIdx = newDispIdx;
else
    app.state.selectedIdx = min(app.state.selectedIdx, max(1, numel(app.state.calls_on)));
end

guidata(mainFig, app);
krgui.redrawAll_v7(mainFig);

end