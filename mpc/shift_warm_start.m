function Uinit = shift_warm_start(Uprev)
%SHIFT_WARM_START Shift previous optimal sequence for warm start.
% If Uprev = [u0; u1; ...; uNc-1]
% then next init guess = [u1; u2; ...; uNc-1; uNc-1]

if isempty(Uprev)
    Uinit = [];
    return;
end

Nc = length(Uprev);
Uinit = [Uprev(2:end); Uprev(end)];
end
