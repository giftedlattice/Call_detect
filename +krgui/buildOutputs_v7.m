function [calls, detInfo] = buildOutputs_v7(app)
calls = struct([]);
detInfo = struct('accepted',false);

if ~isfield(app,'state') || ~isfield(app.state,'accepted') || ~app.state.accepted
    return;
end

onK  = app.state.calls_on(:);
offK = app.state.calls_off(:);

for k = 1:numel(onK)
    fixedIdx = app.state.dispToFixed(k);

    calls(k).on_samp  = onK(k);
    calls(k).off_samp = offK(k);

    if isfield(app.state,'startFreq_manual_fixed_kHz') && numel(app.state.startFreq_manual_fixed_kHz) >= fixedIdx
        calls(k).startFreq_manual_kHz = app.state.startFreq_manual_fixed_kHz(fixedIdx);
    else
        calls(k).startFreq_manual_kHz = NaN;
    end

    if isfield(app.state,'endFreq_manual_fixed_kHz') && numel(app.state.endFreq_manual_fixed_kHz) >= fixedIdx
        calls(k).endFreq_manual_kHz = app.state.endFreq_manual_fixed_kHz(fixedIdx);
    else
        calls(k).endFreq_manual_kHz = NaN;
    end
end

detInfo.accepted = true;
detInfo.thrAboveNoise_dB = app.state.thrAboveNoise_dB;
detInfo.noiseFloor_dB = app.noiseFloor_dB;
detInfo.n_candidates = numel(app.state.calls_on_fixed);
detInfo.n_kept = numel(app.state.calls_on);
end