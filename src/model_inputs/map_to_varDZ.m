% map_to_varDz.m
% Carolyn Voter
% Feb 2018

% Take existing ICpressure vector at regularly spaced intervals and map to
% a new ICpressure vector for irregularly spaced intervals

function [IC_new] = map_to_varDZ(zL, dz_old, nz_old, z_new, IC_old)
% Old z vector
zU = zL+dz_old*nz_old;
z0_old = zL+dz_old/2; 
zf_old = zU-dz_old/2;
z_old = z0_old:dz_old:zf_old;

% Map old IC onto new IC
IC_new = interp1(z_old, IC_old, z_new)';
IC_new(end) = IC_old(end);

end
