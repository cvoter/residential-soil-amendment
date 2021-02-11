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
library(cowplot) # For plot grid

# Source functions
source("src/model_outputs/functions_hourly_fluxes.R")

# Data
runname.info <- read.csv('results/runname.info.csv')
runname      <- as.character(runname.info$runname)

# 2. LOAD AND RESAVE FLUXES ---------------------------------------------------
# Define model run parameters
nhrs <- 5136
hour <- c(1:nhrs)

# Initalize indicies and summary data frames
cum.errors <- NULL
fluxes     <- NULL
i          <- 0

count = 1
# Retrieve and re-save hourly flux data for each model run
for (soil in c('measured','loam','clay_loam')) {
  for ( run in 1:length(runname) ){
    if (runname.info$type[run] != "nix") {
      this.run <- runname[run]
      
      # Initalize indicies and data frames within loop
      hourly.balance <- NULL
      
      # Define filenames for csv input and Rda output
      input.filepath  <- sprintf("results/model_outputs/%s/%s_%s_hourly_balance.csv", 
                                 this.run, soil, this.run)
      output.filepath <- sprintf('results/model_outputs/%s/%s_%s_hourly_balance.Rda', 
                                 this.run, soil, this.run)
      
      if (file.exists(input.filepath)){
        # Load data from csv, replace colnames with R versions
        hourly.balance           <- read.csv(input.filepath)
        colnames(hourly.balance) <- c("precipitation", 
                                      "delta.storage.surface",
                                      "delta.storage.canopy",
                                      "delta.storage.snow",
                                      "delta.storage.subsurface",
                                      "evaptranssum",
                                      "evaporation", 
                                      "surface.runoff",
                                      "transpiration", 
                                      "deep.drainage",
                                      "recharge")
        
        # Calculate this run's errors and add to this run's output dataframe
        errors         <- calculate_balance_errors(hourly.balance)
        hourly.balance <- as.data.frame(cbind(hour, hourly.balance, errors))
        
        # Add this run's final cumulative errors to summary error dataframe
        this.cum.errs <- subset(hourly.balance, hour==nhrs,
                                select = c("cum.err.depth.CLM", "cum.err.rel.CLM",
                                           "cum.err.depth.PF", "cum.err.rel.PF",
                                           "cum.err.depth", "cum.err.rel"))
        cum.errors    <- as.data.frame(rbind(cum.errors, this.cum.errs))
        
        # Add this run's cumulative P, RO, DD, and ET to summary flux dataframe
        fluxes$soil[count]           <- soil
        fluxes$runname[count]        <- this.run
        fluxes$precip.depth[count]   <- sum(hourly.balance$precipitation)
        fluxes$runoff.depth[count]   <- sum(hourly.balance$surface.runoff)
        fluxes$ET.depth[count]       <- sum(hourly.balance$evaporation) + 
                                        sum(hourly.balance$transpiration)
        fluxes$drainage.depth[count] <- sum(hourly.balance$deep.drainage)
        
        # Save data frame to Rda file
        # save(hourly.balance, file = output.filepath)
        count = count + 1
      }
    }
  }
}

# 3. PROCESS FLUXES ----------------------------------------------------
# Convert fluxes as DEPTH from list to dataframe
fluxes <- as.data.frame(fluxes)

# Fluxes as PERCENT
fluxes$runoff.precip   <- 100*fluxes$runoff.depth/fluxes$precip.depth
fluxes$ET.precip       <- 100*fluxes$ET.depth/fluxes$precip.depth
fluxes$drainage.precip <- 100*fluxes$drainage.depth/fluxes$precip.depth

fluxes <- merge(fluxes, runname.info, by = "runname")

# Difference as DEPTH
fluxes <- fluxes %>%
          group_by(soil) %>%
          mutate(runoff.diff = runoff.depth - 
                              (fluxes %>% group_by(soil) %>% filter(runname == "amend_pixels_TWI_0"))$runoff.depth,
                 ET.diff = ET.depth - filter(fluxes, runname == "amend_pixels_TWI_0")$ET.depth,
                 drainage.diff = drainage.depth - filter(fluxes, runname == "amend_pixels_TWI_0")$drainage.depth)

# Difference as PERCENT PRECIP
fluxes$runoff.diff.precip   <- fluxes$runoff.diff/fluxes$precip.depth
fluxes$drainage.diff.precip <- fluxes$drainage.diff/fluxes$precip.depth
fluxes$ET.diff.precip       <- fluxes$ET.diff/fluxes$precip.depth

# Difference as PERCENT MAX DIFF
fluxes <- fluxes %>%
          group_by(soil) %>%
          mutate(runoff.diff.rel = 100*abs(runoff.diff/max(runoff.diff)),
                 ET.diff.rel = 100*ET.diff/max(ET.diff),
                 drainage.diff.rel = 100*drainage.diff/max(drainage.diff))

# 4. SAVE PROCESSED DATA FRAMES -----------------------------------------------
# save(fluxes, file = sprintf('%s/fluxes_summary.Rda', results.dir))

# 5. PLOT WATER BALANCE ERRORS ------------------------------------------------
x.label     <- "Cumulative Error as Depth (mm)"
y.label     <- "Cumulative Relative Error (-)"
x.intercept <- 1
y.intercept <- 0.01

plot.err.CLM <- ggplot() +
                geom_point(data = cum.errors,
                           aes(x = abs(cum.err.depth.CLM),
                               y = abs(cum.err.rel.CLM))) + 
                scale_y_log10() +
                scale_x_log10() +
                labs(x = x.label, y = y.label, title = "CLM") +
                geom_vline(xintercept = x.intercept) + 
                geom_hline(yintercept = y.intercept) +
                theme_bw()

plot.err.PF <- ggplot() +
               geom_point(data = cum.errors,
                          aes(x = abs(cum.err.depth.PF),
                              y = abs(cum.err.rel.PF))) + 
               scale_y_log10() +
               scale_x_log10() +
               labs(x = x.label, y = y.label, title = "PF") +
               geom_vline(xintercept = x.intercept) + 
               geom_hline(yintercept = y.intercept) +
               theme_bw()

plot.err <- ggplot() +
            geom_point(data = cum.errors,
                       aes(x = abs(cum.err.depth),
                           y = abs(cum.err.rel))) + 
            scale_y_log10() +
            scale_x_log10() +
            labs(x = x.label, y = y.label, title = "Overall") +
            geom_vline(xintercept = x.intercept) + 
            geom_hline(yintercept = y.intercept) +
            theme_bw()

plot_grid(plot.err, plot.err.PF, plot.err.CLM, ncol = 3)
