#!/usr/bin/env python3
"""
US Stock Market Sector Analysis - HTML Report Generator
========================================================
Generates a beautiful HTML report that looks like the reference image.
Pulls data from Yahoo Finance (or uses sample data if unavailable).

Requirements:
    pip install yfinance pandas numpy

Usage:
    python sector_analysis_html.py
    # Opens sector_report.html in your default browser
"""

import sys
import os
import webbrowser
from datetime import datetime

try:
    import yfinance as yf
    import pandas as pd
    import numpy as np
    LIVE_DATA = True
except ImportError:
    LIVE_DATA = False


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
    """Calculate trend strength as MA momentum."""
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
    strength = "Strong " if abs_trend > 2.0 else ""
    if trend_pct > 0.5:
        return f"{strength}Bullish"
    elif trend_pct < -0.5:
        return f"{strength}Bearish"
    else:
        return "Neutral"


def calculate_regime_score(change_pct, trend_pct):
    """Calculate regime score (0-3)."""
    score = 0
    if change_pct > 1.0:
        score += 1
    elif change_pct < -1.0:
        score -= 1
    if trend_pct > 1.0:
        score += 1
    elif trend_pct < -1.0:
        score -= 1
    if abs(trend_pct) > 2.5:
        if trend_pct > 0:
            score += 1
        else:
            score -= 1
    return max(0, min(3, score + 1))


def get_regime_label(score):
    """Get regime label from score."""
    return {0: "Lagging", 1: "Weakening", 2: "Improving", 3: "Leading"}.get(score, "Unknown")


def fetch_live_data():
    """Fetch live data from Yahoo Finance."""
    results = []
    for symbol, sector in SECTOR_ETFS.items():
        try:
            ticker = yf.Ticker(symbol)
            hist = ticker.history(period="3mo")
            if hist.empty:
                continue
            last_price = round(hist["Close"].iloc[-1], 2)
            prev_close = hist["Close"].iloc[-2] if len(hist) > 1 else last_price
            change_pct = round(((last_price - prev_close) / prev_close) * 100, 2)
            trend_pct = calculate_trend_strength(hist["Close"])
            trend_label = get_trend_label(trend_pct)
            regime_score = calculate_regime_score(change_pct, trend_pct)
            regime_label = get_regime_label(regime_score)
            results.append({
                "Symbol": symbol, "Sector": sector, "Last": last_price,
                "Change %": change_pct, "Trend %": trend_pct,
                "Trend Label": trend_label, "Regime Score": regime_score,
                "Regime Label": regime_label,
            })
        except Exception as e:
            print(f"  Error fetching {symbol}: {e}")
    results.sort(key=lambda x: x["Change %"], reverse=True)
    return results


def get_sample_data():
    """Sample data for demonstration."""
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


def get_row_color(change_pct):
    """Get row background color based on change percentage."""
    if change_pct > 2.0:
        return "#2d8f2d"  # Dark green
    elif change_pct > 0.5:
        return "#4CAF50"  # Green
    elif change_pct > 0:
        return "#6dbf6d"  # Light green
    elif change_pct > -0.5:
        return "#c8c832"  # Yellow-green
    elif change_pct > -1.0:
        return "#d4a017"  # Dark yellow / gold
    elif change_pct > -2.0:
        return "#e67e22"  # Orange
    elif change_pct > -3.5:
        return "#d35400"  # Dark orange
    else:
        return "#c0392b"  # Red


def get_trend_color(trend_label):
    """Get trend text color."""
    if "Strong Bullish" in trend_label:
        return "#00ff00"
    elif "Bullish" in trend_label:
        return "#7dff7d"
    elif "Neutral" in trend_label:
        return "#ffff00"
    elif "Strong Bearish" in trend_label:
        return "#ff4444"
    elif "Bearish" in trend_label:
        return "#ff8c00"
    return "#ffffff"


def get_regime_color(score):
    """Get regime score color."""
    return {0: "#ff4444", 1: "#ffff00", 2: "#ff8c00", 3: "#00ff00"}.get(score, "#ffffff")


def generate_html(data):
    """Generate HTML report."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    data_source = "Yahoo Finance (Live)" if LIVE_DATA else "Sample Data (Demo)"

    rows_html = ""
    for row in data:
        bg_color = get_row_color(row["Change %"])
        trend_color = get_trend_color(row["Trend Label"])
        regime_color = get_regime_color(row["Regime Score"])

        change_sign = "+" if row["Change %"] > 0 else ""
        change_str = f"{change_sign}{row['Change %']:.2f}%"
        trend_str = f"{row['Trend %']:.2f}% {row['Trend Label']}"
        regime_str = f"{row['Regime Score']} {row['Regime Label']}"

        rows_html += f"""
        <tr style="background-color: {bg_color};">
            <td class="symbol"><strong>{row['Symbol']}</strong></td>
            <td class="sector">{row['Sector']}</td>
            <td class="number">{row['Last']:.2f}</td>
            <td class="number">{change_str}</td>
            <td class="center" style="color: {trend_color};">{trend_str}</td>
            <td class="center" style="color: {regime_color};">{regime_str}</td>
        </tr>"""

    # Summary stats
    leading = sum(1 for d in data if d["Regime Score"] == 3)
    improving = sum(1 for d in data if d["Regime Score"] == 2)
    weakening = sum(1 for d in data if d["Regime Score"] == 1)
    lagging = sum(1 for d in data if d["Regime Score"] == 0)
    avg_change = sum(d["Change %"] for d in data) / len(data) if data else 0
    positive = sum(1 for d in data if d["Change %"] > 0)
    negative = len(data) - positive
    breadth = "BULLISH" if positive > negative else "BEARISH" if negative > positive else "NEUTRAL"
    breadth_color = "#00ff00" if breadth == "BULLISH" else "#ff4444" if breadth == "BEARISH" else "#ffff00"

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SPDR Sector Analysis</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        body {{
            background-color: #1a1a2e;
            color: #ffffff;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            padding: 20px;
        }}
        .container {{
            max-width: 1000px;
            margin: 0 auto;
        }}
        h1 {{
            text-align: center;
            color: #00ff88;
            margin-bottom: 5px;
            font-size: 28px;
        }}
        .subtitle {{
            text-align: center;
            color: #888;
            margin-bottom: 20px;
            font-size: 14px;
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.3);
        }}
        thead tr {{
            background-color: #333333;
        }}
        th {{
            padding: 12px 15px;
            text-align: center;
            font-weight: bold;
            color: #ffffff;
            border-bottom: 2px solid #555;
            font-size: 14px;
        }}
        td {{
            padding: 10px 15px;
            color: #ffffff;
            border-bottom: 1px solid rgba(255,255,255,0.1);
            font-size: 13px;
            font-weight: 500;
        }}
        .symbol {{
            text-align: center;
            font-weight: bold;
        }}
        .sector {{
            text-align: left;
        }}
        .number {{
            text-align: right;
            font-family: 'Courier New', monospace;
        }}
        .center {{
            text-align: center;
            font-weight: bold;
        }}
        tr:hover {{
            filter: brightness(1.15);
            transition: filter 0.2s;
        }}
        .summary {{
            margin-top: 20px;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }}
        .summary-card {{
            background: #2a2a4a;
            border-radius: 8px;
            padding: 15px;
            text-align: center;
            border: 1px solid #444;
        }}
        .summary-card h3 {{
            color: #aaa;
            font-size: 12px;
            margin-bottom: 5px;
            text-transform: uppercase;
        }}
        .summary-card .value {{
            font-size: 24px;
            font-weight: bold;
        }}
        .footer {{
            text-align: center;
            margin-top: 20px;
            color: #666;
            font-size: 12px;
        }}
        .legend {{
            margin-top: 15px;
            padding: 15px;
            background: #2a2a4a;
            border-radius: 8px;
            border: 1px solid #444;
        }}
        .legend h3 {{
            color: #aaa;
            font-size: 13px;
            margin-bottom: 10px;
        }}
        .legend-items {{
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
            font-size: 12px;
        }}
        .legend-item {{
            display: flex;
            align-items: center;
            gap: 5px;
        }}
        .legend-dot {{
            width: 12px;
            height: 12px;
            border-radius: 3px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>SPDR SECTOR FUNDs</h1>
        <p class="subtitle">US Stock Market Sector Analysis | {data_source} | {timestamp}</p>

        <table>
            <thead>
                <tr>
                    <th>Symbol</th>
                    <th>Sector</th>
                    <th>Last</th>
                    <th>Change %</th>
                    <th>Trend Strength %</th>
                    <th>Regime Score</th>
                </tr>
            </thead>
            <tbody>
                {rows_html}
            </tbody>
        </table>

        <div class="summary">
            <div class="summary-card">
                <h3>Market Breadth</h3>
                <div class="value" style="color: {breadth_color};">{breadth}</div>
                <div style="color: #aaa; font-size: 12px;">{positive} up / {negative} down</div>
            </div>
            <div class="summary-card">
                <h3>Average Change</h3>
                <div class="value" style="color: {'#00ff00' if avg_change > 0 else '#ff4444'};">{avg_change:+.2f}%</div>
            </div>
            <div class="summary-card">
                <h3>Leading Sectors</h3>
                <div class="value" style="color: #00ff00;">{leading}</div>
            </div>
            <div class="summary-card">
                <h3>Lagging Sectors</h3>
                <div class="value" style="color: #ff4444;">{lagging}</div>
            </div>
        </div>

        <div class="legend">
            <h3>REGIME SCORE LEGEND</h3>
            <div class="legend-items">
                <div class="legend-item">
                    <div class="legend-dot" style="background: #00ff00;"></div>
                    <span>3 = Leading (Strong bullish momentum)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-dot" style="background: #ff8c00;"></div>
                    <span>2 = Improving (Building momentum)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-dot" style="background: #ffff00;"></div>
                    <span>1 = Weakening (Mixed signals)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-dot" style="background: #ff4444;"></div>
                    <span>0 = Lagging (Negative momentum)</span>
                </div>
            </div>
        </div>

        <div class="footer">
            <p>Data Source: Yahoo Finance | SPDR State Street Global Advisors</p>
            <p>Trend Strength: 20-day moving average momentum | Regime: Composite trend indicator</p>
        </div>
    </div>
</body>
</html>"""
    return html


def main():
    """Main function."""
    print("=" * 60)
    print("   SPDR SECTOR ANALYSIS - HTML REPORT GENERATOR")
    print("=" * 60)
    print()

    if LIVE_DATA:
        print("Fetching live data from Yahoo Finance...")
        data = fetch_live_data()
        if not data:
            print("Could not fetch live data. Using sample data.")
            data = get_sample_data()
    else:
        print("Using sample data (install yfinance for live data)")
        data = get_sample_data()

    html = generate_html(data)

    output_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sector_report.html")
    with open(output_file, "w") as f:
        f.write(html)

    print(f"\nReport generated: {output_file}")
    print()

    # Try to open in browser
    try:
        webbrowser.open(f"file://{output_file}")
        print("Opening in default browser...")
    except Exception:
        print("Open the HTML file in your browser to view the report.")


if __name__ == "__main__":
    main()
