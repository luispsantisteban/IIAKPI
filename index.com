```html
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>IIA — Dashboard KPI</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.js"></script>
<link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
  :root {
    --bg: #F7F6F2;
    --surface: #FFFFFF;
    --border: #E4E2DA;
    --text: #1A1916;
    --text-sec: #6B6860;
    --accent: #1A3A5C;
    --green: #1D7A5A;
    --red: #C0392B;
    --amber: #B8730A;
    --blue: #185FA5;
    --purple: #534AB7;
    --orange: #D85A30;
    --r: 10px;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: 'DM Sans', sans-serif; background: var(--bg); color: var(--text); font-size: 14px; }

  @media print {
    .nav, .tab-bar, .no-print { display: none !important; }
    .page { display: block !important; page-break-after: always; padding: 20px; }
    body { background: white; }
  }

  /* NAV */
  .nav {
    background: var(--accent); color: white; padding: 0 32px;
    display: flex; align-items: center; justify-content: space-between;
    height: 56px; position: sticky; top: 0; z-index: 100;
  }
  .nav-brand { font-family: 'DM Serif Display', serif; font-size: 18px; letter-spacing: .02em; }
  .nav-sub { font-size: 11px; opacity: .65; margin-top: 1px; }
  .nav-right { display: flex; align-items: center; gap: 12px; }
  .btn-pdf {
    background: white; color: var(--accent); border: none; border-radius: 6px;
    padding: 7px 16px; font-family: 'DM Sans', sans-serif; font-size: 13px;
    font-weight: 500; cursor: pointer; transition: opacity .2s;
  }
  .btn-pdf:hover { opacity: .85; }
  .period-input {
    background: rgba(255,255,255,.15); border: 1px solid rgba(255,255,255,.3);
    color: white; border-radius: 6px; padding: 5px 10px; font-family: 'DM Sans', sans-serif;
    font-size: 13px; width: 130px;
  }
  .period-input::placeholder { color: rgba(255,255,255,.5); }
  .year-input {
    background: rgba(255,255,255,.15); border: 1px solid rgba(255,255,255,.3);
    color: white; border-radius: 6px; padding: 5px 8px; font-family: 'DM Sans', sans-serif;
    font-size: 13px; width: 70px; text-align: center;
  }
  .year-label { font-size: 11px; opacity: .7; }

  /* TAB BAR */
  .tab-bar {
    background: var(--surface); border-bottom: 1px solid var(--border);
    display: flex; padding: 0 32px; gap: 4px; overflow-x: auto;
  }
  .tab {
    padding: 14px 18px; font-size: 13px; font-weight: 500; color: var(--text-sec);
    cursor: pointer; border-bottom: 2px solid transparent; white-space: nowrap; transition: all .2s;
  }
  .tab:hover { color: var(--text); }
  .tab.active { color: var(--accent); border-bottom-color: var(--accent); }

  /* PAGES */
  .page { display: none; padding: 32px; max-width: 1100px; margin: 0 auto; }
  .page.active { display: block; }

  /* PAGE HEADER */
  .page-header { margin-bottom: 28px; }
  .page-title { font-family: 'DM Serif Display', serif; font-size: 26px; color: var(--accent); }
  .page-subtitle { font-size: 12px; color: var(--text-sec); margin-top: 4px; text-transform: uppercase; letter-spacing: .06em; }

  /* QUARTER BUTTONS */
  .quarter-bar {
    display: flex; align-items: center; gap: 8px; margin-bottom: 18px; flex-wrap: wrap;
  }
  .quarter-bar-label { font-size: 11px; color: var(--text-sec); margin-right: 4px; }
  .qbtn {
    padding: 6px 16px; border-radius: 6px; font-size: 12px; font-weight: 600;
    cursor: pointer; border: 1.5px solid var(--border); background: transparent;
    color: var(--text-sec); transition: all .18s; font-family: 'DM Sans', sans-serif; letter-spacing: .02em;
  }
  .qbtn.active { background: var(--accent); color: white; border-color: var(--accent); }
  .qbtn:hover:not(.active) { border-color: var(--accent); color: var(--accent); }

  /* INPUT GRID */
  .input-grid-13 { display: grid; grid-template-columns: repeat(13, 1fr); gap: 6px; margin-bottom: 8px; }

  .input-block label { font-size: 11px; color: var(--text-sec); display: block; margin-bottom: 5px; text-align: center; }
  .input-block input[type="number"],
  .input-block input[type="text"] {
    width: 100%; text-align: center; border: 1.5px solid var(--border);
    border-radius: 7px; padding: 8px 2px; font-family: 'DM Sans', sans-serif;
    font-size: 15px; font-weight: 500; color: var(--text);
    background: var(--surface); transition: border-color .15s;
  }
  .input-block input:focus { outline: none; border-color: var(--accent); }
  .input-block input.small { font-size: 12px; }
  .week-date-input {
    width: 100%; text-align: center; border: 1px solid var(--border);
    border-radius: 5px; padding: 3px 2px; font-family: 'DM Sans', sans-serif;
    font-size: 10px; color: var(--text-sec); background: var(--bg);
    margin-top: 4px; transition: border-color .15s;
  }
  .week-date-input:focus { outline: none; border-color: var(--accent); }

  /* STAT PILLS */
  .stat-row { display: grid; gap: 10px; margin-bottom: 20px; }
  .stat-row-3 { grid-template-columns: repeat(3, 1fr); }
  .stat-row-4 { grid-template-columns: repeat(4, 1fr); }
  .stat {
    background: var(--surface); border: 1px solid var(--border); border-radius: var(--r);
    padding: 14px 16px; text-align: center;
  }
  .stat-label { font-size: 11px; color: var(--text-sec); margin-bottom: 4px; }
  .stat-value { font-size: 20px; font-weight: 600; }

  /* CHART WRAP */
  .chart-wrap { position: relative; width: 100%; height: 200px; margin-top: 4px; }

  /* DIVIDER */
  .divider { border: none; border-top: 1px solid var(--border); margin: 32px 0; }

  /* SECTION LABEL */
  .section-label {
    font-size: 11px; color: var(--text-sec); text-transform: uppercase;
    letter-spacing: .06em; margin-bottom: 16px;
  }

  /* 2-COL GRID */
  .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }

  /* CARD */
  .card {
    background: var(--surface); border: 1px solid var(--border);
    border-radius: var(--r); padding: 18px 20px;
  }
  .card-title { font-size: 12px; color: var(--text-sec); margin-bottom: 4px; }
  .card-total { font-size: 11px; color: var(--text-sec); margin-bottom: 12px; }
  .card-total span { font-weight: 600; color: var(--text); }

  /* BAR ROWS */
  .bar-row { display: flex; flex-direction: column; gap: 2px; margin-bottom: 9px; }
  .bar-row-head { display: flex; justify-content: space-between; align-items: center; }
  .bar-row-left { display: flex; align-items: center; gap: 8px; }
  .bar-label { font-size: 12px; color: var(--text-sec); width: 80px; }
  .bar-label-wide { font-size: 12px; color: var(--text-sec); width: 150px; }
  .bar-input { width: 60px; text-align: center; border: 1.5px solid var(--border); border-radius: 5px; padding: 4px; font-family: 'DM Sans', sans-serif; font-size: 13px; font-weight: 500; background: var(--surface); }
  .bar-input:focus { outline: none; border-color: var(--accent); }
  .bar-pct { font-size: 12px; font-weight: 500; min-width: 36px; text-align: right; }
  .bar-track { background: #F0EEE8; border-radius: 4px; height: 8px; margin-top: 3px; }
  .bar-fill { border-radius: 4px; height: 8px; transition: width .3s; }

  /* GEO BAR */
  .geo-bar { display: flex; width: 100%; height: 20px; border-radius: 5px; overflow: hidden; gap: 2px; margin-bottom: 10px; }
  .geo-legend { display: flex; flex-wrap: wrap; gap: 12px; }
  .geo-legend-item { display: flex; align-items: center; gap: 5px; font-size: 11px; color: var(--text-sec); }
  .legend-dot { width: 10px; height: 10px; border-radius: 2px; flex-shrink: 0; }

  /* BAJA ROW */
  .baja-row { display: flex; align-items: center; justify-content: space-between; padding: 6px 0; border-bottom: 1px solid #F0EEE8; }
  .baja-row:last-child { border-bottom: none; }
  .baja-total-row { display: flex; justify-content: space-between; align-items: center; padding-top: 10px; margin-top: 4px; border-top: 1px solid var(--border); }

  /* BAJA NAMES */
  .baja-names-wrap { margin-top: 10px; }
  .baja-names-label { font-size: 10px; color: var(--text-sec); text-transform: uppercase; letter-spacing: .05em; margin-bottom: 5px; }
  .baja-names-input {
    width: 100%; border: 1.5px solid var(--border); border-radius: 7px; padding: 7px 10px;
    font-family: 'DM Sans', sans-serif; font-size: 12px; color: var(--text);
    background: var(--surface); resize: vertical; min-height: 60px;
    transition: border-color .15s;
  }
  .baja-names-input:focus { outline: none; border-color: var(--accent); }

  /* VENDOR GRID */
  .vendor-grid { display: grid; grid-template-columns: repeat(5, 1fr); gap: 10px; }
  .vendor-card { text-align: center; }
  .vendor-card label { font-size: 11px; color: var(--text-sec); display: block; margin-bottom: 4px; }
  .vendor-name { width: 100%; text-align: center; border: 1.5px solid var(--border); border-radius: 5px; padding: 4px; font-family: 'DM Sans', sans-serif; font-size: 12px; margin-bottom: 4px; background: var(--surface); }
  .vendor-name:focus { outline: none; border-color: var(--accent); }
  .vendor-num { width: 100%; text-align: center; border: 1.5px solid var(--border); border-radius: 7px; padding: 7px 4px; font-family: 'DM Sans', sans-serif; font-size: 18px; font-weight: 600; background: var(--surface); }
  .vendor-num:focus { outline: none; border-color: var(--accent); }
  .vendor-pct { font-size: 11px; color: var(--text-sec); margin-top: 3px; }

  /* FINANCES */
  .income-input-block { background: var(--surface); border: 1px solid var(--border); border-radius: var(--r); padding: 16px 20px; margin-bottom: 12px; }
  .income-input-block label { font-size: 12px; color: var(--text-sec); display: block; margin-bottom: 6px; }
  .income-big { width: 100%; text-align: center; border: 1.5px solid var(--border); border-radius: 8px; padding: 10px; font-family: 'DM Sans', sans-serif; font-size: 24px; font-weight: 600; background: var(--surface); }
  .income-big:focus { outline: none; border-color: var(--accent); }

  .results-card { background: var(--surface); border: 1px solid var(--border); border-radius: var(--r); padding: 18px 20px; margin-bottom: 12px; }
  .results-title { font-size: 12px; color: var(--text-sec); margin-bottom: 14px; }
  .result-row { display: flex; justify-content: space-between; align-items: baseline; padding: 8px 0; border-bottom: 1px solid #F0EEE8; }
  .result-row:last-child { border-bottom: none; }
  .result-label { font-size: 13px; }
  .result-label small { display: block; font-size: 10px; color: var(--text-sec); margin-top: 1px; }
  .result-label.strong { font-weight: 600; }
  .result-value { font-size: 14px; font-weight: 600; text-align: right; }
  .result-value.big { font-size: 18px; }
  .result-sub { font-size: 10px; color: var(--text-sec); }

  .margin-card { background: #F0EEE8; border-radius: var(--r); padding: 16px 20px; }
  .margin-label { font-size: 12px; color: var(--text-sec); margin-bottom: 4px; }
  .margin-value { font-size: 30px; font-weight: 600; margin-bottom: 10px; }
  .margin-track { background: white; border-radius: 5px; height: 10px; }
  .margin-fill { border-radius: 5px; height: 10px; transition: width .3s; }
  .margin-hint { font-size: 10px; color: var(--text-sec); margin-top: 6px; }

  /* SECTION GROUP LABEL */
  .group-label { font-size: 10px; color: var(--text-sec); text-transform: uppercase; letter-spacing: .05em; margin: 12px 0 6px; padding-top: 8px; border-top: 1px solid #F0EEE8; }
  .group-label:first-of-type { border-top: none; padding-top: 0; margin-top: 0; }

  /* COLORS */
  .c-blue { color: var(--blue) !important; }
  .c-green { color: var(--green) !important; }
  .c-red { color: var(--red) !important; }
  .c-amber { color: var(--amber) !important; }

  /* LEGEND LINE */
  .chart-legend { display: flex; gap: 16px; margin-bottom: 6px; }
  .chart-legend-item { display: flex; align-items: center; gap: 6px; font-size: 11px; color: var(--text-sec); }
  .legend-line { width: 22px; height: 2px; border-radius: 1px; }
  .legend-dashed { border-top: 2px dashed #888780; display: inline-block; }

  /* IDIOMA DONUT CHART */
  .idioma-chart-wrap { position: relative; width: 100%; height: 180px; margin-top: 8px; }

  /* GEO INPUTS GRID */
  .geo-inputs-grid { display: grid; grid-template-columns: repeat(4, 1fr) repeat(5, 1fr); gap: 8px; margin-bottom: 12px; }

  /* INGRESOS 13-week dual row */
  .ing-dual-row { display: grid; grid-template-columns: repeat(13,1fr); gap: 6px; margin-bottom: 6px; }
  .ing-dual-block { display: flex; flex-direction: column; gap: 4px; }
  .ing-dual-block label { font-size: 10px; color: var(--text-sec); text-align: center; }
  .ing-dual-block input[type="number"] {
    width: 100%; text-align: center; border: 1.5px solid var(--border);
    border-radius: 6px; padding: 5px 2px; font-family: 'DM Sans', sans-serif;
    font-size: 12px; font-weight: 500; background: var(--surface); transition: border-color .15s;
  }
  .ing-dual-block input[type="number"]:focus { outline: none; border-color: var(--accent); }
  .ing-proj { border-color: #E4E2DA !important; color: var(--text-sec); }
  .ing-real { border-color: #185FA5 !important; color: var(--blue); }
</style>
</head>
<body>

<nav class="nav no-print">
  <div>
    <div class="nav-brand">Instituto Internacional de Aprendizaje</div>
    <div class="nav-sub">Dashboard de KPIs</div>
  </div>
  <div class="nav-right">
    <span class="year-label">Año:</span>
    <input class="year-input" type="number" id="dash-year" value="2026" min="2020" max="2040" oninput="recalcAllQuarters()">
    <input class="period-input" type="text" id="period" placeholder="Ej: Q1 — 2026">
    <button class="btn-pdf" onclick="window.print()">⬇ Exportar PDF</button>
  </div>
</nav>

<div class="tab-bar no-print">
  <div class="tab active" onclick="showTab(0)">📈 Estudiantes activos</div>
  <div class="tab" onclick="showTab(1)">👥 Resumen estudiantes</div>
  <div class="tab" onclick="showTab(2)">💼 Ventas</div>
  <div class="tab" onclick="showTab(3)">📊 Resumen ventas</div>
  <div class="tab" onclick="showTab(4)">💰 Ingresos</div>
  <div class="tab" onclick="showTab(5)">📋 Gastos y resultados</div>
</div>

<!-- ===== KPI 1: ESTUDIANTES ACTIVOS (trimestral) ===== -->
<div class="page active" id="page-0">
  <div class="page-header">
    <div class="page-title">Estudiantes Activos</div>
    <div class="page-subtitle">Seguimiento trimestral — 13 semanas</div>
  </div>

  <div class="quarter-bar">
    <span class="quarter-bar-label">Trimestre:</span>
    <button class="qbtn active" onclick="setQuarter('e',1,this)">T1</button>
    <button class="qbtn" onclick="setQuarter('e',2,this)">T2</button>
    <button class="qbtn" onclick="setQuarter('e',3,this)">T3</button>
    <button class="qbtn" onclick="setQuarter('e',4,this)">T4</button>
  </div>

  <div class="input-grid-13" id="e-week-inputs"></div>
  <div class="input-grid-13" id="e-date-inputs"></div>

  <div class="stat-row stat-row-3" style="margin-top:16px;">
    <div class="stat"><div class="stat-label">Promedio trimestral</div><div class="stat-value" id="eq-avg">—</div></div>
    <div class="stat"><div class="stat-label">Pico del trimestre</div><div class="stat-value" id="eq-peak">—</div></div>
    <div class="stat"><div class="stat-label">Tendencia</div><div class="stat-value" id="eq-trend">—</div></div>
  </div>
  <div class="chart-wrap"><canvas id="chartEQ"></canvas></div>
</div>

<!-- ===== KPI 2: RESUMEN ESTUDIANTES ===== -->
<div class="page" id="page-1">
  <div class="page-header">
    <div class="page-title">Resumen de Estudiantes</div>
    <div class="page-subtitle">Bajas, distribución por idioma y geografía</div>
  </div>
  <div class="grid-2" style="margin-bottom:16px;">

    <!-- BAJAS -->
    <div class="card">
      <div class="card-title">Bajas del trimestre</div>
      <div style="margin-top:8px;">
        <div class="baja-row"><span style="font-size:13px;color:var(--text-sec);">Inglés</span><input type="number" id="b1" value="4" min="0" class="bar-input" oninput="updateResumen()"></div>
        <div class="baja-row"><span style="font-size:13px;color:var(--text-sec);">Portugués</span><input type="number" id="b2" value="2" min="0" class="bar-input" oninput="updateResumen()"></div>
        <div class="baja-row"><span style="font-size:13px;color:var(--text-sec);">Japonés</span><input type="number" id="b3" value="1" min="0" class="bar-input" oninput="updateResumen()"></div>
        <div class="baja-row"><span style="font-size:13px;color:var(--text-sec);">Coreano</span><input type="number" id="b4" value="1" min="0" class="bar-input" oninput="updateResumen()"></div>
        <div class="baja-row"><span style="font-size:13px;color:var(--text-sec);">Francés</span><input type="number" id="b5" value="0" min="0" class="bar-input" oninput="updateResumen()"></div>
        <div class="baja-row"><span style="font-size:13px;color:var(--text-sec);">LENSEGUA</span><input type="number" id="b6" value="0" min="0" class="bar-input" oninput="updateResumen()"></div>
        <div class="baja-row"><span style="font-size:13px;color:var(--text-sec);">Español</span><input type="number" id="b7" value="0" min="0" class="bar-input" oninput="updateResumen()"></div>
        <div class="baja-row"><span style="font-size:13px;color:var(--text-sec);">Soft Skills</span><input type="number" id="b8" value="0" min="0" class="bar-input" oninput="updateResumen()"></div>
        <div class="baja-total-row"><span style="font-size:13px;font-weight:600;">Total bajas</span><span id="b-total" style="font-size:20px;font-weight:600;color:var(--red);">8</span></div>
      </div>
      <div class="baja-names-wrap">
        <div class="baja-names-label">Nombres de estudiantes que dieron de baja</div>
        <textarea class="baja-names-input" id="baja-names" placeholder="Ej: Juan Pérez (Inglés), Ana López (Portugués)..."></textarea>
      </div>
    </div>

    <!-- ACTIVOS POR IDIOMA -->
    <div class="card">
      <div class="card-title">Activos por idioma</div>
      <div class="card-total">Total: <span id="i-total">0</span> estudiantes</div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Inglés</span><input type="number" id="i1" value="94" min="0" class="bar-input" oninput="updateResumen()"></div><span class="bar-pct" id="ip1"></span></div><div class="bar-track"><div class="bar-fill" id="ib1" style="background:#185FA5;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Portugués</span><input type="number" id="i2" value="52" min="0" class="bar-input" oninput="updateResumen()"></div><span class="bar-pct" id="ip2"></span></div><div class="bar-track"><div class="bar-fill" id="ib2" style="background:#1D9E75;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Japonés</span><input type="number" id="i3" value="28" min="0" class="bar-input" oninput="updateResumen()"></div><span class="bar-pct" id="ip3"></span></div><div class="bar-track"><div class="bar-fill" id="ib3" style="background:#993C1D;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Coreano</span><input type="number" id="i4" value="18" min="0" class="bar-input" oninput="updateResumen()"></div><span class="bar-pct" id="ip4"></span></div><div class="bar-track"><div class="bar-fill" id="ib4" style="background:#534AB7;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Francés</span><input type="number" id="i5" value="4" min="0" class="bar-input" oninput="updateResumen()"></div><span class="bar-pct" id="ip5"></span></div><div class="bar-track"><div class="bar-fill" id="ib5" style="background:#D85A30;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">LENSEGUA</span><input type="number" id="i6" value="2" min="0" class="bar-input" oninput="updateResumen()"></div><span class="bar-pct" id="ip6"></span></div><div class="bar-track"><div class="bar-fill" id="ib6" style="background:#888780;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Español</span><input type="number" id="i7" value="8" min="0" class="bar-input" oninput="updateResumen()"></div><span class="bar-pct" id="ip7"></span></div><div class="bar-track"><div class="bar-fill" id="ib7" style="background:#BA7517;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Soft Skills</span><input type="number" id="i8" value="5" min="0" class="bar-input" oninput="updateResumen()"></div><span class="bar-pct" id="ip8"></span></div><div class="bar-track"><div class="bar-fill" id="ib8" style="background:#AFA9EC;"></div></div></div>

      <div style="margin-top:14px;">
        <div class="idioma-chart-wrap"><canvas id="chartIdioma"></canvas></div>
      </div>
    </div>
  </div>

  <!-- DISTRIBUCIÓN GEOGRÁFICA -->
  <div class="card">
    <div class="card-title">Distribución geográfica</div>
    <div class="card-total">Total: <span id="g-total">0</span> estudiantes</div>
    <div style="display:grid;grid-template-columns:repeat(4,1fr) 1fr;gap:10px;margin-bottom:12px;" id="geo-inputs-wrap">
      <!-- 8 editables + Otros generados por JS -->
    </div>
    <div class="geo-bar" id="geo-bar"></div>
    <div class="geo-legend" id="geo-legend"></div>
  </div>
</div>

<!-- ===== KPI 3: VENTAS (trimestral) ===== -->
<div class="page" id="page-2">
  <div class="page-header">
    <div class="page-title">Ventas</div>
    <div class="page-subtitle">Seguimiento trimestral — 13 semanas</div>
  </div>

  <div class="quarter-bar">
    <span class="quarter-bar-label">Trimestre:</span>
    <button class="qbtn active" onclick="setQuarter('v',1,this)">T1</button>
    <button class="qbtn" onclick="setQuarter('v',2,this)">T2</button>
    <button class="qbtn" onclick="setQuarter('v',3,this)">T3</button>
    <button class="qbtn" onclick="setQuarter('v',4,this)">T4</button>
  </div>

  <div style="margin-bottom:4px;">
    <div style="font-size:10px;color:var(--text-sec);margin-bottom:6px;">
      <span style="display:inline-flex;align-items:center;gap:5px;margin-right:16px;"><span style="width:18px;border-top:2px dashed #D85A30;display:inline-block;"></span> Reuniones con clientes</span>
      <span style="display:inline-flex;align-items:center;gap:5px;"><span style="width:18px;height:2px;background:#378ADD;display:inline-block;border-radius:1px;"></span> Ventas cerradas</span>
    </div>
  </div>

  <div class="input-grid-13" id="v-reunion-inputs"></div>
  <div class="input-grid-13" id="v-week-inputs"></div>
  <div class="input-grid-13" id="v-date-inputs"></div>

  <div class="stat-row stat-row-3" style="margin-top:16px;">
    <div class="stat"><div class="stat-label">Total del trimestre</div><div class="stat-value" id="vq-total">—</div></div>
    <div class="stat"><div class="stat-label">Mejor semana</div><div class="stat-value" id="vq-peak">—</div></div>
    <div class="stat"><div class="stat-label">Tendencia</div><div class="stat-value" id="vq-trend">—</div></div>
  </div>
  <div class="chart-wrap"><canvas id="chartVQ"></canvas></div>
</div>

<!-- ===== KPI 4: RESUMEN VENTAS ===== -->
<div class="page" id="page-3">
  <div class="page-header">
    <div class="page-title">Resumen de Ventas</div>
    <div class="page-subtitle">Por idioma, tipo de curso, canal y vendedor</div>
  </div>
  <div class="grid-2" style="margin-bottom:16px;">
    <div class="card">
      <div class="card-title">Ventas por idioma</div>
      <div class="card-total">Total: <span id="vl-total">0</span> ventas</div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Inglés</span><input type="number" id="vl1" value="42" min="0" class="bar-input" oninput="updateVR()"></div><span class="bar-pct" id="vlp1"></span></div><div class="bar-track"><div class="bar-fill" id="vlb1" style="background:#185FA5;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Portugués</span><input type="number" id="vl2" value="25" min="0" class="bar-input" oninput="updateVR()"></div><span class="bar-pct" id="vlp2"></span></div><div class="bar-track"><div class="bar-fill" id="vlb2" style="background:#1D9E75;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Japonés</span><input type="number" id="vl3" value="14" min="0" class="bar-input" oninput="updateVR()"></div><span class="bar-pct" id="vlp3"></span></div><div class="bar-track"><div class="bar-fill" id="vlb3" style="background:#993C1D;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Coreano</span><input type="number" id="vl4" value="8" min="0" class="bar-input" oninput="updateVR()"></div><span class="bar-pct" id="vlp4"></span></div><div class="bar-track"><div class="bar-fill" id="vlb4" style="background:#534AB7;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Francés</span><input type="number" id="vl5" value="2" min="0" class="bar-input" oninput="updateVR()"></div><span class="bar-pct" id="vlp5"></span></div><div class="bar-track"><div class="bar-fill" id="vlb5" style="background:#D85A30;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">LENSEGUA</span><input type="number" id="vl6" value="1" min="0" class="bar-input" oninput="updateVR()"></div><span class="bar-pct" id="vlp6"></span></div><div class="bar-track"><div class="bar-fill" id="vlb6" style="background:#888780;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Español</span><input type="number" id="vl7" value="4" min="0" class="bar-input" oninput="updateVR()"></div><span class="bar-pct" id="vlp7"></span></div><div class="bar-track"><div class="bar-fill" id="vlb7" style="background:#BA7517;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Soft Skills</span><input type="number" id="vl8" value="2" min="0" class="bar-input" oninput="updateVR()"></div><span class="bar-pct" id="vlp8"></span></div><div class="bar-track"><div class="bar-fill" id="vlb8" style="background:#AFA9EC;"></div></div></div>
    </div>
    <div style="display:flex;flex-direction:column;gap:12px;">
      <div class="card">
        <div class="card-title">Tipo de curso</div>
        <div style="margin-top:8px;">
          <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Grupal</span><input type="number" id="vt1" value="55" min="0" class="bar-input" oninput="updateVR()"></div><span class="bar-pct" id="vtp1"></span></div><div class="bar-track"><div class="bar-fill" id="vtb1" style="background:#185FA5;"></div></div></div>
          <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Privado</span><input type="number" id="vt2" value="28" min="0" class="bar-input" oninput="updateVR()"></div><span class="bar-pct" id="vtp2"></span></div><div class="bar-track"><div class="bar-fill" id="vtb2" style="background:#7F77DD;"></div></div></div>
          <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">B2B</span><input type="number" id="vt3" value="9" min="0" class="bar-input" oninput="updateVR()"></div><span class="bar-pct" id="vtp3"></span></div><div class="bar-track"><div class="bar-fill" id="vtb3" style="background:#1D9E75;"></div></div></div>
        </div>
      </div>
      <div class="card">
        <div class="card-title">Canal de venta</div>
        <div style="margin-top:8px;">
          <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Redes soc.</span><input type="number" id="vc1" value="38" min="0" class="bar-input" oninput="updateVR()"></div><span class="bar-pct" id="vcp1"></span></div><div class="bar-track"><div class="bar-fill" id="vcb1" style="background:#D85A30;"></div></div></div>
          <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Referidos</span><input type="number" id="vc2" value="30" min="0" class="bar-input" oninput="updateVR()"></div><span class="bar-pct" id="vcp2"></span></div><div class="bar-track"><div class="bar-fill" id="vcb2" style="background:#BA7517;"></div></div></div>
          <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Directo</span><input type="number" id="vc3" value="16" min="0" class="bar-input" oninput="updateVR()"></div><span class="bar-pct" id="vcp3"></span></div><div class="bar-track"><div class="bar-fill" id="vcb3" style="background:#888780;"></div></div></div>
          <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label">Web/online</span><input type="number" id="vc4" value="8" min="0" class="bar-input" oninput="updateVR()"></div><span class="bar-pct" id="vcp4"></span></div><div class="bar-track"><div class="bar-fill" id="vcb4" style="background:#534AB7;"></div></div></div>
        </div>
      </div>
    </div>
  </div>
  <div class="card">
    <div class="card-title">Ventas por vendedor</div>
    <div class="card-total">Total: <span id="vv-total">0</span> ventas</div>
    <div class="vendor-grid">
      <div class="vendor-card"><label>Nombre</label><input type="text" id="vn1" value="María" class="vendor-name" oninput="updateVR()"><input type="number" id="vv1" value="35" min="0" class="vendor-num" oninput="updateVR()"><div class="vendor-pct" id="vvp1"></div></div>
      <div class="vendor-card"><label>Nombre</label><input type="text" id="vn2" value="Carlos" class="vendor-name" oninput="updateVR()"><input type="number" id="vv2" value="28" min="0" class="vendor-num" oninput="updateVR()"><div class="vendor-pct" id="vvp2"></div></div>
      <div class="vendor-card"><label>Nombre</label><input type="text" id="vn3" value="Luis" class="vendor-name" oninput="updateVR()"><input type="number" id="vv3" value="20" min="0" class="vendor-num" oninput="updateVR()"><div class="vendor-pct" id="vvp3"></div></div>
      <div class="vendor-card"><label>Nombre</label><input type="text" id="vn4" value="Andrea" class="vendor-name" oninput="updateVR()"><input type="number" id="vv4" value="9" min="0" class="vendor-num" oninput="updateVR()"><div class="vendor-pct" id="vvp4"></div></div>
      <div class="vendor-card"><label>Nombre</label><input type="text" id="vn5" value="" class="vendor-name" placeholder="—" oninput="updateVR()"><input type="number" id="vv5" value="0" min="0" class="vendor-num" oninput="updateVR()"><div class="vendor-pct" id="vvp5"></div></div>
    </div>
    <div class="baja-names-wrap" style="margin-top:16px;">
      <div class="baja-names-label">Nombres de estudiantes que compraron este trimestre</div>
      <textarea class="baja-names-input" id="ventas-names" placeholder="Ej: Juan Pérez (Inglés — Grupal), Ana López (Portugués — Privado)..."></textarea>
    </div>
  </div>
</div>

<!-- ===== KPI 5: INGRESOS (mensual) ===== -->
<div class="page" id="page-4">
  <div class="page-header">
    <div class="page-title">Ingresos</div>
    <div class="page-subtitle">Real vs proyección mensual — semanas del mes</div>
  </div>

  <div class="quarter-bar" id="f-month-bar">
    <span class="quarter-bar-label">Mes:</span>
    <button class="qbtn active" onclick="setMonth(1,this)">Ene</button>
    <button class="qbtn" onclick="setMonth(2,this)">Feb</button>
    <button class="qbtn" onclick="setMonth(3,this)">Mar</button>
    <button class="qbtn" onclick="setMonth(4,this)">Abr</button>
    <button class="qbtn" onclick="setMonth(5,this)">May</button>
    <button class="qbtn" onclick="setMonth(6,this)">Jun</button>
    <button class="qbtn" onclick="setMonth(7,this)">Jul</button>
    <button class="qbtn" onclick="setMonth(8,this)">Ago</button>
    <button class="qbtn" onclick="setMonth(9,this)">Sep</button>
    <button class="qbtn" onclick="setMonth(10,this)">Oct</button>
    <button class="qbtn" onclick="setMonth(11,this)">Nov</button>
    <button class="qbtn" onclick="setMonth(12,this)">Dic</button>
  </div>

  <div style="margin-bottom:4px;">
    <div style="font-size:10px;color:var(--text-sec);margin-bottom:6px;">
      <span style="display:inline-flex;align-items:center;gap:5px;margin-right:16px;"><span style="width:18px;border-top:2px dashed #888780;display:inline-block;"></span> Proyección</span>
      <span style="display:inline-flex;align-items:center;gap:5px;"><span style="width:18px;height:2px;background:#185FA5;display:inline-block;border-radius:1px;"></span> Real</span>
    </div>
  </div>

  <!-- week inputs generated by JS depending on month -->
  <div id="f-week-inputs-wrap"></div>
  <div id="f-date-inputs-wrap" style="display:grid;gap:6px;margin-bottom:0;"></div>

  <div class="stat-row stat-row-4" style="margin-top:16px;">
    <div class="stat"><div class="stat-label">Total proyectado</div><div class="stat-value" id="fq-proj">—</div></div>
    <div class="stat"><div class="stat-label">Total real</div><div class="stat-value" id="fq-real">—</div></div>
    <div class="stat"><div class="stat-label">Diferencia</div><div class="stat-value" id="fq-diff">—</div></div>
    <div class="stat"><div class="stat-label">Cumplimiento</div><div class="stat-value" id="fq-pct">—</div></div>
  </div>
  <div class="chart-wrap"><canvas id="chartFQ"></canvas></div>
</div>

<!-- ===== KPI 6: GASTOS Y RESULTADOS ===== -->
<div class="page" id="page-5">
  <div class="page-header">
    <div class="page-title">Gastos y Estado de Resultados</div>
    <div class="page-subtitle">Desglose mensual de gastos y cascada financiera</div>
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title">Desglose de gastos</div>
      <div class="card-total">Total: <span id="gt-total">—</span></div>

      <div class="group-label">Costo de enseñanza</div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label-wide">Profesores</span><input type="number" id="gg1" value="12000" min="0" class="bar-input" oninput="updateGastos()"></div><span class="bar-pct" id="ggp1"></span></div><div class="bar-track"><div class="bar-fill" id="ggb1" style="background:#185FA5;"></div></div></div>

      <div class="group-label">Gastos operativos</div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label-wide">Marketing</span><input type="number" id="gg2" value="3500" min="0" class="bar-input" oninput="updateGastos()"></div><span class="bar-pct" id="ggp2"></span></div><div class="bar-track"><div class="bar-fill" id="ggb2" style="background:#D85A30;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label-wide">Salarios admin.</span><input type="number" id="gg3" value="4000" min="0" class="bar-input" oninput="updateGastos()"></div><span class="bar-pct" id="ggp3"></span></div><div class="bar-track"><div class="bar-fill" id="ggb3" style="background:#7F77DD;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label-wide">Plataformas dig.</span><input type="number" id="gg4" value="1200" min="0" class="bar-input" oninput="updateGastos()"></div><span class="bar-pct" id="ggp4"></span></div><div class="bar-track"><div class="bar-fill" id="ggb4" style="background:#1D9E75;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label-wide">Rentas</span><input type="number" id="gg5" value="2000" min="0" class="bar-input" oninput="updateGastos()"></div><span class="bar-pct" id="ggp5"></span></div><div class="bar-track"><div class="bar-fill" id="ggb5" style="background:#BA7517;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label-wide">Vehículos</span><input type="number" id="gg6" value="800" min="0" class="bar-input" oninput="updateGastos()"></div><span class="bar-pct" id="ggp6"></span></div><div class="bar-track"><div class="bar-fill" id="ggb6" style="background:#534AB7;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label-wide">Pautas</span><input type="number" id="gg7" value="1500" min="0" class="bar-input" oninput="updateGastos()"></div><span class="bar-pct" id="ggp7"></span></div><div class="bar-track"><div class="bar-fill" id="ggb7" style="background:#993C1D;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label-wide">Impuestos</span><input type="number" id="gg8" value="600" min="0" class="bar-input" oninput="updateGastos()"></div><span class="bar-pct" id="ggp8"></span></div><div class="bar-track"><div class="bar-fill" id="ggb8" style="background:#E24B4A;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label-wide">Muebles</span><input type="number" id="gg9" value="400" min="0" class="bar-input" oninput="updateGastos()"></div><span class="bar-pct" id="ggp9"></span></div><div class="bar-track"><div class="bar-fill" id="ggb9" style="background:#888780;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label-wide">Otros</span><input type="number" id="gg10" value="300" min="0" class="bar-input" oninput="updateGastos()"></div><span class="bar-pct" id="ggp10"></span></div><div class="bar-track"><div class="bar-fill" id="ggb10" style="background:#5DCAA5;"></div></div></div>

      <div class="group-label">Compromisos financieros</div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label-wide">Préstamo</span><input type="number" id="gg11" value="2000" min="0" class="bar-input" oninput="updateGastos()"></div><span class="bar-pct" id="ggp11"></span></div><div class="bar-track"><div class="bar-fill" id="ggb11" style="background:#AFA9EC;"></div></div></div>
      <div class="bar-row"><div class="bar-row-head"><div class="bar-row-left"><span class="bar-label-wide">Retorno inversionist.</span><input type="number" id="gg12" value="1500" min="0" class="bar-input" oninput="updateGastos()"></div><span class="bar-pct" id="ggp12"></span></div><div class="bar-track"><div class="bar-fill" id="ggb12" style="background:#9FE1CB;"></div></div></div>
    </div>

    <div style="display:flex;flex-direction:column;gap:12px;">
      <div class="income-input-block">
        <label>Ingresos reales del trimestre (Q)</label>
        <input type="number" id="ing" value="33300" min="0" class="income-big" oninput="updateGastos()">
      </div>
      <div class="results-card">
        <div class="results-title">Estado de resultados</div>
        <div class="result-row">
          <div class="result-label">Ingresos</div>
          <div class="result-value" id="r-ing">—</div>
        </div>
        <div class="result-row">
          <div class="result-label"><strong>Margen bruto</strong><small>Ingresos − Profesores</small></div>
          <div style="text-align:right;"><div class="result-value" id="r-mb">—</div><div class="result-sub" id="r-mb-pct"></div></div>
        </div>
        <div class="result-row">
          <div class="result-label"><strong>Margen operativo (EBIT)</strong><small>Margen bruto − gastos operativos</small></div>
          <div style="text-align:right;"><div class="result-value" id="r-ebit">—</div><div class="result-sub" id="r-ebit-pct"></div></div>
        </div>
        <div class="result-row" style="border-bottom:none;padding-top:10px;">
          <div class="result-label" style="font-size:15px;font-weight:700;">Utilidad neta<small style="font-weight:400;">EBIT − Préstamo − Retorno inv.</small></div>
          <div style="text-align:right;"><div class="result-value big" id="r-util">—</div><div class="result-sub" id="r-util-pct"></div></div>
        </div>
      </div>
      <div class="margin-card">
        <div class="margin-label">Margen neto</div>
        <div class="margin-value" id="margin-val">—</div>
        <div class="margin-track"><div class="margin-fill" id="margin-bar" style="width:0%;"></div></div>
        <div class="margin-hint">Verde ≥30% · Ámbar ≥15% · Rojo &lt;15%</div>
      </div>
    </div>
  </div>
</div>

<script>
// ===================== HELPERS =====================
const $ = id => document.getElementById(id);
function fmtQ(n){ return 'Q' + Math.abs(Math.round(n)).toLocaleString('es-GT'); }
function fmtK(n){ return n >= 1000 ? 'Q' + Math.round(n/1000) + 'K' : fmtQ(n); }
function pct(v, t){ return t ? Math.round((v/t)*100) + '%' : '0%'; }
function col(v){ return v >= 0 ? '#1D7A5A' : '#C0392B'; }
function trend(first, last){ return first > 0 ? Math.round(((last-first)/first)*100) : 0; }
function trendStr(p){ return (p >= 0 ? '+' : '') + p + '%'; }
function setColor(el, v){ if(el) el.style.color = col(v); }

// ===================== CHARTS =====================
const chartDefs = {};
function makeChart(id, labels, datasets, yCallback){
  const ctx = $(id);
  if(!ctx) return null;
  if(chartDefs[id]) chartDefs[id].destroy();
  chartDefs[id] = new Chart(ctx, {
    type: 'line',
    data: { labels, datasets },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        y: { beginAtZero: false, ticks: { font: { size: 10, family: 'DM Sans' }, callback: yCallback || (v => v) } },
        x: { ticks: { font: { size: 9, family: 'DM Sans' }, autoSkip: false, maxRotation: 45 } }
      }
    }
  });
  return chartDefs[id];
}
function makeDoughnutChart(id, labels, data, colors){
  const ctx = $(id);
  if(!ctx) return null;
  if(chartDefs[id]) chartDefs[id].destroy();
  chartDefs[id] = new Chart(ctx, {
    type: 'doughnut',
    data: { labels, datasets: [{ data, backgroundColor: colors, borderWidth: 2, borderColor: '#fff' }] },
    options: {
      responsive: true, maintainAspectRatio: false, cutout: '60%',
      plugins: {
        legend: { position: 'right', labels: { font: { size: 10, family: 'DM Sans' }, boxWidth: 12, padding: 8 } }
      }
    }
  });
}
function lineDS(data, color, dashed){
  return {
    data, borderColor: color,
    backgroundColor: color + '14',
    borderWidth: dashed ? 2 : 2.5,
    borderDash: dashed ? [6,4] : [],
    pointRadius: 4, pointBackgroundColor: color,
    fill: !dashed, tension: 0.3, spanGaps: false
  };
}

// ===================== TABS =====================
function showTab(idx){
  document.querySelectorAll('.page').forEach((p,i) => p.classList.toggle('active', i===idx));
  document.querySelectorAll('.tab').forEach((t,i) => t.classList.toggle('active', i===idx));
  setTimeout(() => {
    if(idx===0) updateEQ();
    if(idx===2) updateVQ();
    if(idx===4) updateFQ();
    if(idx===1) updateResumen();
  }, 50);
}

// ===================== QUARTER DATE CALCULATOR =====================
// Quarter week starts: Q1=Jan1, Q2=Apr1, Q3=Jul1, Q4=Oct1 (approx, using Mon-Sun weeks)
const MONTHS_ES = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];

function getQuarterDates(year, q) {
  // Start date for each quarter (Monday of the week containing the 1st of month)
  const qStarts = [
    new Date(year, 0, 1),  // Q1: Jan 1
    new Date(year, 3, 1),  // Q2: Apr 1
    new Date(year, 6, 1),  // Q3: Jul 1
    new Date(year, 9, 1),  // Q4: Oct 1
  ];
  let start = new Date(qStarts[q-1]);
  // Move to Monday of that week
  const day = start.getDay(); // 0=Sun
  const diff = day === 0 ? -6 : 1 - day;
  start.setDate(start.getDate() + diff);

  const weeks = [];
  for(let i = 0; i < 13; i++){
    const s = new Date(start);
    s.setDate(s.getDate() + i*7);
    const e = new Date(s);
    e.setDate(e.getDate() + 6);
    const fmt = d => MONTHS_ES[d.getMonth()] + ' ' + d.getDate();
    weeks.push(fmt(s) + '-' + e.getDate());
  }
  return weeks;
}

// Per-prefix state
const qState = { e: 1, v: 1, f: 1 };

function setQuarter(prefix, q, btn) {
  btn.closest('.quarter-bar').querySelectorAll('.qbtn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  qState[prefix] = q;
  const year = parseInt($('dash-year').value) || 2026;
  const dates = getQuarterDates(year, q);

  // Reset all 13 week numeric inputs to 0
  for(let i = 1; i <= 13; i++){
    const wEl = $(`${prefix}-w${i}`);
    if(wEl) wEl.value = 0;
    // Also reset reunion inputs for ventas
    if(prefix === 'v'){
      const rEl = $(`v-r${i}`);
      if(rEl) rEl.value = 0;
    }
    // Clear user-edited flag on date inputs so they get refilled
    const dEl = $(`${prefix}-date-${i}`);
    if(dEl) { dEl.value = ''; delete dEl.dataset.userEdited; }
  }

  fillDates(prefix, dates);
  if(prefix==='e') updateEQ();
  if(prefix==='v') updateVQ();
  if(prefix==='f') updateFQ();
}

function fillDates(prefix, dates) {
  for(let i=0;i<13;i++){
    const el = $(`${prefix}-date-${i+1}`);
    if(el && !el.dataset.userEdited) el.value = dates[i];
  }
}

function recalcAllQuarters(){
  const year = parseInt($('dash-year').value) || 2026;
  ['e','v'].forEach(prefix => {
    const q = qState[prefix];
    const dates = getQuarterDates(year, q);
    fillDates(prefix, dates);
  });
  // Rebuild ingresos for current month with new year
  buildFWeekInputs(fCurrentMonth);
  updateEQ(); updateVQ(); updateFQ();
}

// ===================== BUILD 13-WEEK INPUTS =====================
function buildWeekInputs(prefix, updateFn) {
  const wrapId = `${prefix}-week-inputs`;
  const dateWrapId = `${prefix}-date-inputs`;
  const wrap = $(wrapId);
  const dateWrap = $(dateWrapId);
  if(!wrap || !dateWrap) return;
  wrap.innerHTML = '';
  dateWrap.innerHTML = '';

  // Build reuniones row for ventas
  if(prefix === 'v') {
    const reunWrap = $('v-reunion-inputs');
    if(reunWrap) {
      reunWrap.innerHTML = '';
      for(let i=1;i<=13;i++){
        const div = document.createElement('div');
        div.className = 'input-block';
        div.innerHTML = `<label style="color:#D85A30;">Reun. ${i}</label><input type="number" id="v-r${i}" value="0" min="0" style="border-color:#D85A3040;" oninput="updateVQ()">`;
        reunWrap.appendChild(div);
      }
    }
  }

  for(let i=1;i<=13;i++){
    const div = document.createElement('div');
    div.className = 'input-block';
    div.innerHTML = `<label>Sem ${i}</label><input type="number" id="${prefix}-w${i}" value="0" min="0" oninput="${updateFn}()">`;
    wrap.appendChild(div);

    const dDiv = document.createElement('div');
    dDiv.innerHTML = `<input type="text" class="week-date-input" id="${prefix}-date-${i}" placeholder="Sem ${i}" oninput="this.dataset.userEdited='1'">`;
    dateWrap.appendChild(dDiv);
  }
}

// Monthly week count: how many Mon–Sun weeks overlap each month
function getWeeksInMonth(year, month) {
  // Get all Mondays whose week (Mon-Sun) overlaps the month
  // A week overlaps the month if Monday <= last day of month AND Sunday >= first day of month
  const firstDay = new Date(year, month - 1, 1);
  const lastDay = new Date(year, month, 0);
  const weeks = [];
  // Find first Monday on or before firstDay
  let mon = new Date(firstDay);
  const dow = mon.getDay(); // 0=Sun
  const back = dow === 0 ? 6 : dow - 1;
  mon.setDate(mon.getDate() - back);
  // Walk Mondays while they start before or within month
  while (mon <= lastDay) {
    const sun = new Date(mon); sun.setDate(sun.getDate() + 6);
    // Week overlaps month if mon <= lastDay && sun >= firstDay
    if (sun >= firstDay) {
      const fmt = d => MONTHS_ES[d.getMonth()] + ' ' + d.getDate();
      weeks.push({ label: fmt(mon) + '-' + sun.getDate(), mon: new Date(mon), sun: new Date(sun) });
    }
    mon.setDate(mon.getDate() + 7);
  }
  return weeks;
}

let fCurrentMonth = 1;
// Store proj/real values per month: fMonthData[month] = { proj: [], real: [], dates: [] }
const fMonthData = {};

function ensureMonthData(month, weekCount) {
  if (!fMonthData[month]) {
    fMonthData[month] = {
      proj: Array(weekCount).fill(8000),
      real: Array(weekCount).fill(0),
      dates: Array(weekCount).fill('')
    };
  } else {
    // Resize if week count changed
    while (fMonthData[month].proj.length < weekCount) { fMonthData[month].proj.push(8000); fMonthData[month].real.push(0); fMonthData[month].dates.push(''); }
    fMonthData[month].proj.length = weekCount;
    fMonthData[month].real.length = weekCount;
    fMonthData[month].dates.length = weekCount;
  }
}

function buildFWeekInputs(month) {
  const year = parseInt($('dash-year').value) || 2026;
  const weeks = getWeeksInMonth(year, month);
  const n = weeks.length;
  ensureMonthData(month, n);
  const data = fMonthData[month];

  const wrap = $('f-week-inputs-wrap');
  const dateWrap = $('f-date-inputs-wrap');
  if (!wrap || !dateWrap) return;

  const cols = `repeat(${n},1fr)`;

  let projHTML = `<div style="display:grid;grid-template-columns:${cols};gap:6px;margin-bottom:4px;">`;
  let realHTML = `<div style="display:grid;grid-template-columns:${cols};gap:6px;margin-bottom:4px;">`;
  for (let i = 0; i < n; i++) {
    projHTML += `<div class="input-block"><label style="color:#888;">Proy. ${i+1}</label><input type="number" id="fp${i+1}" value="${data.proj[i]}" min="0" class="ing-proj" oninput="saveFData(${month});updateFQ()"></div>`;
    realHTML += `<div class="input-block"><label style="color:var(--blue);">Real ${i+1}</label><input type="number" id="fr${i+1}" value="${data.real[i]}" min="0" class="ing-real" oninput="saveFData(${month});updateFQ()"></div>`;
  }
  projHTML += '</div>'; realHTML += '</div>';
  wrap.innerHTML = projHTML + realHTML;

  dateWrap.style.gridTemplateColumns = cols;
  dateWrap.innerHTML = '';
  for (let i = 0; i < n; i++) {
    const dDiv = document.createElement('div');
    dDiv.innerHTML = `<input type="text" class="week-date-input" id="f-date-${i+1}" value="${data.dates[i] || weeks[i].label}" placeholder="Sem ${i+1}" oninput="saveFData(${month});updateFQ()">`;
    dateWrap.appendChild(dDiv);
  }
}

function saveFData(month) {
  const year = parseInt($('dash-year').value) || 2026;
  const weeks = getWeeksInMonth(year, month);
  const n = weeks.length;
  ensureMonthData(month, n);
  for (let i = 0; i < n; i++) {
    const pEl = $('fp'+(i+1)), rEl = $('fr'+(i+1)), dEl = $(`f-date-${i+1}`);
    if (pEl) fMonthData[month].proj[i] = parseInt(pEl.value) || 0;
    if (rEl) fMonthData[month].real[i] = parseInt(rEl.value) || 0;
    if (dEl) fMonthData[month].dates[i] = dEl.value;
  }
}

function setMonth(month, btn) {
  // Save current before switching
  saveFData(fCurrentMonth);
  // Switch button active state
  $('f-month-bar').querySelectorAll('.qbtn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  fCurrentMonth = month;
  // If this month has never been visited, delete any stale data so it starts fresh
  if(!fMonthData[month]) {
    // ensureMonthData will create it clean with proj=8000, real=0
  }
  buildFWeekInputs(month);
  updateFQ();
}

// ===================== BUILD GEO INPUTS =====================
const GEO_COLORS = ['#185FA5','#1D9E75','#7F77DD','#D85A30','#BA7517','#993C1D','#534AB7','#5DCAA5','#888780'];
const GEO_DEFAULTS = ['🇬🇹 Guatemala','🇲🇽 México','🇺🇸 EE.UU.','🇧🇷 Brasil','🇨🇴 Colombia','🇦🇷 Argentina','🇨🇦 Canadá','🇪🇸 España'];

function buildGeoInputs(){
  const wrap = $('geo-inputs-wrap');
  if(!wrap) return;
  wrap.style.display = 'grid';
  wrap.style.gridTemplateColumns = 'repeat(3,1fr) repeat(3,1fr) repeat(3,1fr)';
  wrap.style.gap = '8px';
  wrap.innerHTML = '';
  for(let i=1;i<=8;i++){
    const div = document.createElement('div');
    div.className = 'input-block';
    div.innerHTML = `
      <input type="text" id="gn${i}" value="${GEO_DEFAULTS[i-1]}" style="font-size:11px;text-align:center;border:1.5px solid var(--border);border-radius:6px;padding:4px;width:100%;background:var(--surface);font-family:'DM Sans',sans-serif;margin-bottom:4px;" oninput="updateResumen()">
      <input type="number" id="g${i}" value="${i===1?155:i===2?20:i===3?14:0}" min="0" oninput="updateResumen()">
      <div style="font-size:10px;color:var(--text-sec);text-align:center;margin-top:3px;" id="gp${i}"></div>
    `;
    wrap.appendChild(div);
  }
  // Otros
  const otros = document.createElement('div');
  otros.className = 'input-block';
  otros.innerHTML = `
    <div style="font-size:11px;text-align:center;color:var(--text-sec);border:1.5px solid var(--border);border-radius:6px;padding:4px;margin-bottom:4px;background:#F7F6F2;">Otros</div>
    <input type="number" id="g9" value="9" min="0" oninput="updateResumen()">
    <div style="font-size:10px;color:var(--text-sec);text-align:center;margin-top:3px;" id="gp9"></div>
  `;
  wrap.appendChild(otros);
}

// ===================== KPI 1 — ESTUDIANTES TRIMESTRAL =====================
function updateEQ(){
  const d = Array.from({length:13},(_,i)=>parseInt($(`e-w${i+1}`).value)||0);
  const filled = d.filter(v=>v>0);
  const avg = filled.length ? Math.round(filled.reduce((a,b)=>a+b,0)/filled.length) : 0;
  const peak = Math.max(...d);
  const peakIdx = d.indexOf(peak);
  const t = filled.length > 1 ? trend(filled[0], filled[filled.length-1]) : 0;
  $('eq-avg').textContent = avg;
  $('eq-peak').textContent = peak > 0 ? peak + ' (Sem '+(peakIdx+1)+')' : '—';
  $('eq-trend').textContent = trendStr(t);
  setColor($('eq-trend'), t);
  const labels = Array.from({length:13},(_,i) => {
    const el = $(`e-date-${i+1}`);
    return (el && el.value) ? el.value : 'Sem '+(i+1);
  });
  const plotData = d.map(v => v > 0 ? v : null);
  if(chartDefs['chartEQ']){ chartDefs['chartEQ'].data.labels=labels; chartDefs['chartEQ'].data.datasets[0].data=plotData; chartDefs['chartEQ'].update(); }
  else makeChart('chartEQ', labels, [lineDS(plotData,'#1D9E75')]);
}

// ===================== KPI 2 — RESUMEN ESTUDIANTES =====================
function updateResumen(){
  // Bajas
  const bV = [1,2,3,4,5,6,7,8].map(i=>parseInt($('b'+i).value)||0);
  $('b-total').textContent = bV.reduce((a,b)=>a+b,0);

  // Activos por idioma
  const idiomas = ['Inglés','Portugués','Japonés','Coreano','Francés','LENSEGUA','Español','Soft Skills'];
  const idiColors = ['#185FA5','#1D9E75','#993C1D','#534AB7','#D85A30','#888780','#BA7517','#AFA9EC'];
  const iV = [1,2,3,4,5,6,7,8].map(i=>parseInt($('i'+i).value)||0);
  const iT = iV.reduce((a,b)=>a+b,0);
  $('i-total').textContent = iT;
  iV.forEach((v,i)=>{
    const p=pct(v,iT);
    const pEl = $('ip'+(i+1));
    const bEl = $('ib'+(i+1));
    if(pEl) pEl.textContent = p;
    if(bEl) bEl.style.width = p;
  });

  // Donut chart activos por idioma
  const nonZeroIdxs = iV.map((v,i)=>i).filter(i=>iV[i]>0);
  makeDoughnutChart('chartIdioma',
    nonZeroIdxs.map(i=>idiomas[i]),
    nonZeroIdxs.map(i=>iV[i]),
    nonZeroIdxs.map(i=>idiColors[i])
  );

  // Geo
  const gNames = Array.from({length:8},(_,i) => {
    const el = $('gn'+(i+1));
    return el ? el.value || 'País '+(i+1) : 'País '+(i+1);
  }).concat(['Otros']);
  const gV = [1,2,3,4,5,6,7,8,9].map(i=>parseInt($('g'+i).value)||0);
  const gT = gV.reduce((a,b)=>a+b,0);
  $('g-total').textContent = gT;
  gV.forEach((v,i) => {
    const el = $('gp'+(i+1));
    if(el) el.textContent = pct(v,gT);
  });
  const geoBar = $('geo-bar');
  if(geoBar) geoBar.innerHTML = gV.map((v,i)=>`<div style="flex:${v||0};background:${GEO_COLORS[i]};min-width:${v>0?'2px':'0'};border-radius:2px;"></div>`).join('');
  const geoLegend = $('geo-legend');
  if(geoLegend) geoLegend.innerHTML = gV.map((v,i)=>v>0 ? `<div class="geo-legend-item"><div class="legend-dot" style="background:${GEO_COLORS[i]};"></div>${gNames[i]}</div>` : '').join('');
}

// ===================== KPI 3 — VENTAS TRIMESTRAL =====================
function updateVQ(){
  const d = Array.from({length:13},(_,i)=>parseInt($(`v-w${i+1}`).value)||0);
  const r = Array.from({length:13},(_,i)=>parseInt($(`v-r${i+1}`) ? $(`v-r${i+1}`).value : 0)||0);
  const total = d.reduce((a,b)=>a+b,0);
  const peakIdx = d.indexOf(Math.max(...d));
  const filled = d.filter(v=>v>0);
  const t = filled.length > 1 ? trend(filled[0], filled[filled.length-1]) : 0;
  $('vq-total').textContent = total;
  const peakLabel = (() => { const el = $(`v-date-${peakIdx+1}`); return (el && el.value) ? el.value : 'Sem '+(peakIdx+1); })();
  $('vq-peak').textContent = total > 0 ? peakLabel : '—';
  $('vq-trend').textContent = trendStr(t);
  setColor($('vq-trend'), t);
  const labels = Array.from({length:13},(_,i) => {
    const el = $(`v-date-${i+1}`);
    return (el && el.value) ? el.value : 'Sem '+(i+1);
  });
  const plotData = d.map(v => v > 0 ? v : null);
  const plotR = r.map(v => v > 0 ? v : null);
  if(chartDefs['chartVQ']){
    chartDefs['chartVQ'].data.labels = labels;
    chartDefs['chartVQ'].data.datasets[0].data = plotR;
    chartDefs['chartVQ'].data.datasets[1].data = plotData;
    chartDefs['chartVQ'].update();
  } else {
    makeChart('chartVQ', labels, [
      lineDS(plotR,'#D85A30',true),
      lineDS(plotData,'#378ADD')
    ]);
  }
}

// ===================== KPI 4 — RESUMEN VENTAS =====================
function updateVR(){
  const bs = (bid, v, t) => { const el=document.getElementById(bid); if(el) el.style.width = pct(v,t); };
  const lV = [1,2,3,4,5,6,7,8].map(i=>parseInt($('vl'+i).value)||0);
  const lT = lV.reduce((a,b)=>a+b,0);
  $('vl-total').textContent = lT;
  lV.forEach((v,i)=>{ const pEl=$('vlp'+(i+1)); if(pEl) pEl.textContent=pct(v,lT); bs('vlb'+(i+1),v,lT); });
  const tV = [1,2,3].map(i=>parseInt($('vt'+i).value)||0);
  const tT = tV.reduce((a,b)=>a+b,0);
  tV.forEach((v,i)=>{ const pEl=$('vtp'+(i+1)); if(pEl) pEl.textContent=pct(v,tT); bs('vtb'+(i+1),v,tT); });
  const cV = [1,2,3,4].map(i=>parseInt($('vc'+i).value)||0);
  const cT = cV.reduce((a,b)=>a+b,0);
  cV.forEach((v,i)=>{ const pEl=$('vcp'+(i+1)); if(pEl) pEl.textContent=pct(v,cT); bs('vcb'+(i+1),v,cT); });
  const vV = [1,2,3,4,5].map(i=>parseInt($('vv'+i).value)||0);
  const vT = vV.reduce((a,b)=>a+b,0);
  $('vv-total').textContent = vT;
  vV.forEach((v,i) => { const pEl=$('vvp'+(i+1)); if(pEl) pEl.textContent = pct(v,vT) + ' del total'; });
}

// ===================== KPI 5 — INGRESOS MENSUAL =====================
function updateFQ(){
  const year = parseInt($('dash-year').value) || 2026;
  const weeks = getWeeksInMonth(year, fCurrentMonth);
  const n = weeks.length;
  const p = Array.from({length:n},(_,i)=>parseInt($('fp'+(i+1)) ? $('fp'+(i+1)).value : 0)||0);
  const r = Array.from({length:n},(_,i)=>parseInt($('fr'+(i+1)) ? $('fr'+(i+1)).value : 0)||0);
  const tP = p.reduce((a,b)=>a+b,0), tR = r.reduce((a,b)=>a+b,0);
  const diff = tR - tP;
  const cp = tP > 0 ? Math.round((tR/tP)*100) : 0;
  $('fq-proj').textContent = fmtQ(tP);
  $('fq-real').textContent = fmtQ(tR);
  $('fq-diff').textContent = (diff>=0?'+':'') + fmtQ(diff);
  setColor($('fq-diff'), diff);
  $('fq-pct').textContent = cp + '%';
  setColor($('fq-pct'), cp - 100);
  const labels = Array.from({length:n},(_,i) => {
    const el = $(`f-date-${i+1}`);
    return (el && el.value) ? el.value : weeks[i] ? weeks[i].label : 'Sem '+(i+1);
  });
  if(chartDefs['chartFQ']){
    chartDefs['chartFQ'].data.labels = labels;
    chartDefs['chartFQ'].data.datasets[0].data = p;
    chartDefs['chartFQ'].data.datasets[1].data = r;
    chartDefs['chartFQ'].update();
  } else {
    makeChart('chartFQ', labels,
      [lineDS(p,'#888780',true), lineDS(r,'#185FA5')],
      v => 'Q' + v.toLocaleString('es-GT'));
  }
}

// ===================== KPI 6 — GASTOS =====================
function updateGastos(){
  const g = Array.from({length:12}, (_,i) => parseInt($('gg'+(i+1)).value)||0);
  const gT = g.reduce((a,b)=>a+b,0);
  $('gt-total').textContent = fmtQ(gT);
  g.forEach((v,i)=>{
    const pEl = $('ggp'+(i+1));
    const bEl = $('ggb'+(i+1));
    if(pEl) pEl.textContent = pct(v,gT);
    if(bEl) bEl.style.width = pct(v,gT);
  });
  const ing = parseInt($('ing').value)||0;
  const operativos = g[1]+g[2]+g[3]+g[4]+g[5]+g[6]+g[7]+g[8]+g[9];
  const mb = ing - g[0];
  const ebit = mb - operativos;
  const util = ebit - g[10] - g[11];
  const margen = ing > 0 ? Math.round((util/ing)*100) : 0;
  $('r-ing').textContent = fmtQ(ing);
  $('r-mb').textContent = (mb<0?'-':'') + fmtQ(mb); setColor($('r-mb'), mb);
  $('r-mb-pct').textContent = pct(mb,ing) + ' de ingresos';
  $('r-ebit').textContent = (ebit<0?'-':'') + fmtQ(ebit); setColor($('r-ebit'), ebit);
  $('r-ebit-pct').textContent = pct(ebit,ing) + ' de ingresos';
  $('r-util').textContent = (util<0?'-':'') + fmtQ(util); setColor($('r-util'), util);
  $('r-util-pct').textContent = pct(util,ing) + ' de ingresos';
  $('margin-val').textContent = margen + '%'; setColor($('margin-val'), util);
  const w = Math.max(0, Math.min(100, Math.abs(margen)));
  $('margin-bar').style.width = w + '%';
  $('margin-bar').style.background = margen >= 30 ? '#1D7A5A' : margen >= 15 ? '#B8730A' : '#C0392B';
}

// ===================== INIT =====================
buildWeekInputs('e','updateEQ');
buildWeekInputs('v','updateVQ');

buildGeoInputs();

// Fill initial Q1 dates for estudiantes and ventas
const initYear = parseInt($('dash-year').value) || 2026;
['e','v'].forEach(prefix => {
  const dates = getQuarterDates(initYear, 1);
  fillDates(prefix, dates);
});

// Init ingresos on Enero
buildFWeekInputs(1);

// Initial calculations
updateEQ();
updateResumen();
updateVQ();
updateVR();
updateFQ();
updateGastos();
</script>
</body>
</html>
```
