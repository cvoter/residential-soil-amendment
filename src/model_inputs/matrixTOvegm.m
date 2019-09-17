function [ ] = matrixTOvegm(saveDir,nx,ny,vegGrid)
%matrixTOvegm.m
%Based on *.f90 script of same name by Vibhava Srivastave, obtained from
%Aditi Bhaskar
%Modified by Carolyn Voter
%September 02, 2014

sand = 0.16;
clay = 0.265;
color = 2;
cell = nx*ny;
lat = 43.14;
lon = -89.33;

lu1 = zeros([nx ny]);
lu2 = zeros([nx ny]);
lu3 = zeros([nx ny]);
lu4 = zeros([nx ny]);
lu5 = zeros([nx ny]);
lu6 = zeros([nx ny]);
lu7 = zeros([nx ny]);
lu8 = zeros([nx ny]);
lu9 = zeros([nx ny]);
lu10 = zeros([nx ny]);
lu11 = zeros([nx ny]);
lu12 = zeros([nx ny]);
lu13 = zeros([nx ny]);
lu14 = zeros([nx ny]);
lu15 = zeros([nx ny]);
lu16 = zeros([nx ny]);
lu17 = zeros([nx ny]);
lu18 = zeros([nx ny]);

for j=1:ny
    for i=1:nx
        if vegGrid(i,j)==1
            lu1(i,j) = 1;
        elseif vegGrid(i,j)==2
            lu2(i,j) = 1;
        elseif vegGrid(i,j)==3
            lu3(i,j) = 1;
        elseif vegGrid(i,j)==4
            lu4(i,j) = 1;
        elseif vegGrid(i,j)==5
            lu5(i,j) = 1;
        elseif vegGrid(i,j)==6
            lu6(i,j) = 1;
        elseif vegGrid(i,j)==7
            lu7(i,j) = 1;
        elseif vegGrid(i,j)==8
            lu8(i,j) = 1;
        elseif vegGrid(i,j)==9
            lu9(i,j) = 1;
        elseif vegGrid(i,j)==10
            lu10(i,j) = 1;
        elseif vegGrid(i,j)==11
            lu11(i,j) = 1;
        elseif vegGrid(i,j)==12
            lu12(i,j) = 1;
        elseif vegGrid(i,j)==13
            lu13(i,j) = 1;
        elseif vegGrid(i,j)==14
            lu14(i,j) = 1;
        elseif vegGrid(i,j)==15
            lu15(i,j) = 1;
        elseif vegGrid(i,j)==16
            lu16(i,j) = 1;
        elseif vegGrid(i,j)==17
            lu17(i,j) = 1;
        elseif vegGrid(i,j)==18
            lu18(i,j) = 1;
        end
    end
end

filename = strcat(saveDir,'/drv_vegm.dat');
fid = fopen(filename,'w');
fmt = '%4d% 4d% 7.2f% 7.2f% 3.2f% 3.2f% 2d% 4.2f% 4.2f% 4.2f% 4.2f% 4.2f% 4.2f% 4.2f% 4.2f% 4.2f% 4.2f% 4.2f% 4.2f% 4.2f% 4.2f% 4.2f% 4.2f% 4.2f% 4.2f\n';
fprintf(fid,'%s\n','x  y  lat    lon    sand clay color  fractional coverage of grid by vegetation class (Must/Should Add to 1.0)');
fprintf(fid,'%s\n','         (Deg)  (Deg)  (%/100) index  1    2    3    4    5    6    7    8    9   10  11  12   13   14   15   16   17   18');
for j=1:ny
    for i=1:nx
        landuse = [lu1(i,j) lu2(i,j) lu3(i,j) lu4(i,j) lu5(i,j) lu6(i,j)...
            lu7(i,j) lu8(i,j) lu9(i,j) lu10(i,j) lu11(i,j) lu12(i,j)...
            lu13(i,j) lu14(i,j) lu15(i,j) lu16(i,j) lu17(i,j) lu18(i,j)];
        matrix = [i,j,lat,lon,sand,clay,color,landuse(1,:)];
        fprintf(fid,fmt,matrix);
    end
end
fclose(fid);

end

