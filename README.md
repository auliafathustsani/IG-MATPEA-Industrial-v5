# IG-MATPEA Industrial v5

> **Industrial Grade Multi-Asset Trend-Pullback Expert Advisor for MetaTrader 5**

[![Platform](https://img.shields.io/badge/Platform-MetaTrader%205-blue)](https://www.metatrader5.com/)
[![Language](https://img.shields.io/badge/Language-MQL5-green)](https://www.mql5.com/)
[![Version](https://img.shields.io/badge/Version-5.00-orange)]()
[![Status](https://img.shields.io/badge/Status-Academic%20Testing-yellow)]()

---

## 1. Project Overview

**IG-MATPEA Industrial v5** adalah Expert Advisor (EA) untuk MetaTrader 5 yang dikembangkan sebagai proyek akademik untuk membangun, menguji, mengoptimasi, dan mengevaluasi sistem trading algoritmik.

Nama proyek:

> **Industrial Grade Multi-Asset Trend-Pullback Expert Advisor (IG-MATPEA)**

EA dirancang menggunakan pendekatan **trend-following + pullback** dengan beberapa lapisan filter entry serta sistem manajemen risiko.

Tujuan utama pengembangan adalah memperoleh sistem yang:

- memiliki aturan entry dan exit yang objektif;
- dapat diuji secara historis;
- memiliki pengendalian risiko;
- tidak menggunakan Martingale;
- tidak menggunakan Grid;
- tidak menggunakan HFT;
- membatasi drawdown;
- dapat dikembangkan untuk multi-asset;
- dapat dievaluasi menggunakan backtest dan forward test.

> **Catatan:** Hasil yang tersedia pada versi saat ini belum dapat dianggap sebagai validasi final 10 instrumen karena keterbatasan data historis tick pada terminal pengujian.

---

# 2. Project Objectives

Tujuan pengembangan IG-MATPEA Industrial v5 adalah:

1. Membuat EA berbasis MQL5 untuk MetaTrader 5.
2. Menerapkan strategi trend-following dan pullback.
3. Menggunakan indikator teknikal sebagai filter entry.
4. Menerapkan position sizing berbasis risiko.
5. Menerapkan Stop Loss dan Take Profit berbasis ATR.
6. Mengimplementasikan Break-Even dan Trailing Stop.
7. Membatasi daily loss.
8. Membatasi maximum drawdown.
9. Menghindari Martingale, Grid, dan HFT.
10. Melakukan optimasi parameter.
11. Melakukan backtest menggunakan data historis.
12. Melakukan forward testing.
13. Mempersiapkan arsitektur untuk pengujian multi-asset.
14. Mengevaluasi hasil berdasarkan profit, drawdown, Profit Factor, Sharpe Ratio, dan jumlah transaksi.

---

# 3. Project Scope

Versi saat ini berfokus pada pengembangan dan validasi awal EA pada MetaTrader 5.

### Scope utama

- Platform: MetaTrader 5
- Bahasa: MQL5
- Strategi: Trend-following + Pullback
- Timeframe pengujian: H1
- Instrumen validasi utama: EURUSDm
- Broker/server pengujian: Exness-MT5Real29
- Initial deposit: USD 10,000
- Tester leverage: 1:1
- Model: Every tick based on real ticks
- Periode pengujian: 2019.10.05–2026.10.05

---

# 4. System Architecture

Secara konseptual EA terdiri dari beberapa lapisan:

```text
Market Data
     │
     ▼
Trend Detection
     │
     ├── EMA 50/200
     ├── ADX
     └── DI+/DI-
     │
     ▼
Pullback Detection
     │
     ├── ATR
     └── Price Pullback
     │
     ▼
Entry Confirmation
     │
     ├── RSI
     └── Candle Body Ratio
     │
     ▼
Risk Management
     │
     ├── Position Sizing
     ├── Stop Loss
     ├── Take Profit
     ├── Daily Loss Limit
     └── Maximum Drawdown
     │
     ▼
Trade Execution
     │
     ├── Buy
     └── Sell
     │
     ▼
Position Management
     │
     ├── Break-Even
     ├── Trailing Stop
     ├── Trend Failure Exit
     └── Time Exit
```

---

# 5. Trading Logic

## 5.1 Trend Detection

EMA digunakan untuk menentukan arah trend utama.

### Bullish

```text
EMA 50 > EMA 200
```

### Bearish

```text
EMA 50 < EMA 200
```

EA tidak mencari entry secara acak. Entry hanya dipertimbangkan ketika arah trend utama telah memenuhi kondisi.

---

## 5.2 ADX Filter

ADX digunakan untuk mengukur kekuatan trend.

Parameter:

```text
ADX Period = 14
Minimum ADX = 21
```

EA juga menggunakan perubahan ADX untuk membantu menghindari kondisi ketika kekuatan trend sedang melemah.

---

## 5.3 Directional Movement Filter

Directional Index digunakan untuk memastikan arah momentum.

### Buy

```text
DI+ > DI-
```

### Sell

```text
DI- > DI+
```

Dengan demikian, EMA menentukan trend utama sementara DI membantu mengonfirmasi arah tekanan pasar.

---

# 6. Pullback Entry

EA tidak langsung membuka posisi ketika trend terdeteksi.

Harga harus terlebih dahulu mengalami pullback terhadap trend.

ATR digunakan untuk menormalisasi jarak pullback berdasarkan volatilitas instrumen.

Parameter hasil optimasi:

```text
ATR Period = 14
Pullback ATR = 0.20
```

Konsep:

```text
Strong Trend
     │
     ▼
Price moves with trend
     │
     ▼
Pullback
     │
     ▼
Confirmation
     │
     ▼
Entry
```

Pendekatan ini bertujuan menghindari entry setelah harga bergerak terlalu jauh dari area trend.

---

# 7. RSI Filter

RSI digunakan sebagai filter momentum tambahan.

Parameter hasil optimasi:

### Buy

```text
RSI Minimum = 45
RSI Maximum = 60
```

### Sell

```text
RSI Minimum = 28
RSI Maximum = 45
```

RSI tidak digunakan sebagai sistem reversal mandiri, tetapi sebagai filter tambahan terhadap kondisi entry.

---

# 8. Candle Quality Filter

EA menggunakan rasio body candle terhadap total range.

Rumus konseptual:

```text
Body Ratio = |Close - Open| / (High - Low)
```

Parameter:

```text
Minimum Body Ratio = 0.60
```

Semakin tinggi rasio body terhadap range, semakin dominan pergerakan candle tersebut dibandingkan wick.

Filter ini digunakan untuk menghindari entry pada candle dengan struktur yang terlalu lemah.

---

# 9. Buy Conditions

Secara umum, posisi BUY membutuhkan kombinasi kondisi berikut:

```text
1. EMA 50 > EMA 200
2. ADX >= 21
3. ADX tidak melemah secara signifikan
4. DI+ > DI-
5. Harga memenuhi kondisi pullback
6. RSI berada pada 45–60
7. Candle memenuhi minimum body ratio
8. Tidak terdapat posisi aktif pada simbol yang sama
9. Daily loss limit belum tercapai
10. Maximum drawdown protection belum aktif
11. Spread memenuhi batas
12. Risk/exposure masih diperbolehkan
```

Jika seluruh filter terpenuhi, EA dapat mengirim order BUY.

---

# 10. Sell Conditions

Secara umum, posisi SELL membutuhkan:

```text
1. EMA 50 < EMA 200
2. ADX >= 21
3. ADX tidak melemah secara signifikan
4. DI- > DI+
5. Harga memenuhi kondisi pullback
6. RSI berada pada 28–45
7. Candle memenuhi minimum body ratio
8. Tidak terdapat posisi aktif pada simbol yang sama
9. Daily loss limit belum tercapai
10. Maximum drawdown protection belum aktif
11. Spread memenuhi batas
12. Risk/exposure masih diperbolehkan
```

Jika seluruh filter terpenuhi, EA dapat mengirim order SELL.

---

# 11. Exit Management

EA menggunakan beberapa mekanisme exit.

## 11.1 Stop Loss

Stop Loss berbasis ATR:

```text
SL = 2.0 × ATR
```

Pendekatan ATR membuat jarak Stop Loss menyesuaikan volatilitas pasar.

---

## 11.2 Take Profit

Take Profit:

```text
TP = 3.0 × ATR
```

Risk-to-reward secara nominal dasar:

```text
2 ATR : 3 ATR
```

atau sekitar:

```text
1 : 1.5
```

sebelum memperhitungkan spread, slippage, dan biaya transaksi.

---

## 11.3 Break-Even

Break-Even aktif ketika posisi telah bergerak sesuai arah profit sebesar:

```text
1.0 × ATR
```

Tujuannya mengurangi risiko ketika posisi sudah memiliki keuntungan.

---

## 11.4 Trailing Stop

Trailing Stop:

```text
1.5 × ATR
```

Trailing digunakan untuk mempertahankan peluang mengikuti trend sambil mengunci sebagian keuntungan ketika harga bergerak lebih jauh.

---

## 11.5 Trend Failure Exit

Posisi dapat ditutup ketika struktur trend gagal.

Contoh konsep BUY:

```text
Bid < EMA 50
dan
EMA 50 < EMA 200
```

Untuk SELL digunakan kondisi berlawanan.

---

## 11.6 Time Exit

EA juga memiliki batas waktu posisi.

Parameter:

```text
Maximum Bars = 72
```

Time exit terutama digunakan ketika posisi telah terlalu lama terbuka dan tidak menunjukkan perkembangan profit yang memadai.

---

# 12. Risk Management

Risk management merupakan salah satu komponen utama EA.

Parameter:

```text
Risk Per Trade       = 0.75%
Daily Loss Limit     = 3%
Maximum Drawdown     = 25%
Maximum Exposure     = 100%
```

Position sizing dihitung berdasarkan risiko yang ditentukan terhadap jarak Stop Loss.

Tujuan utama:

> membatasi kerugian per transaksi sehingga satu transaksi tidak memberikan dampak yang terlalu besar terhadap equity.

---

# 13. No Martingale

EA **tidak menggunakan Martingale**.

Ukuran posisi tidak dinaikkan secara progresif setelah mengalami kerugian.

Tidak terdapat pola:

```text
Loss → lot × 2
Loss → lot × 4
Loss → lot × 8
```

Position sizing tetap dikendalikan oleh risk percentage.

---

# 14. No Grid

EA **tidak menggunakan Grid Trading**.

EA tidak membuka serangkaian posisi pada interval harga tertentu seperti:

```text
BUY
BUY
BUY
BUY
BUY
```

untuk mengejar harga rata-rata.

Maksimal satu posisi EA pada simbol yang sama diterapkan sebagai salah satu kontrol.

---

# 15. No HFT

EA tidak dirancang sebagai High Frequency Trading.

Entry dibatasi pada **new bar**, sehingga EA tidak membuka transaksi berkali-kali pada setiap tick.

Timeframe utama pengujian:

```text
H1
```

---

# 16. No-Leverage Mode

EA memiliki mekanisme internal untuk membatasi exposure.

Pengujian dilakukan dengan:

```text
Tester Leverage = 1:1
```

Tujuannya adalah membuat skenario pengujian yang konservatif dan tidak mengandalkan leverage tinggi untuk memperbesar ukuran posisi.

> **Important:** `1:1` pada Strategy Tester adalah parameter simulasi. Ini tidak berarti leverage akun broker secara otomatis berubah menjadi 1:1.

---

# 17. Instruments Target

Arsitektur proyek dirancang untuk pengembangan multi-asset.

Target instrumen:

| No. | Category | Instrument |
|---:|---|---|
| 1 | Forex | EURUSDm |
| 2 | Forex | USDJPYm |
| 3 | Metal | XAUUSDm |
| 4 | Metal | XAGUSDm |
| 5 | Index | US30 / US500 |
| 6 | Index | JP225 |
| 7 | Crypto | BTCUSDm |
| 8 | Crypto | ETHUSDm |
| 9 | Energy | USOILm |
| 10 | Energy | UKOILm |

### Validation Status

**EURUSDm** adalah instrumen yang telah memiliki hasil backtest dan forward test yang terdokumentasi dalam proyek ini.

Sembilan instrumen lainnya belum dianggap tervalidasi secara final karena keterbatasan historical tick data yang tersedia pada terminal pengujian.

---

# 18. Broker and Account

Pengujian dilakukan menggunakan environment Exness MT5.

```text
Broker:
Exness

Server:
Exness-MT5Real29

Currency:
USD

Initial Deposit:
10,000 USD

Tester Leverage:
1:1
```

Akun real digunakan sebagai referensi environment/symbol untuk Strategy Tester dan **bukan untuk melakukan trading real dalam proyek ini**.

---

# 19. Backtest Methodology

Pengujian utama menggunakan:

```text
Model:
Every tick based on real ticks
```

Periode:

```text
2019.10.05 – 2026.10.05
```

Timeframe:

```text
H1
```

Initial deposit:

```text
$10,000
```

Instrumen:

```text
EURUSDm
```

---

# 20. Optimization Methodology

Optimasi dilakukan dengan MetaTrader 5 Strategy Tester.

Parameter yang dioptimasi meliputi:

```text
Pullback ATR
Buy RSI Minimum
Buy RSI Maximum
Sell RSI Minimum
Sell RSI Maximum
Minimum Body Ratio
```

Ruang pencarian awal menghasilkan:

```text
5,040 combinations
```

Fast Genetic Optimization digunakan sehingga sebagian kombinasi dievaluasi melalui proses optimasi genetik.

Hasil yang dipilih adalah **Pass 153**.

---

# 21. Selected Optimization Result

Parameter Pass 153:

```text
Pullback ATR       = 0.20
Buy RSI Min        = 45
Buy RSI Max        = 60
Sell RSI Min       = 28
Sell RSI Max       = 45
Minimum Body Ratio = 0.60
```

Parameter trend dan risk management:

```text
Fast EMA            = 50
Slow EMA            = 200
ADX Period          = 14
Minimum ADX         = 21
ATR Period          = 14

Risk Per Trade      = 0.75%
SL ATR              = 2.0
TP ATR              = 3.0
Break-Even ATR      = 1.0
Trailing ATR        = 1.5
```

---

# 22. Full Backtest Result

Full-period test:

```text
Symbol:
EURUSDm

Period:
2019.10.05–2026.10.05

Timeframe:
H1

Deposit:
$10,000

Leverage:
1:1

Model:
Every tick based on real ticks
```

Hasil:

| Metric | Result |
|---|---:|
| Net Profit | +$172.73 |
| Gross Profit | $1,139.54 |
| Gross Loss | -$966.81 |
| Profit Factor | 1.18 |
| Expected Payoff | $1.16 |
| Sharpe Ratio | 3.39 |
| Max Balance DD | 1.68% |
| Max Equity DD | 2.01% |
| Total Trades | 149 |
| Profit Trades | 88 |
| Loss Trades | 61 |
| Win Rate | 59.06% |

---

# 23. Full Backtest Trade Statistics

### Long Trades

```text
Long Trades = 80
Winning Long Trades = 43
Win Rate = 53.75%
```

### Short Trades

```text
Short Trades = 69
Winning Short Trades = 45
Win Rate = 65.22%
```

### Overall

```text
Profit Trades = 88
Loss Trades = 61
Win Rate = 59.06%
```

Maximum consecutive sequence:

```text
Maximum Consecutive Wins  = 9
Maximum Consecutive Losses = 5
```

---

# 24. Forward Test

Forward test menggunakan:

```text
Forward = 1/3
```

Parameter tidak dioptimasi ulang pada forward segment.

Hasil forward:

| Metric | Result |
|---|---:|
| Net Profit | +$109.36 |
| Gross Profit | $391.19 |
| Gross Loss | -$281.83 |
| Profit Factor | 1.39 |
| Expected Payoff | $2.54 |
| Sharpe Ratio | 4.63 |
| Max Balance DD | 0.81% |
| Max Equity DD | 1.05% |
| Total Trades | 43 |
| Profit Trades | 26 |
| Loss Trades | 17 |
| Win Rate | 60.47% |

Hasil ini menunjukkan bahwa parameter yang dipilih tetap menghasilkan performa positif pada forward segment.

Namun, jumlah transaksi hanya 43 sehingga diperlukan pengujian out-of-sample yang lebih panjang untuk memperoleh validasi yang lebih kuat.

---

# 25. Training / Non-Forward Segment

Pada konfigurasi Forward 1/3, report training/non-forward yang tersedia menunjukkan:

```text
Bars = 29,019
Net Profit = +$65.03
Profit Factor = 1.10
Max Equity DD = 2.01%
Sharpe Ratio = 6.59
Total Trades = 106
Win Rate = 58.49%
```

Data ini harus dibedakan dari forward test.

**Forward murni** yang digunakan dalam laporan adalah hasil:

```text
Net Profit = +$109.36
PF = 1.39
DD = 1.05%
Trades = 43
```

---

# 26. History Quality

Salah satu keterbatasan penting adalah:

```text
History Quality = 26%
```

Walaupun model Strategy Tester dipilih:

```text
Every tick based on real ticks
```

nilai History Quality yang tersedia pada terminal adalah 26%.

Artinya, hasil pengujian harus diperlakukan sebagai hasil penelitian/eksperimen berdasarkan data yang tersedia, bukan sebagai bukti bahwa seluruh tujuh tahun telah tersedia dalam bentuk historical tick berkualitas penuh.

---

# 27. Performance Target

Target proyek:

```text
Monthly Return Target = 3–5%
Annual Return Target  = 50–70%
Maximum DD            = 25–30%
Maximum Loss Months   = ≤ 6 months/year
```

Evaluasi saat ini:

| Requirement | Evaluation |
|---|---|
| Monthly 3–5% | Not achieved |
| Annual 50–70% | Not achieved |
| Max DD 25–30% | Achieved with large margin |
| No Martingale | Achieved |
| No Grid | Achieved |
| No HFT | Achieved |
| Backtest 7 years | Tested |
| Forward test | Completed |
| 10 instruments | Pending |

Kesimpulannya, versi saat ini lebih berhasil dari sisi **risk control** daripada sisi **return target**.

---

# 28. Strengths

Kekuatan utama sistem:

1. Entry memiliki aturan objektif.
2. Trend utama menggunakan EMA 50/200.
3. Kekuatan trend menggunakan ADX.
4. Arah trend dikonfirmasi dengan DI+ dan DI-.
5. Pullback dinormalisasi menggunakan ATR.
6. RSI digunakan sebagai momentum filter.
7. Candle quality digunakan sebagai entry filter.
8. Stop Loss berbasis volatilitas.
9. Take Profit berbasis volatilitas.
10. Break-Even tersedia.
11. Trailing Stop tersedia.
12. Daily loss protection tersedia.
13. Maximum drawdown protection tersedia.
14. Tidak menggunakan Martingale.
15. Tidak menggunakan Grid.
16. Tidak menggunakan HFT.
17. Menggunakan new-bar entry.
18. Memiliki proses optimasi.
19. Memiliki forward test.
20. Struktur dapat dikembangkan menjadi multi-asset.

---

# 29. Limitations

Keterbatasan saat ini:

1. History Quality hanya 26%.
2. Validasi penuh baru tersedia untuk EURUSDm.
3. Forward test hanya menghasilkan 43 transaksi.
4. Return masih jauh dari target 3–5% per bulan.
5. Return tahunan belum mencapai 50–70%.
6. Belum tersedia validasi out-of-sample jangka panjang untuk seluruh target instrumen.
7. Kondisi spread dan slippage real dapat berbeda dari tester.
8. Hasil backtest tidak menjamin hasil trading real.
9. Perhitungan exposure no-leverage pada EA merupakan pembatasan internal dan bukan pengganti spesifikasi margin broker.
10. Validasi 10 instrumen membutuhkan historical tick data yang konsisten dan dapat direproduksi.

---

# 30. Installation

## Requirements

- MetaTrader 5
- MetaEditor
- MQL5
- Broker yang menyediakan simbol terkait
- Historical data untuk backtesting

## Steps

1. Buka MetaTrader 5.
2. Klik **File → Open Data Folder**.
3. Buka:

```text
MQL5/Experts/
```

4. Salin:

```text
IG_MATPEA_Industrial_v5.mq5
```

ke folder tersebut.

5. Buka MetaEditor.
6. Buka file EA.
7. Tekan:

```text
F7
```

8. Pastikan compilation tidak menghasilkan error.
9. Kembali ke MetaTrader 5.
10. Buka Navigator.
11. Cari EA pada bagian Expert Advisors.
12. Jalankan melalui Strategy Tester.

---

# 31. Backtest Procedure

Buka:

```text
View → Strategy Tester
```

Gunakan:

```text
Expert:
IG_MATPEA_Industrial_v5

Symbol:
EURUSDm

Period:
H1

Model:
Every tick based on real ticks

From:
2019.10.05

To:
2026.10.05

Deposit:
10000 USD

Leverage:
1:1
```

Gunakan parameter Pass 153.

Kemudian klik:

```text
Start
```

Simpan report dan screenshot hasil Strategy Tester untuk dokumentasi proyek.

---

# 32. Forward Testing Procedure

1. Buka Strategy Tester.
2. Pilih EA `IG_MATPEA_Industrial_v5`.
3. Pilih `EURUSDm`.
4. Pilih H1.
5. Gunakan tanggal pengujian yang sama.
6. Aktifkan **Forward**.
7. Pilih **1/3**.
8. Pastikan parameter menggunakan Pass 153.
9. Jangan melakukan optimasi ulang pada forward segment.
10. Jalankan test.
11. Simpan report.
12. Dokumentasikan hasil.

Tujuan forward test adalah melihat apakah parameter yang dipilih masih bekerja pada data yang tidak digunakan secara langsung untuk pemilihan parameter.

---

# 33. Recommended Project Structure

Struktur repository GitHub yang disarankan:

```text
IG-MATPEA-Industrial-v5/
│
├── MQL5/
│   └── Experts/
│       └── IG_MATPEA_Industrial_v5.mq5
│
├── Report/
│   └── Laporan_IG-MATPEA_Industrial_v5.docx
│
├── Backtest/
│   ├── EURUSDm_Full_Backtest.txt
│   └── EURUSDm_Forward_Test.txt
│
├── Screenshots/
│   ├── tester_settings.png
│   ├── optimization_pass153.png
│   ├── full_backtest.png
│   └── forward_test.png
│
├── README.md
│
└── LICENSE
```

---

# 34. Suggested Evidence Files

Untuk dokumentasi akademik, disarankan repository berisi:

### Source Code

```text
IG_MATPEA_Industrial_v5.mq5
```

### Report

```text
Laporan_IG-MATPEA_Industrial_v5.docx
```

### Backtest

```text
EURUSDm_Full_Backtest.txt
```

### Forward

```text
EURUSDm_Forward_Test.txt
```

### Screenshots

```text
tester_settings.png
optimization_pass153.png
full_backtest.png
forward_test.png
```

---

# 35. Reproducibility

Untuk membuat eksperimen dapat direproduksi, gunakan:

```text
Broker/Server:
Exness-MT5Real29

Symbol:
EURUSDm

Timeframe:
H1

Period:
2019.10.05–2026.10.05

Deposit:
$10,000

Tester Leverage:
1:1

Model:
Every tick based on real ticks

EA:
IG_MATPEA_Industrial_v5

Optimization Pass:
153
```

Parameter yang digunakan juga harus disimpan bersama report.

---

# 36. Academic Disclaimer

Proyek ini dibuat untuk tujuan akademik dan pengujian sistem trading algoritmik.

Hasil backtest dan forward test:

- tidak menjamin keuntungan masa depan;
- sangat bergantung pada kualitas historical data;
- dapat berubah akibat spread;
- dapat berubah akibat slippage;
- dapat berubah akibat biaya transaksi;
- dapat berbeda antar broker;
- tidak dapat dianggap sebagai jaminan performa akun real.

EA ini tidak dimaksudkan sebagai rekomendasi investasi atau jaminan keuntungan finansial.

---

# 37. Conclusion

IG-MATPEA Industrial v5 berhasil dikembangkan sebagai Expert Advisor MetaTrader 5 menggunakan pendekatan trend-following dan pullback.

Sistem menggabungkan:

```text
EMA
ADX
DI+/DI-
ATR
RSI
Candle Quality
Risk Management
Break-Even
Trailing Stop
Trend Failure Exit
Time Exit
```

Pada full backtest EURUSDm, sistem menghasilkan:

```text
Net Profit = +$172.73
Profit Factor = 1.18
Sharpe Ratio = 3.39
Max Equity DD = 2.01%
```

Pada forward test:

```text
Net Profit = +$109.36
Profit Factor = 1.39
Sharpe Ratio = 4.63
Max Equity DD = 1.05%
```

Hasil tersebut menunjukkan indikasi performa positif dengan drawdown relatif rendah pada data yang diuji.

Namun, sistem belum memenuhi target return:

```text
3–5% per month
50–70% per year
```

dan belum dapat diklaim sebagai sistem multi-asset tervalidasi penuh karena historical tick data yang memadai belum tersedia untuk seluruh 10 instrumen.

---

# 38. Future Development

Pengembangan berikutnya yang direkomendasikan:

1. Mendapatkan historical tick data berkualitas untuk seluruh instrumen.
2. Melakukan validasi 10 instrumen.
3. Membuat instrument-specific parameter profile.
4. Melakukan walk-forward analysis.
5. Melakukan extended out-of-sample testing.
6. Menguji robustness terhadap perubahan spread.
7. Menguji sensitivity terhadap parameter.
8. Menguji Monte Carlo atau randomization analysis.
9. Membandingkan hasil antar instrumen.
10. Menghasilkan portfolio equity curve.
11. Menghasilkan monthly return heatmap.
12. Menghasilkan drawdown curve.
13. Mengukur korelasi antar instrumen.
14. Menguji portfolio-level risk management.

---

# 39. Project Status

**Current Version: `v5.00`**

### Completed

- [x] EA MQL5 developed
- [x] Successfully compiled
- [x] Trend-following strategy
- [x] Pullback strategy
- [x] EMA filter
- [x] ADX filter
- [x] DI filter
- [x] RSI filter
- [x] ATR risk management
- [x] Stop Loss
- [x] Take Profit
- [x] Break-Even
- [x] Trailing Stop
- [x] Daily loss protection
- [x] Maximum drawdown protection
- [x] No Martingale
- [x] No Grid
- [x] No HFT
- [x] Optimization
- [x] Full backtest
- [x] Forward test
- [x] Academic report

### Pending

- [ ] Complete 10-instrument historical validation
- [ ] High-quality tick data validation
- [ ] Extended out-of-sample test
- [ ] Walk-forward analysis
- [ ] Portfolio-level validation
- [ ] Cross-asset correlation analysis

---

# 40. Project Files

Repository utama:

```text
IG-MATPEA-Industrial-v5
```

File utama:

```text
MQL5/Experts/IG_MATPEA_Industrial_v5.mq5
```

Dokumen laporan:

```text
Report/Laporan_IG-MATPEA_Industrial_v5.docx
```

Dokumentasi:

```text
README.md
```

---

# 41. Author

**IG-MATPEA Industrial v5**

MetaTrader 5 / MQL5 Expert Advisor Project

Developed for academic research, algorithmic trading system development, backtesting, optimization, and performance evaluation.

---

## 42. Final Note

> **Important:** Angka performa yang tercantum dalam README ini adalah hasil pengujian proyek pada environment dan historical data yang tersedia. Hasil tersebut tidak boleh dianggap sebagai jaminan keuntungan atau sebagai bukti bahwa EA akan menghasilkan performa yang sama pada kondisi pasar real.

**Project Status: Academic Research / Experimental**
