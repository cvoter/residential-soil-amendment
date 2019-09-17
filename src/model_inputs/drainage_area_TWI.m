function [drainarea, TWI, catchmentarea] = drainage_area_TWI(slopeX, ...
    slopeY, mask, outlets, outlet_ids, dx, dy, plot_on)
% drainage_area_TWI.m
% Carolyn Voter
% 2019.05

% slopeX = slope in X direction, as input to ParFlow
% slopeY = slope in Y direction, as input to ParFlow
% mask = mask for plotting (NaNs for areas not to plot)
% outlets = mask with numbered outlets
% outlet ids = outlets to display on plots
% dx, dy = horizontal resolution (m)
% plot_on = triggers plotting when equal to 1

set(0,'defaultTextFontSize',10,'defaultTextFontName','Segoe UI Semilight',...
    'defaultAxesFontSize',10,'defaultAxesFontName','Segoe UI Semilight')

%% 1. DEFINE CONSTANTS
[ny,nx] = size(slopeX);
cellArea = dx*dy;
d4 = [3,4,1,2]; % down, left, top, right

% Max Slope for TWI
for i = 1:ny
    for j = 1:nx
        maxSlope(i,j) = max(abs(slopeX(i,j)),abs(slopeY(i,j)));
    end
end
if min(maxSlope(:)) == 0
    display("Warning: There is at least one cell with max slope = 0")
end

%% 2. SET DIRECTIONS BASED ON SLOPE
direction = zeros([ny,nx]);
for i = 1:ny
    for j = 1:nx
        % Determine if x or y dominates
        if abs(slopeX(i,j)) == abs(slopeY(i,j))
            if round(rand(1)) == 1
                dir = 1; %x dominates
            else
                dir = 2; %y dominates
            end
        elseif abs(slopeX(i,j)) > abs(slopeY(i,j))
            dir = 1; %x-dir
        elseif abs(slopeX(i,j)) < abs(slopeY(i,j))
            dir = 2; %y-dir
        end
        
        % Set direction
        if dir == 1 %x dominates
            if slopeX(i,j) < 0 % toward right
                direction(i,j) = d4(4);
            elseif slopeX(i,j) > 0 %toward left
                direction(i,j) = d4(2);
            end
        elseif dir == 2 %y dominates
            if slopeY(i,j) < 0 % toward top
                direction(i,j) = d4(3);
            elseif slopeY(i,j) > 0 %toward bottom
                direction(i,j) = d4(1);
            end    
        end
    end
end

%% 3. CALCULATE DRAINAGE AREA
drainarea = ones([ny,nx]);
kd = ones([2,4]);
kd(1,:) = [0, -1, 0, 1]; %downstream in x
kd(2,:) = [-1, 0, 1, 0]; %downstream in y

up = zeros([ny,nx]); up(direction == d4(3)) = 1;
down = zeros([ny,nx]); down(direction == d4(1)) = 1;
right = zeros([ny,nx]); right(direction == d4(4)) = 1;
left = zeros([ny,nx]); left(direction == d4(2)) = 1;

draincount = zeros([ny,nx]);
draincount(1:(ny-1),:) = draincount(1:(ny-1),:) + down(2:ny,:);
draincount(2:ny,:) = draincount(2:ny,:) + up(1:(ny-1),:);
draincount(:,1:(nx-1)) = draincount(:,1:(nx-1)) + left(:,2:nx);
draincount(:,2:nx) = draincount(:,2:nx) + right(:,1:(nx-1));
if max(draincount(:)) > 3
    display("Warning: Have at least one cell with no exit (draincount > 3)")
end

draintemp = draincount;
[queue_row,queue_col] = find(draintemp==0);
nqueue = length(queue_row);

while nqueue > 0
	%loop through the queue
    for i = 1:nqueue
        %look downstream add 1 to the area and subtract 1 from the drainage #
        col_temp = queue_col(i);
        row_temp = queue_row(i);
        
        dirtemp = find(d4==direction(row_temp,col_temp));
        col_ds = col_temp + kd(1,dirtemp);
        row_ds = row_temp + kd(2,dirtemp);
        
        %add one to the area of the downstream cell as long as that cell is in the domain
        if( (col_ds <= nx) && (col_ds >= 1) && (row_ds <= ny) && (row_ds >= 1))
            drainarea(row_ds,col_ds) = drainarea(row_ds,col_ds) + drainarea(row_temp, col_temp);
            
            %subtract one from the number of upstream cells from the downstream cell
            draintemp(row_ds,col_ds) = draintemp(row_ds,col_ds) - 1;
        end %end if in the domain extent
        
        %set the drain temp to -99 for current cell to indicate its been done
        draintemp(row_temp, col_temp) = -99;
    end %end for i in 1:nqueue

	%make a new queue with the cells with zero upstream drains left
    [queue_row,queue_col] = find(draintemp==0);
	nqueue = length(queue_row);
end

%% 4. CALCULATE TOPOGRAPHIC WETNESS INDEX
TWI = log((drainarea/dx)./tan(maxSlope));

%% 5. CALCULATE DRAINAGE AREA AT OUTLET
if length(outlets) > 0
    for i = 1:length(outlet_ids)
        [outlet_row(i),outlet_col(i)] = find(outlets == outlet_ids(i));
        catchmentarea(i,:) = [outlet_ids(i),...
            drainarea(outlet_row(i),outlet_col(i))*cellArea];
    end
else
    catchmentarea = 0;
end

%% 5. PLOT
if plot_on == 1
    
    if ishandle(1) == 0; figure_num = 0; else figure_props = gcf; figure_num = figure_props.Number; end
    
    % Drainage Area
    figure(figure_num+1)
    hold on
    pcolor(log10(drainarea).*mask)
    if length(outlets) > 0
        plot(outlet_col+0.5, outlet_row+0.5, '*m')
    end
    shading flat
    colormap(brewermap([],'Blues'))
    c = colorbar;
    c.Label.String = 'Log Drainage Area (m^2)';
    axis equal
    axis([0-2 nx+2 0-2 ny+2])
    hold off
    
    % Topographic Wetness Index
    figure(figure_num+2)
    hold on
    pcolor(TWI.*mask)
    if length(outlets) > 0
        plot(outlet_col+0.5, outlet_row+0.5, '*m')
    end
    shading flat
    colormap(brewermap([],'Blues'))
    c = colorbar;
    c.Label.String = 'Topographic Wetness Index';
    axis equal
    axis([0-2 nx+2 0-2 ny+2])
    hold off
end

end

