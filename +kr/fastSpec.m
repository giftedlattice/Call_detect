function [SdB,Fk,Tk] = fastSpec(x, fs, opts)
win  = opts.specWin;
ovl  = opts.specOvl;
nfft = opts.specNfft;

[S,F,T] = spectrogram(double(x), win, ovl, nfft, fs, 'yaxis');
SdB = 20*log10(abs(S)+eps);
Fk  = F/1000; % kHz
Tk  = T;      % seconds
end