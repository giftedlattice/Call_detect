function moveFreqPoint_v7(mainFig, src, whichPoint)
%MOVEFREQPOINT_V7 Vertical-only drag for start/end frequency points.
% Time stays locked to waveform-defined boundaries.

app = guidata(mainFig);

if isempty(app.state.calls_on)
    return;
end

kDisp = max(1, min(app.state.selectedIdx, numel(app.state.calls_on)));
fixedIdx = app.state.dispToFixed(kDisp);

on  = app.state.calls_on(kDisp);
off = app.state.calls_off(kDisp);

tOn  = (on-1)/app.fs;
tOff = (off-1)/app.fs;

pos = src.Position;
yNew = pos(2);

% Clamp to displayed harmonic band
yMin = app.opts.harmBand_kHz(1);
yMax = app.opts.harmBand_kHz(2);
yNew = max(yMin, min(yMax, yNew));

switch string(whichPoint)
    case "start"
        % lock x to start boundary
        src.Position = [tOn, yNew];
        app.state.startFreq_manual_fixed_kHz(fixedIdx) = yNew;

        % update label live
        if isfield(app,'roi') && isfield(app.roi,'startFreqTxt') && ...
                ~isempty(app.roi.startFreqTxt) && isgraphics(app.roi.startFreqTxt)
            app.roi.startFreqTxt.Position = [tOn, yNew, 0];
            app.roi.startFreqTxt.String = sprintf('  start %.1f kHz', yNew);
        end

    case "end"
        % lock x to end boundary
        src.Position = [tOff, yNew];
        app.state.endFreq_manual_fixed_kHz(fixedIdx) = yNew;

        % update label live
        if isfield(app,'roi') && isfield(app.roi,'endFreqTxt') && ...
                ~isempty(app.roi.endFreqTxt) && isgraphics(app.roi.endFreqTxt)
            app.roi.endFreqTxt.Position = [tOff, yNew, 0];
            app.roi.endFreqTxt.String = sprintf('  end %.1f kHz', yNew);
        end
end

guidata(mainFig, app);
krgui.refreshTable_v7(mainFig);
end