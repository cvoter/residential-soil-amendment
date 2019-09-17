# 03_plot_runoff.R

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
library(reshape2) # For melting
library(ggplot2) # For plotting
library(extrafont) # For fonts

# Define project directories
project.dir <- 'J:/git_research/projects/parcel_soil_amendment'
scripts.dir <- sprintf('%s/src/model_outputs', project.dir)
results.dir <- sprintf('%s/results', project.dir)

# Source functions

# Data
load(sprintf('%s/fluxes_summary.Rda', results.dir))

# 2. LOAD AND RESAVE FLUXES ---------------------------------------------------
x = seq(0.1,100,0.1)
y = x
variable = rep("runoff.diff.rel",length(x))
soil = rep("measured",length(x))
one.to.one = as.data.frame(cbind(x,y,variable,soil))
soil = rep("loam",length(x))
one.to.one = rbind(one.to.one,as.data.frame(cbind(x,y,variable,soil)))
soil = rep("clay_loam",length(x))
one.to.one = rbind(one.to.one,as.data.frame(cbind(x,y,variable,soil)))
colnames(one.to.one) = c("x","y","variable", "soil")
one.to.one$x <- as.numeric(as.character(one.to.one$x))
one.to.one$y <- as.numeric(as.character(one.to.one$y))


fluxes$type <- factor(fluxes$type.short, 
                            levels=c("r","t","d","ds","fw","dw",
                                     "sw","a","ds-sw"),
                            labels=c("Random","TWI","Drain",
                                     "Downspout", "Frontwalk",
                                     "Driveway","Sidewalk","All",
                                     "Downspout+Sidewalk"))
fluxes$soil <- factor(fluxes$soil, 
                      levels=c("measured","loam","clay_loam"),
                      labels=c("Measured Soil","Loam Soil","Clay Loam Soil"))
one.to.one$soil <- factor(one.to.one$soil, 
                      levels=c("measured","loam","clay_loam"),
                      labels=c("Measured Soil","Loam Soil","Clay Loam Soil"))
one.to.one$variable = factor(one.to.one$variable,
                                levels=c("runoff.diff.precip",
                                         "runoff.diff.rel"),
                                labels=c("% of Precip", "% of Max Reduction"))
nsoil = 2480
dot.size = 3.5 #2
text.size = 24 #10

# 3. PLOT ---------------------------------------------------------------------
melted.balance <- melt(subset(fluxes, runname == 'amend_pixels_TWI_0'| 
                                runname == 'amend_pixels_TWI_100',
                              select = c("runname","soil","runoff.precip",
                                         "drainage.precip","ET.precip")),
                       id = c("soil", "runname"))
melted.balance$runname = factor(melted.balance$runname,
                                levels=c("amend_pixels_TWI_0",
                                         "amend_pixels_TWI_100"),
                                labels=c("0% Amended Soil",
                                         "100% Amended Soil"))
plot.balance = ggplot(data = melted.balance,
                      aes(x = soil, y = value, fill = variable)) + 
               geom_bar(stat = 'identity', position = 'dodge') +
               facet_grid(~runname) +
               labs(x = "", y = "Percent of Precipitation") +
               scale_fill_brewer(name = sprintf("Flux"),
                                 direction = -1,
                                 labels = c("Runoff","Deep Drainage","ET"),
                                 palette= "Greys") + 
               theme_bw() +
               theme(text = element_text(size=text.size, 
                                         family="Segoe UI Semilight"),
                     axis.text = element_text(size=text.size-2, 
                                              family="Segoe UI Semilight"),
                     axis.title = element_text(size=text.size, 
                                               family="Segoe UI Semibold"),
                     legend.title = element_text(size=text.size, 
                                                 family="Segoe UI Semibold"),
                     strip.text = element_text(size=text.size, 
                                               family="Segoe UI Semibold"))
plot.balance
ggsave(sprintf("water_balances.png"),
       plot = plot.balance,
       device = "png",
       path = sprintf("%s/figures", results.dir),
       scale = 1,
       width = 6.5, height = 2.75, units = "in",
       dpi = 300)

# PLOT ------------------------------------------------------------------------  
melted.precip = melt(subset(fluxes, 
                            type.short == "t" | type.short == "d" | 
                              type.short == "r",
                            select = c("soil", "type.short", "amended.pixels",
                                       "runoff.diff.precip", 
                                       "runoff.diff.rel")),
                     id = c("soil", "type.short", "amended.pixels"))
melted.precip$value[which(melted.precip$variable == "runoff.diff.precip")] =
  -100*melted.precip$value[which(melted.precip$variable == 
                                   "runoff.diff.precip")]
melted.precip$variable = factor(melted.precip$variable,
                               levels=c("runoff.diff.precip",
                                        "runoff.diff.rel"),
                               labels=c("% of Precip", 
                                        "% of Max Reduction"))

plot.pixels = ggplot() +
              geom_line(data = one.to.one,
                        aes(x = x, y = y),
                        linetype = 2) +
                geom_point(data = melted.precip,
                           aes(x = 100*amended.pixels/nsoil,
                               y = value,
                               shape = type.short),
                           size = dot.size) +
                scale_shape_manual(name = "Amendment Type",
                                   breaks=c("r","d","t"),
                                   values=c(8,1,19),
                                   labels=c("Random","Drainage Area","TWI")) +
                scale_y_continuous(expand = c(0, 0.3)) +
                scale_x_continuous(expand = c(0, 0)) +
                coord_cartesian(clip = 'off') +
                labs(y = expression(paste(Delta," Runoff (%)")), 
                     x = "Pixels Amended (%)",
                     title = "") +
                facet_grid(variable~soil, scales = "free_y") +
                theme_bw() +
                theme(text = element_text(size=text.size, 
                                          family="Segoe UI Semilight"),
                      axis.title = element_text(size=text.size, 
                                                family="Segoe UI Semibold"),
                      legend.title = element_text(size=text.size, 
                                                  family="Segoe UI Semibold"),
                      strip.text = element_text(size=text.size, 
                                                family="Segoe UI Semibold"),
                      panel.spacing = unit(0.8, "lines"),
                      legend.position=c(0.13,0.86))
plot.pixels

plot.pixels.01 = ggplot() +
  geom_point(data = subset(melted.precip, 
                           variable == "% of Precip" & 
                             type.short == "r"),
             aes(x = 100*amended.pixels/nsoil,
                 y = value,
                 shape = type.short),
             size = dot.size) +
  scale_shape_manual(name = "Amendment Type",
                     breaks=c("r"),
                     values=c(1),
                     labels=c("Random")) +
  scale_y_continuous(expand = c(0, 0.3),
                     limits = c(0,15.5)) +
  scale_x_continuous(expand = c(0, 0),
                     limits = c(0,100)) +
  coord_cartesian(clip = 'off') +
  labs(y = expression(paste(Delta," Runoff (% of Precip)")), 
       x = "Pixels Amended (%)",
       title = "") +
  facet_grid(~soil) +
  theme_bw() +
  theme(text = element_text(size=text.size, 
                            family="Segoe UI Semilight"),
        axis.title = element_text(size=text.size, 
                                  family="Segoe UI Semibold"),
        legend.title = element_text(size=text.size, 
                                    family="Segoe UI Semibold"),
        strip.text = element_text(size=text.size, 
                                  family="Segoe UI Semibold"),
        panel.spacing = unit(2, "lines"),
        legend.position="none") #c(0.14,0.79)
plot.pixels.01

plot.pixels.02 = ggplot() +
  geom_point(data = subset(melted.precip, 
                           variable == "% of Precip"),
             aes(x = 100*amended.pixels/nsoil,
                 y = value,
                 shape = type.short),
             size = dot.size) +
  scale_shape_manual(name = "Amendment Type",
                     breaks=c("r","d","t"),
                     values=c(8,1,19),
                     labels=c("Random","Drainage Area","TWI")) +
  scale_y_continuous(expand = c(0, 0.3),
                     limits = c(0,15.5)) +
  scale_x_continuous(expand = c(0, 0),
                     limits = c(0,100)) +
  coord_cartesian(clip = 'off') +
  labs(y = expression(paste(Delta," Runoff (% of Precip)")), 
       x = "Pixels Amended (%)",
       title = "") +
  facet_grid(~soil) +
  theme_bw() +
  theme(text = element_text(size=text.size, 
                            family="Segoe UI Semilight"),
        axis.title = element_text(size=text.size, 
                                  family="Segoe UI Semibold"),
        legend.title = element_text(size=text.size, 
                                    family="Segoe UI Semibold"),
        strip.text = element_text(size=text.size, 
                                  family="Segoe UI Semibold"),
        panel.spacing = unit(2, "lines"),
        legend.position="none") #c(0.14,0.79)
plot.pixels.02

plot.pixels.03 = ggplot() +
  geom_point(data = subset(melted.precip, 
                           variable == "% of Max Reduction" & 
                             type.short == "r"),
             aes(x = 100*amended.pixels/nsoil,
                 y = value,
                 shape = type.short),
             size = dot.size) +
  scale_shape_manual(name = "Amendment Type",
                     breaks=c("r"),
                     values=c(1),
                     labels=c("Random")) +
  scale_y_continuous(expand = c(0, 0.3),
                     limits = c(0,100)) +
  scale_x_continuous(expand = c(0, 0),
                     limits = c(0,100)) +
  coord_cartesian(clip = 'off') +
  labs(y = expression(paste(Delta," Runoff (% of Max)")), 
       x = "Pixels Amended (%)",
       title = "") +
  facet_grid(~soil) +
  theme_bw() +
  theme(text = element_text(size=text.size, 
                            family="Segoe UI Semilight"),
        axis.title = element_text(size=text.size, 
                                  family="Segoe UI Semibold"),
        legend.title = element_text(size=text.size, 
                                    family="Segoe UI Semibold"),
        strip.text = element_text(size=text.size, 
                                  family="Segoe UI Semibold"),
        panel.spacing = unit(2, "lines"),
        legend.position="none") #c(0.14,0.79)
plot.pixels.03

plot.pixels.04 = ggplot() +
  geom_point(data = subset(melted.precip, 
                           variable == "% of Max Reduction"),
             aes(x = 100*amended.pixels/nsoil,
                 y = value,
                 shape = type.short),
             size = dot.size) +
  scale_shape_manual(name = "Amendment Type",
                     breaks=c("r","d","t"),
                     values=c(8,1,19),
                     labels=c("Random","Drainage Area","TWI")) +
  scale_y_continuous(expand = c(0, 0.3),
                     limits = c(0,100)) +
  scale_x_continuous(expand = c(0, 0),
                     limits = c(0,100)) +
  coord_cartesian(clip = 'off') +
  labs(y = expression(paste(Delta," Runoff (% of Max)")), 
       x = "Pixels Amended (%)",
       title = "") +
  facet_grid(~soil) +
  theme_bw() +
  theme(text = element_text(size=text.size, 
                            family="Segoe UI Semilight"),
        axis.title = element_text(size=text.size, 
                                  family="Segoe UI Semibold"),
        legend.title = element_text(size=text.size, 
                                    family="Segoe UI Semibold"),
        strip.text = element_text(size=text.size, 
                                  family="Segoe UI Semibold"),
        panel.spacing = unit(2, "lines"),
        legend.position="none") #c(0.18,0.21)
plot.pixels.04


# ggsave(sprintf("runoff_diff.png"),
#        plot = plot.pixels,
#        device = "png",
#        path = sprintf("%s/figures", results.dir),
#        scale = 1,
#        width = 6.5, height = 5, units = "in",
#        dpi = 300)


# PLOT ------------------------------------------------------------------------
color.palette = c("#FDBF6F", "#E31A1C", "#33A02C", "#1F78B4", "#CAB2D6")
plot.features01 = ggplot() +
                  geom_line(data = one.to.one,
                            aes(x = x, y = y),
                            linetype = 2) +
                  geom_point(data = subset(fluxes, type.short == "t" | 
                                             type.short == "d" | 
                                             type.short == "r"),
                             aes(x = 100*amended.pixels/nsoil,
                                 y = runoff.diff.rel,
                                 shape = type.short),
                             size = dot.size) +
                  geom_point(data = subset(fluxes, type.short != "t" & 
                                             type.short != "d" &
                                             type.short != "r"),
                             aes(x = 100*amended.pixels/nsoil,
                                 y = runoff.diff.rel, 
                                 fill = type,
                                 shape = size),
                             color = "black", size = dot.size) +
                  scale_shape_manual(name = sprintf("Type"),
                                     breaks=c("r","d","t", "s","l"),
                                     values=c(8,24,1,22,16),
                                     labels=c("Random","Drainage Area","TWI",
                                              "Small Feature","Large Feature")) +
                  scale_fill_manual(name = sprintf("Feature"),
                                    values = color.palette) +
                  guides(shape = guide_legend(order = 1),
                         fill = guide_legend(override.aes=list(shape=21), order = 2)) +
                  facet_grid(~soil) +
                  labs(y = expression(paste(Delta," Runoff (% of max)")), 
                       x = "Pixels Amended (%)",
                       title = "") +
                  scale_x_continuous(limits = c(0,5), expand = c(0, 0)) +
                  scale_y_continuous(limits = c(0,60), expand = c(0, 0)) +
                  coord_cartesian(clip = 'off') +
                  theme_bw() +
                  theme(text = element_text(size=text.size, family="Segoe UI Semilight"),
                        axis.title = element_text(size=text.size, family="Segoe UI Semibold"),
                        legend.title = element_text(size=text.size, family="Segoe UI Semibold"),
                        strip.text = element_text(size=text.size, family="Segoe UI Semibold"),
                        panel.spacing = unit(0.8, "lines"),
                        legend.margin=margin(-6,0,0,0),
                        legend.box.margin = margin(-6,0,0,0))
plot.features01

plot.features01b = ggplot() +
  geom_point(data = subset(fluxes, type.short == "t" | 
                             type.short == "d" | 
                             type.short == "r"),
             aes(x = 100*amended.pixels/nsoil,
                 y = runoff.diff.rel,
                 shape = type.short),
             size = dot.size) +
  scale_shape_manual(name = sprintf("Type"),
                     breaks=c("r","d","t"),
                     values=c(8,1,19),
                     labels=c("Random","Drainage Area","TWI")) +
  scale_fill_manual(name = sprintf("Feature"),
                    values = color.palette) +
  guides(shape = guide_legend(order = 1),
         fill = guide_legend(override.aes=list(shape=21), order = 2)) +
  facet_grid(~soil) +
  labs(y = expression(paste(Delta," Runoff (% of max)")), 
       x = "Pixels Amended (%)",
       title = "") +
  scale_x_continuous(limits = c(0,5), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0,60), expand = c(0, 0)) +
  coord_cartesian(clip = 'off') +
  theme_bw() +
  theme(text = element_text(size=text.size, 
                            family="Segoe UI Semilight"),
        axis.title = element_text(size=text.size, 
                                  family="Segoe UI Semibold"),
        legend.title = element_text(size=text.size, 
                                    family="Segoe UI Semibold"),
        strip.text = element_text(size=text.size, 
                                  family="Segoe UI Semibold"),
        panel.spacing = unit(0.8, "lines"),
        legend.position = "none")
plot.features01b


plot.features01c = ggplot() +
  geom_point(data = subset(fluxes, type.short == "t" | 
                             type.short == "d" | 
                             type.short == "r"),
             aes(x = 100*amended.pixels/nsoil,
                 y = runoff.diff.rel,
                 shape = type.short),
             size = dot.size) +
  geom_point(data = subset(fluxes, type.short != "t" & 
                             type.short != "d" &
                             type.short != "r"),
             aes(x = 100*amended.pixels/nsoil,
                 y = runoff.diff.rel, 
                 fill = type,
                 shape = size),
             color = "black", size = dot.size) +
  scale_shape_manual(name = sprintf("Type"),
                     breaks=c("r","d","t", "s","l"),
                     values=c(8,24,1,22,16),
                     labels=c("Random","Drainage Area","TWI",
                              "Small Feature","Large Feature")) +
  scale_fill_manual(name = sprintf("Feature"),
                    values = color.palette) +
  guides(shape = guide_legend(order = 1),
         fill = guide_legend(override.aes=list(shape=21), order = 2)) +
  facet_grid(~soil) +
  labs(y = expression(paste(Delta," Runoff (% of max)")), 
       x = "Pixels Amended (%)",
       title = "") +
  scale_x_continuous(limits = c(0,5), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0,60), expand = c(0, 0)) +
  coord_cartesian(clip = 'off') +
  theme_bw() +
  theme(text = element_text(size=text.size, family="Segoe UI Semilight"),
        axis.title = element_text(size=text.size, family="Segoe UI Semibold"),
        legend.title = element_text(size=text.size, family="Segoe UI Semibold"),
        strip.text = element_text(size=text.size, family="Segoe UI Semibold"),
        panel.spacing = unit(0.8, "lines"),
        legend.position = "none")
plot.features01c

ggsave(sprintf("runoff_diff_features.png"),
       plot = plot.features01,
       device = "png",
       path = sprintf("%s/figures", results.dir),
       scale = 1,
       width = 6.5, height = 3.25, units = "in",
       dpi = 300)


fluxes$improvement <- (fluxes$runoff.diff.rel/100)*(nsoil/fluxes$amended.pixels)
fluxes$improvement[which(fluxes$improvement < 0.5)] <- 0.5

plot.features02 = ggplot() +
                  geom_point(data = subset(fluxes, type.short == "t" | 
                                             type.short == "d" |
                                             type.short == "r"),
                             aes(x = nsoil/amended.pixels,
                                 y = improvement,
                                 shape = type.short),
                             size = dot.size) +
                  geom_point(data = subset(fluxes, type.short != "t" & 
                                             type.short != "d" &
                                             type.short != "r"),
                             aes(x = nsoil/amended.pixels,
                                 y = improvement, 
                                 fill = type,
                                 shape = size),
                             color = "black", size = dot.size) +
                  scale_shape_manual(name = sprintf("Type"),
                                     breaks=c("r","d","t", "s","l"),
                                     values=c(8,24,1,22,16),
                                     labels=c("Random","Drainage Area","TWI",
                                              "Small Feature","Large Feature")) +
                  scale_fill_manual(name = sprintf("Feature"),
                                    values = color.palette) +
                  guides(shape = guide_legend(order = 1),
                         fill = guide_legend(override.aes=list(shape=21), order = 2)) +
                  labs(y = "Factor of Improvement", 
                       x = "Parcels Amended",
                       title = "") +
                  scale_x_log10(breaks = c(1, 10, 100),
                                minor_breaks = c(c(1:9),10*c(1:9),100*c(1:5)),
                                expand = c(0, 0)) +
                  scale_y_log10(limits = c(0.5, 100),
                                breaks = c(0.5, 1, 10, 100),
                                labels = c("< 0.5", "1", "10", "100"),
                                minor_breaks = c(c(1:9),10*c(1:9),100),
                                expand = c(0,0)) +
                  coord_cartesian(clip = 'off') +
                  facet_grid(~soil) +
                  theme_bw() +
                  theme(text = element_text(size=text.size, family="Segoe UI Semilight"),
                        axis.title = element_text(size=text.size, family="Segoe UI Semibold"),
                        legend.title = element_text(size=text.size, family="Segoe UI Semibold"),
                        strip.text = element_text(size=text.size, family="Segoe UI Semibold"),
                        panel.spacing = unit(0.8, "lines"),
                        legend.margin=margin(-6,0,0,0),
                        legend.box.margin = margin(-6,0,0,0))
plot.features02

ggsave(sprintf("improvement_factor.png"),
       plot = plot.features02,
       device = "png",
       path = sprintf("%s/figures", results.dir),
       scale = 1,
       width = 6.5, height = 3.25, units = "in",
       dpi = 300)
