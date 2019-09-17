# functions_hourly_fluxes.R

# This suite of functions calculates and plot 1) the max hourly and 2) the
# overall cumulative errors as A) a depth, and B) relative to the input fluxes
# for I) CLM only, II) Parflow only, and III) the overall model.

# Includes three functions:
# 1. calculate_errors
# 2. calculate_balance_errors
# 3. plot_water_balance_errors

# calculate_errors ------------------------------------------------------------
# Given input and output fluxes, calculate error as depth and relative to input
calculate_errors <- function(input.fluxes, output.fluxes, errnames) {
  # Calculate errors
  err.depth = input.fluxes - output.fluxes
  err.rel = err.depth/input.fluxes
  cum.err.depth = cumsum(err.depth)
  cum.err.rel = cum.err.depth/cumsum(input.fluxes)
  
  # Replace infinite values with na
  is.na(err.rel) <- !is.finite(err.rel)
  is.na(cum.err.rel) <- !is.finite(cum.err.rel)
  
  errors = as.data.frame(cbind(err.depth, err.rel, cum.err.depth, cum.err.rel))
  colnames(errors) = errnames
  
  return(errors)
}


# calculate_balance_errors ----------------------------------------------------
# Given hourly balance data, calculate water balance errors for all models
calculate_balance_errors = function(hourly.balance) {
  # CLM error
  clm.input = hourly.balance$precipitation
  clm.output = rowSums(subset(hourly.balance, 
                              select = c(delta.storage.canopy, 
                                         delta.storage.snow, 
                                         evaporation, 
                                         transpiration, 
                                         evaptranssum)))
  clm.colnames = c("err.depth.CLM", "err.rel.CLM",
                   "cum.err.depth.CLM", "cum.err.rel.CLM")
  clm.errors = calculate_errors(clm.input, clm.output, clm.colnames)
  
  # PF error
  PF.input = hourly.balance$evaptranssum
  PF.output = rowSums(subset(hourly.balance, 
                             select = c(delta.storage.subsurface, 
                                        delta.storage.surface, 
                                        surface.runoff,
                                        recharge)))
  PF.colnames = c("err.depth.PF", "err.rel.PF", 
                  "cum.err.depth.PF", "cum.err.rel.PF")
  PF.errors = calculate_errors(PF.input, PF.output, PF.colnames)
  
  # Overall error
  overall.input = hourly.balance$precipitation
  overall.output = rowSums(subset(hourly.balance, 
                                  select = c(delta.storage.canopy,
                                             delta.storage.snow,
                                             evaporation,
                                             transpiration,
                                             delta.storage.subsurface,
                                             delta.storage.surface,
                                             surface.runoff, 
                                             recharge)))
  overall.colnames = c("err.depth", "err.rel", 
                       "cum.err.depth", "cum.err.rel")
  overall.errors = calculate_errors(overall.input, overall.output, overall.colnames)
  
  # Bind all errors together and return
  all.errors = as.data.frame(cbind(clm.errors, PF.errors, overall.errors))
  return(all.errors)
}