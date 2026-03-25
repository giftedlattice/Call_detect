function [onW, offW, dispToFixed] = applyFilter_v7(state)
%APPLYFILTER_V7 Build working list from candidate pool robustly.
%
% keepMask = (autoKeep_fixed AND bwOk_fixed) OR manualKeep_fixed
% manualKeep always overrides (keeps even if bw is "bad").

% Candidate count (ground truth)
nCand = numel(state.calls_on_fixed);

% Normalize masks to length nCand safely
auto = false(nCand,1);
man  = false(nCand,1);
bw   = true(nCand,1);

if isfield(state,'autoKeep_fixed') && ~isempty(state.autoKeep_fixed)
    a = logical(state.autoKeep_fixed(:));
    auto(1:min(nCand,numel(a))) = a(1:min(nCand,numel(a)));
end

if isfield(state,'manualKeep_fixed') && ~isempty(state.manualKeep_fixed)
    m = logical(state.manualKeep_fixed(:));
    man(1:min(nCand,numel(m))) = m(1:min(nCand,numel(m)));
end

if isfield(state,'bwOk_fixed') && ~isempty(state.bwOk_fixed)
    b = logical(state.bwOk_fixed(:));
    bw(1:min(nCand,numel(b))) = b(1:min(nCand,numel(b)));
end

keepMask = (auto & bw) | man;

dispToFixed = find(keepMask);
onW  = state.calls_on_fixed(keepMask);
offW = state.calls_off_fixed(keepMask);
end