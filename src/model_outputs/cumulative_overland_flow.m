function [q_cum,q_net,net_runoff] = cumulative_overland_flow(surface_pressure, mannings,...
    slopeX, slopeY, x, y, dx, dy, mask, plot_on)

% cumulative_overland_flow.m
% Carolyn Voter
% 2019.05

% INPUTS
% surface_pressure = pressure head at surface (m), 0 if < 0.
% mannings = matrix of size ny,nx with manning's n for each cell
% slopeX = slope in x-direction, as input to parflow
% slopeY = slope in y-direction, as input to parflow
% dx, dy = horizontal resolution (m)
% mask = mask with NaNs for plotting
% plot_on = triggers plotting when set to 1

% OUTPUTS
% q_cum = cumulative overland flow each cell experiences (m^3)
% q_net = net runoff from each cell per time step (m^3/time step)
% net_runoff = net runoff from domain (m^3), this should match what is
% calculated for overlandsum.total.step.mat

% PROCESS
%  1. EXTRACT PARAMETERS.
%  2. CALCULATE CUMULATIVE FLOW OVER CELLS. 
%  3. PLOT. Plots cumulative overland flow masked by mask when plot_on = 1


%% 1. EXTRACT PARAMETERS
nhours = length(surface_pressure);
[Xy,Yx] = meshgrid(x,y);
xL = x(1); xU = x(length(x));
yL = y(1); yU =y(length(y));
[ny,nx] = size(slopeX);

% Flow direction
xdir = zeros(size(slopeX));
ydir = zeros(size(slopeY));
xdir(slopeX > 0) = -1;
xdir(slopeX < 0) = 1;
ydir(slopeY > 0) = -1;
ydir(slopeY < 0) = 1;

%% 2. CALCULATE CUMULATIVE FLOW OVER CELLS
q_cum = zeros(size(surface_pressure{1}));
for i = 1:nhours
    for j = 1:ny
        for k = 1:nx
            dirx = xdir(j,k);
            Sx = slopeX(j,k);
            mnx = mannings(j,k);
            px = surface_pressure{i}(j,k);
            q_x{i}(j,k) = dirx*(px^(5/3))*sqrt(abs(Sx))*dx/mnx;
            diry = ydir(j,k);
            Sy = slopeY(j,k);
            mny = mannings(j,k);
            py = surface_pressure{i}(j,k);
            q_y{i}(j,k) = diry*(py^(5/3))*sqrt(abs(Sy))*dy/mny;
            q_net{i}(j,k) = abs(q_y{i}(j,k)) + abs(q_x{i}(j,k));
            net_runoff(i) = sum(q_y{i}(end,:))-sum(q_y{i}(1,:)) + ...
                sum(q_x{i}(:,end))-sum(q_x{i}(:,1));
            q_cum(j,k) = q_cum(j,k) + q_net{i}(j,k);
        end
    end         
end

%% 3. PLOT
if plot_on == 1
    if ishandle(1) == 0; figure_num = 0; else figure_props = gcf; figure_num = figure_props.Number; end
    figure(figure_num+1)
    hold on
    pcolor(Xy,Yx,log10(q_cum).*mask)
    shading flat
    rectangle('Position',[xL,yL,(xU-xL),(yU-yL)],'EdgeColor','k','LineStyle',...
        '-','LineWidth',1.5);
    colormap(brewermap([],'Blues'))
    c = colorbar;
    c.Label.String = 'Cum. Overland Flow (log m^3)';
    xlabel('Distance (m)');
    ylabel('Distance (m)');
    axis equal
    axis([xL-2 xU+2 yL-2 yU+2])
    hold off
end

end

