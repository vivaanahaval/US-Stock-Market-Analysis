#!/usr/bin/env Rscript
# ==============================================================================
# Top 10 Stocks Per Sector - 12 Month Performance Analysis
# ==============================================================================
# Identifies the top 10 contributing stocks in each SPDR sector ETF
# and displays their 12-month performance
#
# Requirements:
#   install.packages(c("quantmod", "dplyr", "gt", "rvest", "TTR", "lubridate", "ggplot2"))
#
# Usage in RStudio:
#   source("sector_top_stocks.R")
# ==============================================================================

suppressPackageStartupMessages({
  library(quantmod)
  library(dplyr)
  library(gt)
  library(rvest)
  library(lubridate)
  library(ggplot2)
  library(tidyr)
})

# ==============================================================================
# SECTOR ETF HOLDINGS - Top constituents by weight for each SPDR Sector ETF
# ==============================================================================
# Note: These are the major holdings in each sector ETF.
# Holdings are sourced from SPDR fund fact sheets.

sector_holdings <- list(

  XLK = list(
    name = "Technology",
    stocks = c("AAPL", "MSFT", "NVDA", "AVGO", "CRM", "ORCL", "AMD", "ADBE", "ACN", "CSCO",
               "INTU", "IBM", "TXN", "QCOM", "NOW")
  ),

  XLI = list(
    name = "Industrial",
    stocks = c("GE", "CAT", "RTX", "UNP", "HON", "DE", "ETN", "ADP", "LMT", "BA",
               "UPS", "GD", "MMM", "ITW", "WM")
  ),

  XLU = list(
    name = "Utilities",
    stocks = c("NEE", "SO", "DUK", "CEG", "SRE", "AEP", "D", "PCG", "EXC", "XEL",
               "PEG", "ED", "WEC", "AWK", "ES")
  ),

  XLY = list(
    name = "Consumer Discretionary",
    stocks = c("AMZN", "TSLA", "MCD", "HD", "NKE", "LOW", "BKNG", "SBUX", "TJX", "ABNB",
               "MAR", "GM", "F", "ORLY", "CMG")
  ),

  XLF = list(
    name = "Financial",
    stocks = c("BRK-B", "JPM", "V", "MA", "BAC", "WFC", "GS", "MS", "SPGI", "AXP",
               "BLK", "C", "SCHW", "CB", "PGR")
  ),

  XLB = list(
    name = "Materials",
    stocks = c("LIN", "SHW", "APD", "FCX", "ECL", "NEM", "NUE", "VMC", "MLM", "DOW",
               "DD", "PPG", "CTVA", "CE", "IFF")
  ),

  XLC = list(
    name = "Communication",
    stocks = c("META", "GOOGL", "GOOG", "NFLX", "DIS", "CMCSA", "T", "VZ", "TMUS", "EA",
               "CHTR", "WBD", "OMC", "TTWO", "LYV")
  ),

  XLV = list(
    name = "Health Care",
    stocks = c("LLY", "UNH", "JNJ", "ABBV", "MRK", "TMO", "ABT", "PFE", "AMGN", "DHR",
               "ISRG", "BMY", "MDT", "SYK", "GILD")
  ),

  XLP = list(
    name = "Consumer Staples",
    stocks = c("PG", "COST", "WMT", "KO", "PEP", "PM", "MDLZ", "MO", "CL", "GIS",
               "KMB", "STZ", "SYY", "KHC", "HSY")
  ),

  XLRE = list(
    name = "Real Estate",
    stocks = c("PLD", "AMT", "EQIX", "SPG", "PSA", "O", "WELL", "DLR", "CCI", "VICI",
               "AVB", "EQR", "SBAC", "WY", "ARE")
  ),

  XLE = list(
    name = "Energy",
    stocks = c("XOM", "CVX", "COP", "EOG", "SLB", "MPC", "PSX", "VLO", "OXY",
               "WMB", "HAL", "DVN", "KMI", "FANG", "TPL")
  )
)

# ==============================================================================
# FETCH DATA & CALCULATE 12-MONTH PERFORMANCE
# ==============================================================================

cat("==============================================================================\n")
cat("   TOP 10 STOCKS PER SECTOR - 12 MONTH PERFORMANCE\n")
cat("==============================================================================\n\n")

end_date <- Sys.Date()
start_date <- end_date - years(1) - days(5)  # Extra days for safety

cat(sprintf("   Period: %s to %s (12 Months)\n\n", end_date - years(1), end_date))

# Function to fetch stock data and calculate 12-month return
fetch_stock_performance <- function(symbol, from_date, to_date) {
  tryCatch({
    data <- getSymbols(symbol, src = "yahoo", from = from_date, to = to_date, auto.assign = FALSE)
    if (is.null(data) || nrow(data) < 20) return(NULL)

    prices <- Cl(data)
    n <- nrow(data)

    # Current and start prices
    current_price <- round(as.numeric(tail(prices, 1)), 2)
    start_price <- as.numeric(prices[1])

    # 12-month return
    twelve_month_return <- round(((current_price - start_price) / start_price) * 100, 2)

    # 6-month return
    six_mo_idx <- max(1, n - 126)
    six_month_return <- round(((current_price - as.numeric(prices[six_mo_idx])) /
                                 as.numeric(prices[six_mo_idx])) * 100, 2)

    # 3-month return
    three_mo_idx <- max(1, n - 63)
    three_month_return <- round(((current_price - as.numeric(prices[three_mo_idx])) /
                                   as.numeric(prices[three_mo_idx])) * 100, 2)

    # 1-month return
    one_mo_idx <- max(1, n - 21)
    one_month_return <- round(((current_price - as.numeric(prices[one_mo_idx])) /
                                 as.numeric(prices[one_mo_idx])) * 100, 2)

    # 52-week high/low
    high_52w <- round(max(as.numeric(Hi(data)), na.rm = TRUE), 2)
    low_52w <- round(min(as.numeric(Lo(data)), na.rm = TRUE), 2)
    pct_from_high <- round(((current_price - high_52w) / high_52w) * 100, 2)

    return(data.frame(
      Symbol = symbol,
      Last_Price = current_price,
      Return_12M = twelve_month_return,
      Return_6M = six_month_return,
      Return_3M = three_month_return,
      Return_1M = one_month_return,
      High_52W = high_52w,
      Low_52W = low_52w,
      Pct_From_High = pct_from_high,
      stringsAsFactors = FALSE
    ))
  }, error = function(e) {
    return(NULL)
  })
}

# ==============================================================================
# PROCESS ALL SECTORS
# ==============================================================================

all_sector_results <- list()

for (etf in names(sector_holdings)) {
  sector_info <- sector_holdings[[etf]]
  cat(sprintf("Fetching %s (%s) stocks...\n", etf, sector_info$name))

  sector_results <- data.frame()

  for (stock in sector_info$stocks) {
    result <- fetch_stock_performance(stock, start_date, end_date)
    if (!is.null(result)) {
      sector_results <- rbind(sector_results, result)
    }
    Sys.sleep(0.3)  # Rate limiting
  }

  if (nrow(sector_results) > 0) {
    # Sort by 12-month return and take top 10
    sector_results <- sector_results %>%
      arrange(desc(Return_12M)) %>%
      head(10) %>%
      mutate(Rank = row_number())

    all_sector_results[[etf]] <- sector_results
    cat(sprintf("  -> Got %d stocks, Top performer: %s (%+.1f%%)\n",
                nrow(sector_results), sector_results$Symbol[1], sector_results$Return_12M[1]))
  }
  cat("\n")
}

# ==============================================================================
# DISPLAY RESULTS - CONSOLE OUTPUT
# ==============================================================================

cat("\n")
cat("##############################################################################\n")
cat("#                    TOP 10 STOCKS BY 12-MONTH RETURN                        #\n")
cat("##############################################################################\n\n")

for (etf in names(all_sector_results)) {
  sector_name <- sector_holdings[[etf]]$name
  results <- all_sector_results[[etf]]

  cat(sprintf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"))
  cat(sprintf("  %s (%s) - Top 10 Contributors (12-Month Performance)\n", etf, sector_name))
  cat(sprintf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"))
  cat(sprintf("  %-4s %-7s %8s %9s %8s %8s %8s %9s\n",
              "Rank", "Symbol", "Price", "12M Ret", "6M Ret", "3M Ret", "1M Ret", "From Hi"))
  cat(sprintf("  %s\n", paste(rep("-", 72), collapse = "")))

  for (i in 1:nrow(results)) {
    r <- results[i, ]
    cat(sprintf("  %-4d %-7s %8.2f %+8.1f%% %+7.1f%% %+7.1f%% %+7.1f%% %+8.1f%%\n",
                r$Rank, r$Symbol, r$Last_Price,
                r$Return_12M, r$Return_6M, r$Return_3M, r$Return_1M, r$Pct_From_High))
  }
  cat("\n")
}

# ==============================================================================
# GENERATE GT TABLES (HTML OUTPUT)
# ==============================================================================

cat("Generating HTML report with color-coded tables...\n\n")

# Function to create a GT table for one sector
create_sector_gt <- function(etf, results, sector_name) {

  display_df <- results %>%
    select(Rank, Symbol, Last_Price, Return_12M, Return_6M, Return_3M, Return_1M, Pct_From_High) %>%
    rename(
      `#` = Rank,
      `Price` = Last_Price,
      `12M %` = Return_12M,
      `6M %` = Return_6M,
      `3M %` = Return_3M,
      `1M %` = Return_1M,
      `From 52W Hi` = Pct_From_High
    )

  tbl <- display_df %>%
    gt() %>%
    tab_header(
      title = md(sprintf("**%s (%s) - Top 10 Stocks**", etf, sector_name)),
      subtitle = md(sprintf("*Ranked by 12-Month Return | %s to %s*",
                            end_date - years(1), end_date))
    ) %>%
    fmt_number(columns = Price, decimals = 2) %>%
    fmt_number(columns = c(`12M %`, `6M %`, `3M %`, `1M %`, `From 52W Hi`),
               decimals = 1, force_sign = TRUE) %>%
    tab_style(
      style = list(cell_text(color = "white", weight = "bold"), cell_fill(color = "#1a5c1a")),
      locations = cells_title()
    ) %>%
    tab_style(
      style = list(cell_text(color = "white", weight = "bold"), cell_fill(color = "#333333")),
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
    cols_align(align = "center", columns = everything())

  # Color rows based on 12M return
  for (i in 1:nrow(results)) {
    ret <- results$Return_12M[i]
    if (ret > 50) bg <- "#1a8c1a"
    else if (ret > 30) bg <- "#2d8f2d"
    else if (ret > 15) bg <- "#4CAF50"
    else if (ret > 5) bg <- "#6dbf6d"
    else if (ret > 0) bg <- "#8fbc8f"
    else if (ret > -10) bg <- "#d4a017"
    else if (ret > -20) bg <- "#e67e22"
    else bg <- "#c0392b"

    tbl <- tbl %>%
      tab_style(style = cell_fill(color = bg), locations = cells_body(rows = i))
  }

  tbl <- tbl %>%
    tab_options(
      table.background.color = "#1a1a2e",
      table.font.size = px(13)
    )

  return(tbl)
}

# Generate all sector tables and combine into one HTML file
html_content <- '<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Sector Top 10 Stocks - 12 Month Performance</title>
<style>
  body { background-color: #1a1a2e; color: white; font-family: "Segoe UI", sans-serif; padding: 20px; }
  h1 { text-align: center; color: #00ff88; margin-bottom: 5px; }
  .subtitle { text-align: center; color: #888; margin-bottom: 30px; }
  .sector-section { margin-bottom: 40px; }
  .summary-bar { background: #2a2a4a; border-radius: 8px; padding: 15px; margin-bottom: 30px;
                 border: 1px solid #444; text-align: center; }
  .summary-bar span { margin: 0 15px; font-size: 14px; }
</style>
</head>
<body>
<h1>TOP 10 STOCKS PER SECTOR</h1>
<p class="subtitle">Ranked by 12-Month Return | Data from Yahoo Finance</p>
<div class="summary-bar">
  <span>Analysis Date: ' 

html_content <- paste0(html_content, as.character(Sys.Date()))
html_content <- paste0(html_content, '</span>
  <span>Period: 12 Months</span>
  <span>Sectors: 11</span>
  <span>Stocks Analyzed: ', sum(sapply(all_sector_results, nrow)), '</span>
</div>
')

for (etf in names(all_sector_results)) {
  sector_name <- sector_holdings[[etf]]$name
  results <- all_sector_results[[etf]]
  tbl <- create_sector_gt(etf, results, sector_name)

  # Convert gt to HTML
  tbl_html <- as.character(as_raw_html(tbl))
  html_content <- paste0(html_content, '<div class="sector-section">\n', tbl_html, '\n</div>\n')
}

html_content <- paste0(html_content, '
<p style="text-align:center; color:#666; font-size:12px; margin-top:30px;">
  Source: Yahoo Finance | Generated: ', Sys.time(), '
</p>
</body></html>')

# Save HTML report
output_file <- file.path(getwd(), "sector_top_stocks_report.html")
writeLines(html_content, output_file)
cat(sprintf("HTML Report saved: %s\n\n", output_file))

# ==============================================================================
# SUMMARY: BEST PERFORMERS ACROSS ALL SECTORS
# ==============================================================================

cat("##############################################################################\n")
cat("#                OVERALL TOP 20 PERFORMERS (ALL SECTORS)                     #\n")
cat("##############################################################################\n\n")

# Combine all results
all_combined <- bind_rows(
  lapply(names(all_sector_results), function(etf) {
    all_sector_results[[etf]] %>%
      mutate(Sector_ETF = etf, Sector_Name = sector_holdings[[etf]]$name)
  })
)

# Overall top 20 by 12-month return
top_20 <- all_combined %>%
  arrange(desc(Return_12M)) %>%
  head(20)

cat(sprintf("  %-4s %-7s %-24s %8s %9s %8s %8s\n",
            "Rank", "Symbol", "Sector", "Price", "12M Ret", "6M Ret", "3M Ret"))
cat(sprintf("  %s\n", paste(rep("-", 72), collapse = "")))

for (i in 1:nrow(top_20)) {
  r <- top_20[i, ]
  cat(sprintf("  %-4d %-7s %-24s %8.2f %+8.1f%% %+7.1f%% %+7.1f%%\n",
              i, r$Symbol, r$Sector_Name, r$Last_Price,
              r$Return_12M, r$Return_6M, r$Return_3M))
}

# Bottom 10
cat("\n\n--- WORST 10 PERFORMERS (ALL SECTORS) ---\n\n")
bottom_10 <- all_combined %>%
  arrange(Return_12M) %>%
  head(10)

cat(sprintf("  %-4s %-7s %-24s %8s %9s %8s %8s\n",
            "Rank", "Symbol", "Sector", "Price", "12M Ret", "6M Ret", "3M Ret"))
cat(sprintf("  %s\n", paste(rep("-", 72), collapse = "")))

for (i in 1:nrow(bottom_10)) {
  r <- bottom_10[i, ]
  cat(sprintf("  %-4d %-7s %-24s %8.2f %+8.1f%% %+7.1f%% %+7.1f%%\n",
              i, r$Symbol, r$Sector_Name, r$Last_Price,
              r$Return_12M, r$Return_6M, r$Return_3M))
}

cat("\n==============================================================================\n")
cat("   Analysis Complete!\n")
cat(sprintf("   Open %s in your browser for the full colored report.\n", output_file))
cat("==============================================================================\n\n")
