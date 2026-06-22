# US Stock Market - SPDR Sector Analysis

Analyzes all 11 SPDR Sector ETFs using **10 years of historical data** from Yahoo Finance. Available in both **R (RStudio)** and **Python** versions with color-coded dashboards.

## Features

- **10 Years of Yahoo Finance Data** - Full historical sector performance
- **Trend Strength Analysis** - 20-day moving average momentum indicator
- **Regime Scoring** - Composite trend regime indicator (0-3 scale)
- **Color-Coded Tables** - Green (bullish) through Red (bearish)
- **Multi-Timeframe Returns** - YTD, 1Y, 3Y, 5Y, 10Y returns
- **Sector Rotation Heatmap** - Monthly returns visualization
- **Normalized Performance Chart** - Compare all sectors over 10 years
- **Annualized Volatility** - Risk metric per sector

## SPDR Sector ETFs Covered

| Symbol | Sector |
|--------|--------|
| XLK | Technology |
| XLI | Industrial |
| XLU | Utilities |
| XLY | Consumer Discretionary |
| XLF | Financial |
| XLB | Materials |
| XLC | Communication |
| XLV | Health Care |
| XLP | Consumer Staples |
| XLRE | Real Estate |
| XLE | Energy |

---

## R Version (RStudio) - Recommended

### Install R Packages

```r
install.packages(c("quantmod", "dplyr", "gt", "TTR", "lubridate", "ggplot2", "tidyr", "htmltools"))
```

### Usage

**Option 1: R Script** (console output + HTML table)
```r
source("sector_analysis.R")
```

**Option 2: RMarkdown** (full interactive report with charts)
- Open `sector_analysis.Rmd` in RStudio
- Click **Knit** to generate the full HTML report
- Includes: color-coded tables, 10-year performance chart, monthly heatmap

### What the R version includes:
- Daily performance table (color-coded like the reference image)
- Long-term returns table (YTD through 10Y)
- 10-year normalized performance line chart
- Monthly sector rotation heatmap
- Market breadth summary

---

## Python Version

### Install Python Packages

```bash
pip install -r requirements.txt
```

### Usage

```bash
python sector_analysis.py        # Terminal colored table
python sector_analysis_html.py   # HTML report in browser
```

---

## Output Columns

| Column | Description |
|--------|-------------|
| **Symbol** | ETF ticker symbol |
| **Sector** | Market sector name |
| **Last** | Latest closing price |
| **Change %** | Daily percentage change |
| **Trend Strength %** | 20-day MA momentum + label (Strong Bullish/Bullish/Neutral/Bearish/Strong Bearish) |
| **Regime Score** | Composite indicator: 0=Lagging, 1=Weakening, 2=Improving, 3=Leading |
| **YTD / 1Y / 3Y / 5Y / 10Y** | Multi-timeframe cumulative returns |
| **Volatility** | 252-day annualized volatility |

## How It Works

- **Trend Strength**: Percentage change of the 20-day moving average over the lookback period
- **Regime Score**: Combines daily momentum direction and trend strength magnitude into a 0-3 composite score
- **Color Gradient**: Rows are dynamically colored based on daily change percentage
- **Normalized Chart**: All sectors rebased to 100 at start date for fair comparison

## File Structure

```
US-Stock-Market-Analysis/
├── sector_analysis.R          # R script (main analysis)
├── sector_analysis.Rmd        # RMarkdown (full report with charts)
├── sector_analysis.py         # Python terminal version
├── sector_analysis_html.py    # Python HTML report version
├── requirements.txt           # Python dependencies
└── README.md
```

## License

MIT
