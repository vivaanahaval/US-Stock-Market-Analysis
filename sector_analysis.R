#!/usr/bin/env Rscript
# ==============================================================================
# US Stock Market - SPDR Sector Analysis (R Version)
# ==============================================================================
# Pulls last 10 years of sector ETF data from Yahoo Finance
# Generates a color-coded sector performance table similar to the reference image
#
# Requirements:
#   install.packages(c("quantmod", "dplyr", "gt", "TTR", "lubridate", "htmltools"))
#
# Usage in RStudio:
#   source("sector_analysis.R")
#   Or run interactively section by section
# ==============================================================================

# --- Load Libraries -----------------------------------------------------------
suppressPackageStartupMessages({
  library(quantmod)
  library(dplyr)
  library(gt)
  library(TTR)
  library(lubridate)
})

# --- Configuration ------------------------------------------------------------

# SPDR Sector ETFs
sector_etfs <- data.frame(

  Symbol = c("XLK", "XLI", "XLU", "XLY", "XLF", "XLB", "XLC", "XLV", "XLP", "XLRE", "XLE"),
  Sector = c("Technology", "Industrial", "Utilities", "Consumer Discretionary",
             "Financial", "Materials", "Communication", "Health Care",
             "Consumer Staples", "Real Estate", "Energy"),
  stringsAsFactors = FALSE
)

# Date range: Last 10 years
end_date <- Sys.Date()
start_date <- end_date - years(10)

cat("==============================================================\n")
cat("   US STOCK MARKET - SPDR SECTOR ANALYSIS (R)\n")
cat("==============================================================\n\n")
cat(sprintf("   Date Range: %s to %s (10 years)\n", start_date, end_date))
cat(sprintf("   Analysis Date: %s\n\n", Sys.Date()))

# --- Fetch Data from Yahoo Finance -------------------------------------------

cat("Fetching 10 years of data from Yahoo Finance...\n\n")

# Function to safely download data
fetch_sector_data <- function(symbol, from_date, to_date) {
  tryCatch({
    data <- getSymbols(symbol, src = "yahoo", from = from_date, to = to_date, auto.assign = FALSE)
    cat(sprintf("  [OK] %s - %d trading days loaded\n", symbol, nrow(data)))
    return(data)
  }, error = function(e) {
    cat(sprintf("  [ERROR] %s - %s\n", symbol, e$message))
    return(NULL)
  })
}

# Download all sector ETF data
all_data <- list()
for (sym in sector_etfs$Symbol) {
  all_data[[sym]] <- fetch_sector_data(sym, start_date, end_date)
}

cat("\n")

# --- Calculate Metrics --------------------------------------------------------

cat("Calculating trend strength and regime scores...\n\n")

# Function to calculate trend strength (20-day MA momentum)
calc_trend_strength <- function(prices, period = 20) {
  if (length(prices) < period + 1) return(0)
  ma <- SMA(prices, n = period)
  # Percentage change of MA over the lookback period
  current_ma <- tail(na.omit(ma), 1)
  past_ma <- na.omit(ma)[length(na.omit(ma)) - period]
  if (is.na(current_ma) || is.na(past_ma) || past_ma == 0) return(0)
  trend <- ((current_ma - past_ma) / past_ma) * 100
  return(round(trend, 2))
}

# Function to get trend label
get_trend_label <- function(trend_pct) {
  abs_trend <- abs(trend_pct)
  strength <- ifelse(abs_trend > 2.0, "Strong ", "")
  if (trend_pct > 0.5) {
    return(paste0(strength, "Bullish"))
  } else if (trend_pct < -0.5) {
    return(paste0(strength, "Bearish"))
  } else {
    return("Neutral")
  }
}

# Function to calculate regime score (0-3)
calc_regime_score <- function(change_pct, trend_pct) {
  score <- 0
  # Daily change contribution
  if (change_pct > 1.0) score <- score + 1
  if (change_pct < -1.0) score <- score - 1
  # Trend direction contribution
  if (trend_pct > 1.0) score <- score + 1
  if (trend_pct < -1.0) score <- score - 1
  # Trend magnitude contribution
  if (abs(trend_pct) > 2.5) {
    if (trend_pct > 0) score <- score + 1
    else score <- score - 1
  }
  # Normalize to 0-3
  return(max(0, min(3, score + 1)))
}

# Get regime label
get_regime_label <- function(score) {
  labels <- c("Lagging", "Weakening", "Improving", "Leading")
  return(labels[score + 1])
}

# --- Build Results Table ------------------------------------------------------

results <- data.frame(
  Symbol = character(),
  Sector = character(),
  Last = numeric(),
  Change_Pct = numeric(),
  Trend_Pct = numeric(),
  Trend_Label = character(),
  Regime_Score = integer(),
  Regime_Label = character(),
  YTD_Return = numeric(),
  One_Year_Return = numeric(),
  Three_Year_Return = numeric(),
  Five_Year_Return = numeric(),
  Ten_Year_Return = numeric(),
  Volatility_252d = numeric(),
  stringsAsFactors = FALSE
)

for (i in 1:nrow(sector_etfs)) {
  sym <- sector_etfs$Symbol[i]
  sector_name <- sector_etfs$Sector[i]
  data <- all_data[[sym]]

  if (is.null(data)) next

  # Get closing prices
  close_col <- paste0(sym, ".Close")
  prices <- Cl(data)

  n <- nrow(data)
  if (n < 252) next  # Need at least 1 year of data

  # Current price and daily change
  last_price <- round(as.numeric(tail(prices, 1)), 2)
  prev_price <- as.numeric(prices[n - 1])
  change_pct <- round(((last_price - prev_price) / prev_price) * 100, 2)

  # Trend strength (20-day MA momentum)
  trend_pct <- calc_trend_strength(as.numeric(prices))
  trend_label <- get_trend_label(trend_pct)

  # Regime score
  regime_score <- calc_regime_score(change_pct, trend_pct)
  regime_label <- get_regime_label(regime_score)

  # YTD Return
  ytd_start_idx <- which(index(data) >= as.Date(paste0(year(end_date), "-01-01")))[1]
  if (!is.na(ytd_start_idx)) {
    ytd_return <- round(((last_price - as.numeric(prices[ytd_start_idx])) /
                           as.numeric(prices[ytd_start_idx])) * 100, 2)
  } else {
    ytd_return <- NA
  }

  # 1-Year Return
  one_yr_idx <- max(1, n - 252)
  one_yr_return <- round(((last_price - as.numeric(prices[one_yr_idx])) /
                            as.numeric(prices[one_yr_idx])) * 100, 2)

  # 3-Year Return
  three_yr_idx <- max(1, n - 756)
  three_yr_return <- round(((last_price - as.numeric(prices[three_yr_idx])) /
                              as.numeric(prices[three_yr_idx])) * 100, 2)

  # 5-Year Return
  five_yr_idx <- max(1, n - 1260)
  five_yr_return <- round(((last_price - as.numeric(prices[five_yr_idx])) /
                             as.numeric(prices[five_yr_idx])) * 100, 2)

  # 10-Year Return (full dataset)
  ten_yr_return <- round(((last_price - as.numeric(prices[1])) /
                            as.numeric(prices[1])) * 100, 2)

  # 252-day Annualized Volatility
  returns <- diff(log(as.numeric(prices)))
  vol_252 <- round(sd(tail(returns, 252)) * sqrt(252) * 100, 2)

  results <- rbind(results, data.frame(
    Symbol = sym,
    Sector = sector_name,
    Last = last_price,
    Change_Pct = change_pct,
    Trend_Pct = trend_pct,
    Trend_Label = trend_label,
    Regime_Score = regime_score,
    Regime_Label = regime_label,
    YTD_Return = ytd_return,
    One_Year_Return = one_yr_return,
    Three_Year_Return = three_yr_return,
    Five_Year_Return = five_yr_return,
    Ten_Year_Return = ten_yr_return,
    Volatility_252d = vol_252,
    stringsAsFactors = FALSE
  ))
}

# Sort by daily change (descending)
results <- results %>% arrange(desc(Change_Pct))

# --- Display Results ----------------------------------------------------------

cat("\n--- SECTOR PERFORMANCE SUMMARY ---\n\n")

# Print a simple console table
cat(sprintf("  %-6s %-24s %8s %9s %12s %18s %14s\n",
            "Symbol", "Sector", "Last", "Change%", "Trend%", "Trend Label", "Regime"))
cat(paste0("  ", paste(rep("-", 95), collapse = ""), "\n"))

for (i in 1:nrow(results)) {
  r <- results[i, ]
  change_sign <- ifelse(r$Change_Pct > 0, "+", "")
  cat(sprintf("  %-6s %-24s %8.2f %s%7.2f%% %10.2f%%  %-14s %d %s\n",
              r$Symbol, r$Sector, r$Last,
              change_sign, r$Change_Pct,
              r$Trend_Pct, r$Trend_Label,
              r$Regime_Score, r$Regime_Label))
}

# --- Generate Beautiful GT Table (HTML) ---------------------------------------

cat("\n\nGenerating color-coded HTML table...\n")

# Prepare display dataframe
display_df <- results %>%
  mutate(
    `Change %` = sprintf("%+.2f%%", Change_Pct),
    `Trend Strength %` = sprintf("%.2f%% %s", Trend_Pct, Trend_Label),
    `Regime Score` = sprintf("%d %s", Regime_Score, Regime_Label),
    `YTD %` = sprintf("%+.2f%%", YTD_Return),
    `1Y Return %` = sprintf("%+.2f%%", One_Year_Return),
    `3Y Return %` = sprintf("%+.2f%%", Three_Year_Return),
    `5Y Return %` = sprintf("%+.2f%%", Five_Year_Return),
    `10Y Return %` = sprintf("%+.2f%%", Ten_Year_Return),
    `Volatility` = sprintf("%.1f%%", Volatility_252d)
  ) %>%
  select(Symbol, Sector, Last, `Change %`, `Trend Strength %`, `Regime Score`,
         `YTD %`, `1Y Return %`, `3Y Return %`, `5Y Return %`, `10Y Return %`, Volatility)

# Function to get background color for a row based on change %
get_row_color <- function(change_pct) {
  if (change_pct > 2.0) return("#2d8f2d")
  if (change_pct > 0.5) return("#4CAF50")
  if (change_pct > 0) return("#6dbf6d")
  if (change_pct > -0.5) return("#c8c832")
  if (change_pct > -1.0) return("#d4a017")
  if (change_pct > -2.0) return("#e67e22")
  if (change_pct > -3.5) return("#d35400")
  return("#c0392b")
}

# Create the GT table
sector_table <- display_df %>%
  gt() %>%
  tab_header(
    title = md("**SPDR SECTOR FUNDs**"),
    subtitle = md(sprintf("*US Stock Market Sector Analysis | %s | 10-Year Data from Yahoo Finance*", Sys.Date()))
  ) %>%
  tab_style(
    style = cell_text(color = "white", weight = "bold"),
    locations = cells_title()
  ) %>%
  tab_style(
    style = cell_fill(color = "#1a5c1a"),
    locations = cells_title()
  ) %>%
  tab_style(
    style = list(
      cell_text(color = "white", weight = "bold"),
      cell_fill(color = "#333333")
    ),
    locations = cells_column_labels()
  ) %>%
  tab_style(
    style = cell_text(color = "white"),
    locations = cells_body()
  ) %>%
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_body(columns = Symbol)
  ) %>%
  cols_align(align = "center", columns = c(Symbol, `Change %`, `Trend Strength %`, `Regime Score`)) %>%
  cols_align(align = "right", columns = c(Last, `YTD %`, `1Y Return %`, `3Y Return %`,
                                           `5Y Return %`, `10Y Return %`, Volatility))

# Apply row-by-row background coloring based on Change %
for (i in 1:nrow(results)) {
  bg_color <- get_row_color(results$Change_Pct[i])
  sector_table <- sector_table %>%
    tab_style(
      style = cell_fill(color = bg_color),
      locations = cells_body(rows = i)
    )
}

# Add source note
sector_table <- sector_table %>%
  tab_source_note(
    source_note = md(sprintf("*Source: Yahoo Finance | SPDR State Street Global Advisors | Data: %s to %s*",
                             start_date, end_date))
  ) %>%
  tab_options(
    table.background.color = "#1a1a2e",
    table.font.size = px(13),
    heading.background.color = "#1a5c1a",
    source_notes.background.color = "#1a1a2e",
    source_notes.font.size = px(11)
  )

# Save the table as HTML
output_file <- file.path(getwd(), "sector_report.html")
gtsave(sector_table, output_file)
cat(sprintf("\n  HTML Report saved: %s\n", output_file))

# --- Additional Analysis: Long-term Performance Table -------------------------

cat("\n\n--- LONG-TERM PERFORMANCE (10 Years) ---\n\n")
cat(sprintf("  %-6s %-24s %8s %8s %8s %8s %9s %8s\n",
            "Symbol", "Sector", "YTD", "1-Year", "3-Year", "5-Year", "10-Year", "Vol"))
cat(paste0("  ", paste(rep("-", 82), collapse = ""), "\n"))

long_term <- results %>% arrange(desc(Ten_Year_Return))
for (i in 1:nrow(long_term)) {
  r <- long_term[i, ]
  cat(sprintf("  %-6s %-24s %+7.1f%% %+7.1f%% %+7.1f%% %+7.1f%% %+8.1f%% %6.1f%%\n",
              r$Symbol, r$Sector,
              r$YTD_Return, r$One_Year_Return,
              r$Three_Year_Return, r$Five_Year_Return,
              r$Ten_Year_Return, r$Volatility_252d))
}

# --- Summary Statistics -------------------------------------------------------

cat("\n\n--- MARKET SUMMARY ---\n")
leading <- sum(results$Regime_Score == 3)
improving <- sum(results$Regime_Score == 2)
weakening <- sum(results$Regime_Score == 1)
lagging <- sum(results$Regime_Score == 0)
avg_change <- mean(results$Change_Pct)
positive <- sum(results$Change_Pct > 0)
negative <- nrow(results) - positive
breadth <- ifelse(positive > negative, "BULLISH",
                  ifelse(negative > positive, "BEARISH", "NEUTRAL"))

cat(sprintf("\n  Regime Distribution: Leading=%d | Improving=%d | Weakening=%d | Lagging=%d\n",
            leading, improving, weakening, lagging))
cat(sprintf("  Average Sector Change: %+.2f%%\n", avg_change))
cat(sprintf("  Market Breadth: %d up / %d down -> %s\n", positive, negative, breadth))
cat(sprintf("  Best Performer Today: %s (%s) %+.2f%%\n",
            results$Symbol[1], results$Sector[1], results$Change_Pct[1]))
cat(sprintf("  Worst Performer Today: %s (%s) %+.2f%%\n",
            results$Symbol[nrow(results)], results$Sector[nrow(results)],
            results$Change_Pct[nrow(results)]))
cat(sprintf("  Best 10Y Return: %s (%s) %+.1f%%\n",
            long_term$Symbol[1], long_term$Sector[1], long_term$Ten_Year_Return[1]))

cat("\n==============================================================\n")
cat("   Analysis Complete!\n")
cat("   Open sector_report.html in your browser for the full report.\n")
cat("==============================================================\n\n")
