function opts = defaultOpts_v7()
%DEFAULTOPTS_V7 Central place for all tunable parameters.

opts = struct();

% Detection band (rear only)
opts.bpHz = [20000 100000];

% FIRST HARMONIC band for all spectral features + displayed spectrograms
opts.harmBand_kHz = [20 70];

% Envelope smoothing
opts.envSmooth_ms = 0.6;

% Detection criteria (candidate creation)
opts.minCallDur_ms = 0.3;          % auto-detection minimum duration
opts.manualMinCallDur_ms = 0.05;   % manual edit minimum duration
opts.minCallSep_ms = 2.0;
opts.mergeGap_ms = 0.6;

% Baseline threshold (your "good" default)
opts.initThrAboveNoise_dB = 12;

% Windows
opts.callHalfWin_s = 0.020;
opts.contextHalfWin_s = 1.50;

% Tight display padding around editable bounds
opts.callPad_s = 0.002;
opts.callSpecPad_s = 0.030;

% Fast spectrogram settings (ALWAYS use these)
opts.specWin = 256;
opts.specOvl = 192;
opts.specNfft = 512;

% Plot decimation
opts.maxSegForPlot = 2500;

% --- Auto boundary refinement to cut off echoes (main burst) ---
opts.boundRefine_enable = true;
opts.boundRefine_dropFromPeak_dB = 10;
opts.boundRefine_quiet_ms = 0.30;
opts.boundRefine_pad_ms = 0.20;
opts.boundRefine_startDrop_dB = 16;

% --- Ridge frequency logic knobs ---
opts.ridgeActiveDrop_dB = 12;
opts.ridgeEdgeDropStart_dB = 28;
opts.ridgeEdgeDropEnd_dB = 32;

% ==============================================================
% Auto-start threshold additional constraints (do NOT replace baseline)
% ==============================================================
% Goal: keep baseline initThrAboveNoise_dB unless it violates constraints.
% If it violates, increase threshold until satisfied.
opts.autoThr_enable = true;
opts.autoThr_searchMax_dB = 40;     % search upward from baseline to this max
opts.autoThr_step_dB = 0.5;

% Constraint #1: min IPI (ms) among KEPT calls
opts.autoThr_minIPI_ms = 2.0;

% Constraint #2: no KEPT calls with bandwidth == 0 (or effectively 0)
opts.autoThr_noZeroBW_enable = true;
opts.autoThr_minBandwidth_kHz = 0.10;   % treat anything below this as "zero-ish"

end