function [A] = matrixTOpfsa(M)
%Converts Matlab matrix to single-column matrix for to save as ascii file
%for input to Parflow

%ASSUMES:
% 1. Size M = [ny nx nz] or [ny nx]

n = size(M);
if length(n) == 3
    ny = n(1);  nx = n(2);  nz = n(3);
    A = zeros([nx*ny*nz,1]);
    count = 1;
    for k=1:nz
        for j=1:ny
            for i=1:nx
                A(count) = M(j,i,k);
                count = count+1;
            end
        end
    end
elseif length(n) == 2
    ny = n(1);  nx = n(2);
    A = zeros([nx*ny,1]);
    count = 1;
    for j=1:ny
        for i=1:nx
            A(count) = M(j,i);
            count = count+1;
        end
    end
end
end

