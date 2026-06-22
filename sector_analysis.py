#!/usr/bin/env python3
"""
US Stock Market Sector Analysis - SPDR Sector ETFs
===================================================
Pulls data from Yahoo Finance and displays a colored table showing:
- Last price, daily change %
- Trend Strength % (20-day moving average momentum)
- Regime Score (composite trend regime indicator)

Requirements:
    pip install yfinance pandas numpy rich

Usage:
    python sector_analysis.py
"""

import sys
from datetime import datetime

try:
    import yfinance as yf
    import pandas as pd
    import numpy as np
    LIVE_DATA = True
except ImportError:
    LIVE_DATA = False
    print("=" * 70)
    print("  WARNING: Required packages not installed.")
    print("  Install with: pip install yfinance pandas numpy rich")
    print("  Running with SAMPLE DATA for demonstration...")
    print("=" * 70)
    print()

try:
    from rich.console import Console
    from rich.table import Table
    from rich.text import Text
    from rich import box
    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False


# SPDR Sector ETF definitions
SECTOR_ETFS = {
    "XLK": "Technology",
    "XLI": "Industrial",
    "XLU": "Utilities",
    "XLY": "Consumer Discretionary",
    "XLF": "Financial",
    "XLB": "Materials",
    "XLC": "Communication",
    "XLV": "Health Care",
    "XLP": "Consumer Staples",
    "XLRE": "Real Estate",
    "XLE": "Energy",
}


def calculate_trend_strength(prices, period=20):
    """
    Calculate trend strength as the percentage change of the
    moving average over the lookback period.
    """
    if len(prices) < period + 1:
        return 0.0
    ma = prices.rolling(window=period).mean()
    if pd.isna(ma.iloc[-1]) or pd.isna(ma.iloc[-period]):
        return 0.0
    trend = ((ma.iloc[-1] - ma.iloc[-period]) / ma.iloc[-period]) * 100
    return round(trend, 2)


def get_trend_label(trend_pct):
    """Classify trend strength into labels."""
    abs_trend = abs(trend_pct)
    if abs_trend > 2.0:
        strength = "Strong "
    else:
        strength = ""

    if trend_pct > 0.5:
        return f"{strength}Bullish"
    elif trend_pct < -0.5:
        return f"{strength}Bearish"
    else:
        return "Neutral"


def calculate_regime_score(change_pct, trend_pct):
    """
    Calculate regime score (0-3) based on:
    - Daily momentum direction
    - Trend strength direction and magnitude
    
    Regime interpretations:
    0 = Lagging (negative momentum + negative trend)
    1 = Weakening (mixed signals)
    2 = Improving (positive momentum building)
    3 = Leading (strong positive momentum + strong positive trend)
    """
    score = 0

    # Daily change contribution
    if change_pct > 1.0:
        score += 1
    elif change_pct < -1.0:
        score -= 1

    # Trend direction contribution
    if trend_pct > 1.0:
        score += 1
    elif trend_pct < -1.0:
        score -= 1

    # Trend magnitude contribution
    if abs(trend_pct) > 2.5:
        if trend_pct > 0:
            score += 1
        else:
            score -= 1

    # Normalize to 0-3 range
    score = max(0, min(3, score + 1))
    return score


def get_regime_label(score):
    """Get regime label from score."""
    labels = {0: "Lagging", 1: "Weakening", 2: "Improving", 3: "Leading"}
    return labels.get(score, "Unknown")


def fetch_live_data():
    """Fetch live data from Yahoo Finance."""
    results = []
    symbols = list(SECTOR_ETFS.keys())

    print("Fetching data from Yahoo Finance...")
    print(f"Symbols: {', '.join(symbols)}")
    print()

    for symbol in symbols:
        try:
            ticker = yf.Ticker(symbol)
            # Get 60 days of history for moving average calculation
            hist = ticker.history(period="3mo")

            if hist.empty:
                print(f"  WARNING: No data for {symbol}")
                continue

            last_price = round(hist["Close"].iloc[-1], 2)
            prev_close = hist["Close"].iloc[-2] if len(hist) > 1 else last_price
            change_pct = round(((last_price - prev_close) / prev_close) * 100, 2)
            trend_pct = calculate_trend_strength(hist["Close"])
            trend_label = get_trend_label(trend_pct)
            regime_score = calculate_regime_score(change_pct, trend_pct)
            regime_label = get_regime_label(regime_score)

            results.append({
                "Symbol": symbol,
                "Sector": SECTOR_ETFS[symbol],
                "Last": last_price,
                "Change %": change_pct,
                "Trend %": trend_pct,
                "Trend Label": trend_label,
                "Regime Score": regime_score,
                "Regime Label": regime_label,
            })
        except Exception as e:
            print(f"  ERROR fetching {symbol}: {e}")

    # Sort by Change % descending
    results.sort(key=lambda x: x["Change %"], reverse=True)
    return results


def get_sample_data():
    """Return sample data for demonstration when live data unavailable."""
    return [
        {"Symbol": "XLK", "Sector": "Technology", "Last": 191.44, "Change %": 3.59, "Trend %": 4.56, "Trend Label": "Strong Bullish", "Regime Score": 3, "Regime Label": "Leading"},
        {"Symbol": "XLI", "Sector": "Industrial", "Last": 180.91, "Change %": 2.68, "Trend %": -0.16, "Trend Label": "Neutral", "Regime Score": 1, "Regime Label": "Weakening"},
        {"Symbol": "XLU", "Sector": "Utilities", "Last": 44.76, "Change %": 0.52, "Trend %": -0.9, "Trend Label": "Bearish", "Regime Score": 0, "Regime Label": "Lagging"},
        {"Symbol": "XLY", "Sector": "Consumer Discretionary", "Last": 117.16, "Change %": 0.48, "Trend %": -2.76, "Trend Label": "Strong Bearish", "Regime Score": 0, "Regime Label": "Lagging"},
        {"Symbol": "XLF", "Sector": "Financial", "Last": 53.57, "Change %": 0.43, "Trend %": -2.74, "Trend Label": "Strong Bearish", "Regime Score": 0, "Regime Label": "Lagging"},
        {"Symbol": "XLB", "Sector": "Materials", "Last": 51.81, "Change %": -0.71, "Trend %": -0.52, "Trend Label": "Bearish", "Regime Score": 1, "Regime Label": "Weakening"},
        {"Symbol": "XLC", "Sector": "Communication", "Last": 109.45, "Change %": -1.97, "Trend %": -2.81, "Trend Label": "Strong Bearish", "Regime Score": 0, "Regime Label": "Lagging"},
        {"Symbol": "XLV", "Sector": "Health Care", "Last": 149.4, "Change %": -2.87, "Trend %": -2.68, "Trend Label": "Strong Bearish", "Regime Score": 0, "Regime Label": "Lagging"},
        {"Symbol": "XLP", "Sector": "Consumer Staples", "Last": 83.3, "Change %": -2.94, "Trend %": -0.98, "Trend Label": "Bearish", "Regime Score": 1, "Regime Label": "Weakening"},
        {"Symbol": "XLRE", "Sector": "Real Estate", "Last": 43.86, "Change %": -3.31, "Trend %": 0.02, "Trend Label": "Neutral", "Regime Score": 1, "Regime Label": "Weakening"},
        {"Symbol": "XLE", "Sector": "Energy", "Last": 53.77, "Change %": -6.57, "Trend %": 2.12, "Trend Label": "Strong Bullish", "Regime Score": 2, "Regime Label": "Improving"},
    ]


def get_change_color(value):
    """Get color based on change percentage for Rich."""
    if value > 2.0:
        return "bright_green"
    elif value > 0.5:
        return "green"
    elif value > 0:
        return "dark_green"
    elif value > -1.0:
        return "yellow"
    elif value > -3.0:
        return "rgb(255,165,0)"  # orange
    else:
        return "red"


def get_trend_color(trend_pct, trend_label):
    """Get color based on trend classification for Rich."""
    if "Strong Bullish" in trend_label:
        return "bright_green"
    elif "Bullish" in trend_label:
        return "green"
    elif "Neutral" in trend_label:
        return "yellow"
    elif "Strong Bearish" in trend_label:
        return "red"
    elif "Bearish" in trend_label:
        return "rgb(255,165,0)"
    return "white"


def get_regime_color(score):
    """Get color based on regime score for Rich."""
    colors = {0: "red", 1: "yellow", 2: "rgb(255,165,0)", 3: "bright_green"}
    return colors.get(score, "white")


def get_row_bg_color(change_pct):
    """Get background color indicator based on daily change."""
    if change_pct > 2.0:
        return "on dark_green"
    elif change_pct > 0:
        return "on rgb(0,80,0)"
    elif change_pct > -1.0:
        return "on rgb(80,80,0)"
    elif change_pct > -3.0:
        return "on rgb(139,69,0)"
    else:
        return "on dark_red"


def display_rich_table(data):
    """Display data using Rich library with colors."""
    console = Console()

    table = Table(
        title="SPDR SECTOR FUNDs",
        title_style="bold white on dark_green",
        box=box.HEAVY_EDGE,
        show_header=True,
        header_style="bold white on grey30",
        border_style="grey50",
        pad_edge=True,
        padding=(0, 1),
    )

    table.add_column("Symbol", style="bold", justify="center", min_width=8)
    table.add_column("Sector", justify="left", min_width=24)
    table.add_column("Last", justify="right", min_width=8)
    table.add_column("Change %", justify="center", min_width=10)
    table.add_column("Trend Strength %", justify="center", min_width=22)
    table.add_column("Regime Score", justify="center", min_width=14)

    for row in data:
        change_color = get_change_color(row["Change %"])
        trend_color = get_trend_color(row["Trend %"], row["Trend Label"])
        regime_color = get_regime_color(row["Regime Score"])

        # Symbol
        symbol_text = Text(row["Symbol"], style="bold white")

        # Sector
        sector_text = Text(row["Sector"])

        # Last price
        last_text = Text(f"{row['Last']:.2f}", style="white")

        # Change %
        change_val = row["Change %"]
        change_sign = "+" if change_val > 0 else ""
        change_text = Text(f"{change_sign}{change_val:.2f}%", style=f"bold {change_color}")

        # Trend Strength
        trend_val = row["Trend %"]
        trend_sign = "" if trend_val < 0 else ""
        trend_str = f"{trend_val:.2f}% {row['Trend Label']}"
        trend_text = Text(trend_str, style=f"bold {trend_color}")

        # Regime Score
        regime_str = f"{row['Regime Score']} {row['Regime Label']}"
        regime_text = Text(regime_str, style=f"bold {regime_color}")

        table.add_row(
            symbol_text,
            sector_text,
            last_text,
            change_text,
            trend_text,
            regime_text,
        )

    console.print()
    console.print(table)
    console.print()
    console.print(
        f"  [dim]Data as of: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}[/dim]"
    )
    console.print(
        "  [dim]Source: Yahoo Finance | SPDR State Street Global Advisors[/dim]"
    )
    console.print()


def display_plain_table(data):
    """Fallback display using plain text with ANSI colors."""
    # ANSI color codes
    RESET = "\033[0m"
    BOLD = "\033[1m"
    RED = "\033[91m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    ORANGE = "\033[33m"
    WHITE = "\033[97m"
    BG_GREEN = "\033[42m"
    BG_RED = "\033[41m"
    BG_YELLOW = "\033[43m"
    BG_DARK_GREEN = "\033[48;5;22m"
    BG_ORANGE = "\033[48;5;208m"
    BG_DARK_RED = "\033[48;5;52m"

    def get_ansi_change_color(val):
        if val > 2.0:
            return GREEN + BOLD
        elif val > 0:
            return GREEN
        elif val > -1.0:
            return YELLOW
        elif val > -3.0:
            return ORANGE
        else:
            return RED + BOLD

    def get_ansi_row_bg(val):
        if val > 2.0:
            return BG_DARK_GREEN
        elif val > 0:
            return BG_DARK_GREEN
        elif val > -1.0:
            return BG_YELLOW
        elif val > -3.0:
            return BG_ORANGE
        else:
            return BG_DARK_RED

    # Header
    header_line = f"{BG_GREEN}{WHITE}{BOLD}"
    header_line += f"{'SPDR SECTOR FUNDs':^95}"
    header_line += RESET
    print()
    print(header_line)
    print()

    # Column headers
    hdr = f"  {BOLD}{'Symbol':<8}{'Sector':<26}{'Last':>8}{'Change %':>10}{'Trend Strength %':>22}{'Regime Score':>16}{RESET}"
    print(hdr)
    print("  " + "-" * 90)

    for row in data:
        bg = get_ansi_row_bg(row["Change %"])
        change_color = get_ansi_change_color(row["Change %"])

        change_val = row["Change %"]
        change_sign = "+" if change_val > 0 else ""
        change_str = f"{change_sign}{change_val:.2f}%"

        trend_str = f"{row['Trend %']:.2f}% {row['Trend Label']}"
        regime_str = f"{row['Regime Score']} {row['Regime Label']}"

        line = f"  {bg}{WHITE}"
        line += f"{row['Symbol']:<8}"
        line += f"{row['Sector']:<26}"
        line += f"{row['Last']:>8.2f}"
        line += f"{change_str:>10}"
        line += f"{trend_str:>22}"
        line += f"{regime_str:>16}"
        line += RESET

        print(line)

    print()
    print(f"  Data as of: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("  Source: Yahoo Finance | SPDR State Street Global Advisors")
    print()


def main():
    """Main function to run sector analysis."""
    print()
    print("=" * 60)
    print("   US STOCK MARKET - SPDR SECTOR ANALYSIS")
    print("=" * 60)
    print()

    # Fetch or use sample data
    if LIVE_DATA:
        data = fetch_live_data()
        if not data:
            print("ERROR: Could not fetch any data. Using sample data.")
            data = get_sample_data()
    else:
        data = get_sample_data()

    # Display the table
    if RICH_AVAILABLE:
        display_rich_table(data)
    else:
        display_plain_table(data)

    # Summary statistics
    print("  --- SUMMARY ---")
    leading = sum(1 for d in data if d["Regime Score"] == 3)
    improving = sum(1 for d in data if d["Regime Score"] == 2)
    weakening = sum(1 for d in data if d["Regime Score"] == 1)
    lagging = sum(1 for d in data if d["Regime Score"] == 0)
    avg_change = sum(d["Change %"] for d in data) / len(data) if data else 0

    print(f"  Leading: {leading} | Improving: {improving} | Weakening: {weakening} | Lagging: {lagging}")
    print(f"  Average Sector Change: {avg_change:.2f}%")
    print()

    # Market breadth indicator
    positive = sum(1 for d in data if d["Change %"] > 0)
    negative = len(data) - positive
    breadth = "BULLISH" if positive > negative else "BEARISH" if negative > positive else "NEUTRAL"
    print(f"  Market Breadth: {positive} up / {negative} down -> {breadth}")
    print()


if __name__ == "__main__":
    main()
