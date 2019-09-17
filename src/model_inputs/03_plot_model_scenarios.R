# 02_process_hourly_fluxes.R

# This script performs the following steps:
# 1. SETUP ENVIRONMENT. Loads libraries, defines directories, sources functions
# 2. LOAD AND RESAVE FLUXES. Loads hourly fluxes as csvs, calulates water
#    balance errors, and resaves to .Rda files
# 3. PROCESS FLUXES BY LOT. For each lot (aka runname), calculates cumulative
#    runoff, deep drainage, ET, and subsurface storage as A) depth, B) fraction
#    of precipitation, C) fraction of root zone fluxes (using dreep drainge),
#    and D) fraction of root zone fluxes (using subsurface storage).
# 4. PROCESS FLUXES (CHANGES) BY LOCATION. For each location, calculate change
#    in fluxes due to low-impact practices as A) depth, B) fraction of
#    precipitation, and C) fraction of root zone fluxes (using deep drainage).
# 5. SAVE PROCESSED DATA FRAMES. By lot and by location.
# 6. PLOT WATER BALANCE ERRORS. Visualize cumulative relative and depth errors
#   for CLM only, ParFlow only, and entire model.

# 1. SETUP ENVIRONMENT --------------------------------------------------------
# Load Libraries 
library(ggplot2) # For plotting
library(extrafont) # for font text on plots

# Define project directories
project.dir <- 'J:/git_research/projects/parcel_soil_amendment'
scripts.dir <- sprintf('%s/src/model_inputs', project.dir)
results.dir <- sprintf('%s/results', project.dir)

# Source functions

# Data
load(sprintf('%s/runname.info.Rda',results.dir))


# 2. PLOT ---------------------------------------------------------------------
i = 10
plot.pixels <- ggplot() + 
               geom_point(data = runname.info[1:i,], 
                          aes(x = "identity", 
                              y = 100*amended.pixels/2480), 
                          shape = 16, size = 3) + 
               geom_point(data = runname.info[i,], 
                          aes(x = "identity", 
                              y = 100*amended.pixels/2480),
                          shape = 16, size = 3, color = "#a3142e") +
               geom_text(data = runname.info[i,],
                         aes(x = "identity", 
                             y = 100*amended.pixels/2480,
                             label = sprintf("%s%%",round(100*amended.pixels/2480*4)/4)),
                         color = "#a3142e",
                         nudge_x = -0.25, 
                         size = 8) +
               scale_y_log10(breaks = c(1,10,100),
                             minor_breaks = c(0.1*c(1:9), c(1:9), 10*c(1:9)),
                             limits = c(0.1,100)) +
               scale_x_discrete(labels = "") +
               labs(x = "", 
                    y = "Pixels Amended (%)",
                    title = "") +
               theme_bw() +
               theme(text = element_text(size=20, family="Segoe UI Semilight"),
                     axis.title = element_text(size=20, family="Segoe UI Semibold"),
                     title = element_text(size=24, family="Segoe UI Semibold"),
                     plot.title = element_text(hjust = 0.5))
plot.pixels

i = 13
plot.features <- ggplot() + 
  geom_point(data = subset(runname.info, type.short == "p"), 
             aes(x = "identity",
                 y = 100*amended.pixels/2480), 
             shape = 16, size = 3, color = "grey60") + 
  geom_point(data = runname.info[11:(10+i),],
             aes(x = "identity",
                 y = 100*amended.pixels/2480),
             shape = 16, size = 3, color = "black") +
  geom_point(data = runname.info[10+i,],
             aes(x = "identity",
                 y = 100*amended.pixels/2480),
             shape = 16, size = 3, color = "#a3142e") +
  geom_text(data = runname.info[10+i,],
            aes(x = "identity",
                y = 100*amended.pixels/2480,
                label = sprintf("%s%%",round(100*amended.pixels/2480*4)/4)),
            color = "#a3142e",
            nudge_x = -0.25,
            size = 8) +
  scale_y_log10(breaks = c(1,10,100),
                minor_breaks = c(0.1*c(1:9), c(1:9), 10*c(1:9)),
                limits = c(0.1,100)) +
  scale_x_discrete(labels = "") +
  labs(x = "", 
       y = "Pixels Amended (%)",
       title = "") +
  theme_bw() +
  theme(text = element_text(size=20, family="Segoe UI Semilight"),
        axis.title = element_text(size=20, family="Segoe UI Semibold"),
        title = element_text(size=24, family="Segoe UI Semibold"),
        plot.title = element_text(hjust = 0.5))
plot.features

