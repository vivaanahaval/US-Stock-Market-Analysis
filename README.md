# US Stock Market - SPDR Sector Analysis

A Python tool that pulls live data from Yahoo Finance to analyze all 11 SPDR Sector ETFs and displays a color-coded sector performance dashboard.

## Features

- **Live Yahoo Finance Data** - Pulls real-time prices and historical data
- **Trend Strength Analysis** - 20-day moving average momentum indicator
- **Regime Scoring** - Composite trend regime indicator (0-3 scale)
- **Color-Coded Output** - Green (bullish) through Red (bearish)
- **Market Breadth Summary** - Overall market sentiment indicator
- **Two Output Modes** - Terminal (colored table) and HTML report

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

## Installation

```bash
git clone https://github.com/vivaanahaval/US-Stock-Market-Analysis.git
cd US-Stock-Market-Analysis
pip install -r requirements.txt
```

## Usage

### Terminal Version (colored table)
```bash
python sector_analysis.py
```

### HTML Report Version (opens in browser)
```bash
python sector_analysis_html.py
```

## Output Columns

| Column | Description |
|--------|-------------|
| **Symbol** | ETF ticker symbol |
| **Sector** | Market sector name |
| **Last** | Latest closing price |
| **Change %** | Daily percentage change |
| **Trend Strength %** | 20-day MA momentum + label (Strong Bullish/Bullish/Neutral/Bearish/Strong Bearish) |
| **Regime Score** | Composite indicator: 0=Lagging, 1=Weakening, 2=Improving, 3=Leading |

## How It Works

- **Trend Strength**: Measures the percentage change of the 20-day moving average over the lookback period
- **Regime Score**: Combines daily momentum direction and trend strength magnitude into a 0-3 composite score
- **Color Gradient**: Rows are dynamically colored based on daily change percentage

## Screenshot

```
  Symbol  Sector                      Last  Change %    Trend Strength %    Regime Score
  --------------------------------------------------------------------------------------
  XLK     Technology                191.44    +3.59%  4.56% Strong Bullish     3 Leading
  XLI     Industrial                180.91    +2.68%      -0.16% Neutral       1 Weakening
  XLU     Utilities                  44.76    +0.52%      -0.90% Bearish       0 Lagging
  ...
```

## License

MIT
