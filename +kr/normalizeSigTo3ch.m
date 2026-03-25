function sig3 = normalizeSigTo3ch(sigIn)
%NORMALIZESIGTO3CH Convert input signal to Nx3 [rear,left,right].
% Accepts:
%   - Nx1  : rear only
%   - Nx2  : assumed [rear,left]
%   - Nx3  : [rear,left,right]
% Missing channels filled with NaN.

sigIn = double(sigIn);

% Ensure 2D column-oriented
if isvector(sigIn)
    sigIn = sigIn(:);
end

N = size(sigIn,1);

switch size(sigIn,2)
    case 1
        sig3 = [sigIn, nan(N,1), nan(N,1)];
    case 2
        % assume [rear,left], missing right
        sig3 = [sigIn(:,1), sigIn(:,2), nan(N,1)];
    case 3
        sig3 = sigIn;
    otherwise
        error('sig must be Nsamp x 1, 2, or 3.');
end
end