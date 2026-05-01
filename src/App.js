import { useState, useEffect, useRef, useCallback } from "react";

// ─── 定数 ────────────────────────────────────────────────
const CHAINS = {
  S: { label: "S", name: "Solana",    color: "#14F195" },
  B: { label: "B", name: "BNB Chain", color: "#F0B90B" },
  P: { label: "P", name: "Polygon",   color: "#A978F5" },
};
const REFILL_HOURS     = [4, 10, 16, 22];
const ENERGY_TO_SEC    = 5 * 60;
const ADVANCE_WARN_SEC = 5 * 60; // ← 5分前に変更

// ─── テーマ ──────────────────────────────────────────────
const makeTheme = (light) => light ? {
  bg:        "#eef0f5",
  card:      "#ffffff",
  cardInner: "#f2f4f8",
  text:      "#0f0f1e",
  textSub:   "#6b6b88",
  border:    "#d4d6e2",
  trackBg:   "#d4d6e2",
  btnBg:     "#eef0f5",
  btnText:   "#6b6b88",
  inputBg:   "#f8f9fc",
} : {
  bg:        "#06060e",
  card:      "#10101f",
  cardInner: "#0c0c1a",
  text:      "#dcdcf0",
  textSub:   "#5a5a7a",  // ← コントラスト改善（旧#353550より明るく）
  border:    "#22223a",  // ← 改善（旧#161628より見やすく）
  trackBg:   "#1a1a2e",  // ← 改善
  btnBg:     "#0e0e1c",
  btnText:   "#4a4a6a",  // ← 改善
  inputBg:   "#0a0a16",
};

// ─── 円形プログレス ────────────────────────────────────────
function CircularProgress({ progress, color, trackBg, size = 196, stroke = 7, children }) {
  const r    = (size - stroke * 2) / 2;
  const circ = r * Math.PI * 2;
  const off  = circ * (1 - Math.max(0, Math.min(1, progress)));
  return (
    <div style={{ position: "relative", width: size, height: size }}>
      <svg width={size} height={size}
        style={{ transform: "rotate(-90deg)", position: "absolute", top: 0, left: 0 }}>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={trackBg} strokeWidth={stroke} />
        <circle cx={size/2} cy={size/2} r={r} fill="none"
          stroke={color} strokeWidth={stroke}
          strokeDasharray={circ} strokeDashoffset={off}
          strokeLinecap="round"
          style={{ transition: "stroke-dashoffset 1s linear",
                   filter: `drop-shadow(0 0 10px ${color}99)` }} />
      </svg>
      <div style={{ position:"absolute", inset:0, display:"flex",
        flexDirection:"column", alignItems:"center", justifyContent:"center" }}>
        {children}
      </div>
    </div>
  );
}

// ─── トグル ────────────────────────────────────────────────
function Toggle({ on, onChange, color, trackBg, border }) {
  return (
    <button onClick={onChange} style={{
      width:46, height:26, borderRadius:13, flexShrink:0,
      background: on ? color : trackBg,
      border: `1px solid ${on ? color : border}`,
      cursor:"pointer", position:"relative", transition:"all 0.25s",
    }}>
      <div style={{
        position:"absolute", top:3, left: on ? 23 : 3,
        width:18, height:18, borderRadius:"50%", background:"#fff",
        transition:"left 0.2s", boxShadow: on ? `0 0 8px ${color}` : "none",
      }} />
    </button>
  );
}

// ─── リフィルタイムライン ──────────────────────────────────
function RefillTimeline({ now, color, theme }) {
  const totalMin = now.getHours() * 60 + now.getMinutes();
  const pct = (totalMin / (24 * 60)) * 100;
  return (
    <div style={{ padding:"6px 4px 22px", position:"relative" }}>
      <div style={{
        position:"absolute", top:"calc(50% - 4px)",
        left:4, right:4, height:3,
        background: theme.trackBg, borderRadius:2,
      }} />
      {REFILL_HOURS.map(h => {
        const pos    = (h / 24) * 100;
        const isPast = totalMin > h * 60;
        return (
          <div key={h}>
            <div style={{
              position:"absolute", left:`${pos}%`, top:"calc(50% - 9px)",
              transform:"translateX(-50%)",
              width:10, height:10, borderRadius:"50%", zIndex:2,
              background: isPast ? theme.border : color,
              boxShadow: isPast ? "none" : `0 0 8px ${color}`,
            }} />
            <div style={{
              position:"absolute", left:`${pos}%`, top:20,
              transform:"translateX(-50%)",
              fontSize:9, color: isPast ? theme.textSub : theme.textSub,
              fontFamily:"inherit",
            }}>{h}</div>
          </div>
        );
      })}
      {/* 現在位置マーカー */}
      <div style={{
        position:"absolute", left:`${pct}%`, top:"calc(50% - 11px)",
        transform:"translateX(-50%)",
        width:14, height:14, borderRadius:"50%", zIndex:3,
        background: theme.text,
        boxShadow: `0 0 12px ${theme.text}66`,
      }} />
    </div>
  );
}

// ─── メインアプリ ──────────────────────────────────────────
export default function App() {
  const [light, setLight]   = useState(false);
  const theme = makeTheme(light);

  const [chain, setChain]   = useState("S");

  // セッションエナジー（今から使う量）
  const [energies, setEnergies] = useState({ S: 20, B: 20, P: 20 });
  // 総エナジー上限（¼/½/¾の計算基準）- チェーン別
  const [maxEnergies, setMaxEnergies] = useState({ S: 20, B: 20, P: 20 });

  const [editing,    setEditing]    = useState(false);
  const [editingMax, setEditingMax] = useState(false);
  const [inputVal,   setInputVal]   = useState("20");
  const [inputMax,   setInputMax]   = useState("20");

  const [running,  setRunning]  = useState(false);
  const [timeLeft, setTimeLeft] = useState(0);
  const [total,    setTotal]    = useState(0);
  const [done,     setDone]     = useState(false);
  const [flash,    setFlash]    = useState(false);

  const [notif, setNotif]         = useState({ speech: true, advance: true });
  const [finishMsg, setFinishMsg] = useState("お疲れ様！エナジー使い切ったで！");
  const [showSettings, setShowSettings] = useState(false);
  const [showNotif,    setShowNotif]    = useState(false);
  const [now, setNow] = useState(new Date());

  // stale closure 防止
  const notifRef     = useRef(notif);
  const finishMsgRef = useRef(finishMsg);
  useEffect(() => { notifRef.current     = notif;     }, [notif]);
  useEffect(() => { finishMsgRef.current = finishMsg; }, [finishMsg]);

  const intervalRef = useRef(null);
  const C = CHAINS[chain];

  useEffect(() => {
    const t = setInterval(() => setNow(new Date()), 30000);
    return () => clearInterval(t);
  }, []);

  const speak = useCallback((text) => {
    if (!window.speechSynthesis || !notifRef.current.speech) return;
    window.speechSynthesis.cancel();
    const u = new SpeechSynthesisUtterance(text);
    u.lang = "ja-JP";
    window.speechSynthesis.speak(u);
  }, []);

  // タイマー
  useEffect(() => {
    if (!running) return;
    intervalRef.current = setInterval(() => {
      setTimeLeft(prev => {
        // ← 5分前アナウンス
        if (prev === ADVANCE_WARN_SEC + 1 && notifRef.current.advance) {
          speak("あと5分やで！ゴールはもうすぐや！");
        }
        if (prev <= 1) {
          clearInterval(intervalRef.current);
          setRunning(false);
          setDone(true);
          setFlash(true);
          speak(finishMsgRef.current);
          setTimeout(() => setFlash(false), 3000);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(intervalRef.current);
  }, [running, speak]);

  // チェーン切り替え
  const switchChain = (c) => {
    clearInterval(intervalRef.current);
    setRunning(false);
    setTimeLeft(0);
    setTotal(0);
    setDone(false);
    setEditing(false);
    setEditingMax(false);
    setChain(c);
    setInputVal(String(energies[c]));
    setInputMax(String(maxEnergies[c]));
  };

  // セッションエナジー確定
  const commitEnergy = () => {
    const v = parseFloat(inputVal);
    if (!isNaN(v) && v >= 0) setEnergies(p => ({ ...p, [chain]: Math.min(v, 99) }));
    setEditing(false);
  };

  // 総エナジー上限確定
  const commitMax = () => {
    const v = parseFloat(inputMax);
    if (!isNaN(v) && v > 0) setMaxEnergies(p => ({ ...p, [chain]: Math.min(v, 99) }));
    setEditingMax(false);
  };

  // 固定値ボタン（5〜25EN）→ セッションエナジーを直接セット
  const setQuickFixed = (n) => {
    if (running) return;
    setEnergies(p => ({ ...p, [chain]: n }));
    setInputVal(String(n));
    setDone(false);
  };

  // 分数ボタン（¼/½/¾）→ 総エナジー上限から計算してセッションエナジーをセット
  const setQuickFraction = (numerator, denominator) => {
    if (running) return;
    const base = maxEnergies[chain];
    const val  = Math.round((base * numerator / denominator) * 10) / 10;
    setEnergies(p => ({ ...p, [chain]: val }));
    setInputVal(String(val));
    setDone(false);
  };

  const handleStart = () => {
    if (done) { setDone(false); setTimeLeft(0); setTotal(0); return; }
    if (running) { clearInterval(intervalRef.current); setRunning(false); return; }
    const energy = energies[chain];
    if (energy <= 0) return;
    const sec = Math.round(energy * ENERGY_TO_SEC);
    setTimeLeft(sec); setTotal(sec); setRunning(true);
  };

  const getNextRefill = () => {
    const min = now.getHours() * 60 + now.getMinutes();
    for (const h of REFILL_HOURS) {
      if (min < h * 60) {
        const d = h * 60 - min;
        return `${Math.floor(d / 60)}h ${d % 60}m`;
      }
    }
    const d = (24 * 60 - min) + 4 * 60;
    return `${Math.floor(d / 60)}h ${d % 60}m`;
  };

  const fmt = (sec) => {
    const h = Math.floor(sec / 3600);
    const m = Math.floor((sec % 3600) / 60);
    const s = sec % 60;
    return h > 0
      ? `${h}:${String(m).padStart(2,"0")}:${String(s).padStart(2,"0")}`
      : `${String(m).padStart(2,"0")}:${String(s).padStart(2,"0")}`;
  };

  const energy   = energies[chain];
  const maxEnergy = maxEnergies[chain];
  const progress = total > 0 ? timeLeft / total : 1;
  const totalMin = Math.round(energy * 5);

  const cardStyle = {
    background: theme.card,
    border: `1px solid ${theme.border}`,
    borderRadius: 20,
    padding: "18px 16px",
    marginBottom: 12,
  };

  // 小さい編集インプット用スタイル
  const miniInput = {
    background: theme.inputBg,
    border: `1px solid ${C.color}66`,
    borderRadius: 6,
    color: C.color,
    fontFamily: "inherit",
    fontSize: 11,
    fontWeight: 700,
    outline: "none",
    padding: "3px 6px",
    width: 48,
    textAlign: "center",
  };

  return (
    <div style={{
      minHeight: "100vh",
      background: light
        ? theme.bg
        : "radial-gradient(ellipse at 25% 15%, #0e0e22 0%, #06060e 55%, #020208 100%)",
      display:"flex", justifyContent:"center",
      fontFamily:"'Orbitron', monospace",
      color: theme.text,
      transition:"background 0.3s",
    }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&display=swap');
        *, *::before, *::after { box-sizing:border-box; margin:0; padding:0; }
        input[type=number]::-webkit-inner-spin-button { -webkit-appearance:none; }
        button { transition:transform 0.1s; }
        button:active { transform:scale(0.94) !important; }
        @keyframes pulse    { 0%,100%{opacity:1;transform:scale(1)} 50%{opacity:.7;transform:scale(0.97)} }
        @keyframes blink    { 0%,100%{opacity:1} 50%{opacity:0} }
        @keyframes flashBg  { 0%,100%{filter:brightness(1)} 50%{filter:brightness(1.3)} }
        @keyframes fadeDown { from{opacity:0;transform:translateY(-8px)} to{opacity:1;transform:translateY(0)} }
      `}</style>

      <div style={{
        width:"100%", maxWidth:400, padding:"20px 14px 48px",
        animation: flash ? "flashBg 0.5s ease 3" : "none",
      }}>

        {/* ヘッダー */}
        <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:18 }}>
          <div>
            <div style={{ fontSize:8, color:theme.textSub, letterSpacing:5, marginBottom:3 }}>▶ STEPN PRO</div>
            <div style={{ fontSize:17, fontWeight:900, letterSpacing:3, color:C.color,
              textShadow: light ? "none" : `0 0 20px ${C.color}66` }}>
              ENERGY TOOLS
            </div>
          </div>
          <div style={{ display:"flex", gap:7 }}>
            {[
              { icon:"🔔", active:showNotif,    onClick:() => { setShowNotif(v=>!v); setShowSettings(false); } },
              { icon:"⚙️", active:showSettings, onClick:() => { setShowSettings(v=>!v); setShowNotif(false); } },
              { icon: light ? "🌙" : "☀️", active:false, onClick:() => setLight(v=>!v) },
            ].map(({ icon, active, onClick }, i) => (
              <button key={i} onClick={onClick} style={{
                width:36, height:36, borderRadius:10,
                background: active ? C.color+"22" : theme.btnBg,
                border: `1px solid ${active ? C.color+"88" : theme.border}`,
                color: active ? C.color : theme.textSub,
                cursor:"pointer", fontSize:15,
                display:"flex", alignItems:"center", justifyContent:"center",
              }}>{icon}</button>
            ))}
          </div>
        </div>

        {/* 通知設定パネル */}
        {showNotif && (
          <div style={{ ...cardStyle, border:`1px solid ${C.color}55`, animation:"fadeDown 0.2s ease" }}>
            <div style={{ fontSize:9, color:C.color, letterSpacing:4, marginBottom:14 }}>通知設定</div>
            {[
              { key:"speech",  label:"音声通知",      desc:"終了時に音声で知らせる" },
              { key:"advance", label:"5分前アナウンス", desc:"残り5分（1EN分）で事前に読み上げ" },
            ].map(({ key, label, desc }) => (
              <div key={key} style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:12, gap:8 }}>
                <div>
                  <div style={{ fontSize:12, color:theme.text, marginBottom:2 }}>{label}</div>
                  <div style={{ fontSize:9, color:theme.textSub }}>{desc}</div>
                </div>
                <Toggle on={notif[key]} color={C.color} trackBg={theme.trackBg} border={theme.border}
                  onChange={() => setNotif(p => ({ ...p, [key]: !p[key] }))} />
              </div>
            ))}
          </div>
        )}

        {/* 設定パネル */}
        {showSettings && (
          <div style={{ ...cardStyle, border:`1px solid ${C.color}55`, animation:"fadeDown 0.2s ease" }}>
            <div style={{ fontSize:9, color:C.color, letterSpacing:4, marginBottom:12 }}>設定</div>
            <div style={{ fontSize:9, color:theme.textSub, marginBottom:6 }}>終了時の音声メッセージ</div>
            <input value={finishMsg} onChange={e => setFinishMsg(e.target.value)}
              style={{
                width:"100%", padding:"10px 12px",
                background:theme.inputBg, border:`1px solid ${theme.border}`,
                borderRadius:10, color:theme.text, fontFamily:"inherit", fontSize:11, outline:"none",
              }} />
          </div>
        )}

        {/* チェーンセレクター */}
        <div style={{ display:"flex", gap:8, marginBottom:12 }}>
          {Object.entries(CHAINS).map(([key, c]) => {
            const active = chain === key;
            return (
              <button key={key} onClick={() => switchChain(key)} style={{
                flex:1, padding:"12px 0",
                background: active ? c.color+"1a" : theme.card,
                border: `1px solid ${active ? c.color+"99" : theme.border}`,
                borderRadius:14,
                color: active ? c.color : theme.btnText,
                fontFamily:"inherit", fontWeight:900, fontSize:14, letterSpacing:2,
                cursor:"pointer",
                boxShadow: active ? `0 0 18px ${c.color}22` : "none",
              }}>
                {key}
                {active && <div style={{ width:4, height:4, borderRadius:"50%", background:c.color, margin:"5px auto 0", boxShadow:`0 0 6px ${c.color}` }} />}
              </button>
            );
          })}
        </div>

        {/* メインカード */}
        <div style={{ ...cardStyle, boxShadow: light ? `0 4px 24px ${C.color}14` : `0 0 50px ${C.color}0a` }}>
          <div style={{ textAlign:"center", fontSize:9, color:theme.textSub, letterSpacing:4, marginBottom:14 }}>
            ⚡ MY ENERGY — {C.name.toUpperCase()}
          </div>

          {/* エナジー値 + SET */}
          <div style={{ display:"flex", alignItems:"center", justifyContent:"center", gap:12, marginBottom:4 }}>
            <span style={{ fontSize:20, color:C.color, textShadow:light?"none":`0 0 10px ${C.color}` }}>⚡</span>
            {editing ? (
              <input type="number" value={inputVal} autoFocus min="0" max="99" step="0.5"
                onChange={e => setInputVal(e.target.value)}
                onBlur={commitEnergy}
                onKeyDown={e => e.key==="Enter" && commitEnergy()}
                style={{
                  background:"transparent", border:"none",
                  borderBottom:`2px solid ${C.color}`,
                  color:C.color, fontSize:44, fontWeight:900,
                  fontFamily:"inherit", width:110, outline:"none", textAlign:"center",
                }} />
            ) : (
              <span onClick={() => { if (!running) { setEditing(true); setInputVal(String(energy)); }}} style={{
                fontSize:50, fontWeight:900, color:C.color, letterSpacing:2,
                textShadow:light?"none":`0 0 24px ${C.color}66`,
                cursor:running?"default":"pointer",
              }}>
                {Number.isInteger(energy) ? energy.toFixed(1) : energy}
              </span>
            )}
            <button onClick={() => { if (!running) { setEditing(true); setInputVal(String(energy)); }}} style={{
              background:C.color+"18", border:`1px solid ${C.color}55`,
              color:C.color, borderRadius:8,
              padding:"7px 13px", fontFamily:"inherit", fontSize:9, letterSpacing:2,
              cursor:running?"not-allowed":"pointer", opacity:running?0.35:1,
            }}>SET</button>
          </div>

          <div style={{ textAlign:"center", fontSize:10, color:theme.textSub, marginBottom:22 }}>
            {totalMin} 分 のプレイ時間
          </div>

          {/* 円形プログレス */}
          <div style={{ display:"flex", justifyContent:"center", marginBottom:24 }}>
            <CircularProgress progress={progress} color={C.color} trackBg={theme.trackBg} size={200}>
              {running ? (
                <>
                  <div style={{ display:"flex", alignItems:"center", gap:5, fontSize:9, color:theme.textSub, letterSpacing:3, marginBottom:6 }}>
                    <span style={{ width:6, height:6, borderRadius:"50%", background:C.color, display:"inline-block", animation:"blink 1s infinite", boxShadow:`0 0 6px ${C.color}` }} />
                    RUNNING
                  </div>
                  <div style={{ fontSize:32, fontWeight:900, color:C.color, letterSpacing:2, textShadow:`0 0 20px ${C.color}88` }}>
                    {fmt(timeLeft)}
                  </div>
                  <div style={{ fontSize:9, color:theme.textSub, letterSpacing:2, marginTop:5 }}>REMAINING</div>
                </>
              ) : done ? (
                <>
                  <div style={{ fontSize:26, fontWeight:900, color:C.color, animation:"pulse 1s infinite", textShadow:`0 0 20px ${C.color}` }}>DONE!</div>
                  <div style={{ fontSize:10, color:theme.textSub, marginTop:6 }}>お疲れ様 🏃</div>
                  <div style={{ fontSize:9, color:theme.textSub, marginTop:2 }}>tap RESET</div>
                </>
              ) : (
                <>
                  <div style={{ fontSize:10, color:theme.textSub, letterSpacing:3, marginBottom:8 }}>READY</div>
                  <div style={{ fontSize:30, fontWeight:900, color:C.color, letterSpacing:2 }}>
                    {String(Math.floor(totalMin/60)).padStart(2,"0")}:{String(totalMin%60).padStart(2,"0")}
                  </div>
                  <div style={{ fontSize:9, color:theme.textSub, marginTop:5 }}>{energy.toFixed(1)} EN</div>
                </>
              )}
            </CircularProgress>
          </div>

          {/* 丸いSTARTボタン */}
          <div style={{ display:"flex", justifyContent:"center" }}>
            <button onClick={handleStart} style={{
              width:100, height:100, borderRadius:"50%",
              background: done
                ? theme.cardInner
                : running
                  ? `radial-gradient(circle, ${C.color}18, ${C.color}06)`
                  : `radial-gradient(circle, ${C.color}28, ${C.color}0c)`,
              border:`2.5px solid ${C.color}${done?"44":running?"ee":"bb"}`,
              color:C.color,
              fontFamily:"inherit", fontWeight:900, fontSize:13, letterSpacing:3,
              cursor:"pointer",
              boxShadow: running
                ? `0 0 28px ${C.color}55, 0 0 56px ${C.color}1a`
                : done ? "none"
                : `0 0 18px ${C.color}33`,
              animation: running ? "pulse 2s ease-in-out infinite" : "none",
              textShadow:`0 0 10px ${C.color}88`,
            }}>
              {done ? "RESET" : running ? "STOP" : "START"}
            </button>
          </div>
        </div>

        {/* ─── 簡易設定カード ─── */}
        <div style={cardStyle}>

          {/* ── 上段: 固定値ボタン（5〜25EN）── */}
          <div style={{ marginBottom:16 }}>
            <div style={{ fontSize:9, color:theme.textSub, letterSpacing:3, marginBottom:10 }}>
              クイックセット
            </div>
            <div style={{ display:"grid", gridTemplateColumns:"repeat(5,1fr)", gap:6 }}>
              {[5, 10, 15, 20, 25].map(n => {
                const active = energy === n;
                return (
                  <button key={n} onClick={() => setQuickFixed(n)} style={{
                    padding:"10px 0",
                    background: active ? C.color+"1a" : theme.cardInner,
                    border:`1px solid ${active ? C.color+"bb" : theme.border}`,
                    borderRadius:10, color: active ? C.color : theme.btnText,
                    fontFamily:"inherit", fontSize:9, letterSpacing:1,
                    cursor:running?"not-allowed":"pointer", opacity:running?0.35:1,
                    boxShadow: active ? `0 0 10px ${C.color}22` : "none",
                    fontWeight: active ? 700 : 400,
                  }}>{n}EN</button>
                );
              })}
            </div>
          </div>

          {/* 区切り線 */}
          <div style={{ height:1, background:theme.border, marginBottom:16 }} />

          {/* ── 下段: 分数ボタン（総エナジー上限ベース）── */}
          <div>
            {/* 総エナジー上限の表示・編集 */}
            <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:10 }}>
              <div style={{ fontSize:9, color:theme.textSub, letterSpacing:3 }}>
                分数セット
              </div>
              {/* 総エナジー上限インジケーター */}
              <div style={{ display:"flex", alignItems:"center", gap:6 }}>
                <span style={{ fontSize:9, color:theme.textSub }}>上限 MAX:</span>
                {editingMax ? (
                  <input type="number" value={inputMax} autoFocus min="1" max="99" step="0.5"
                    onChange={e => setInputMax(e.target.value)}
                    onBlur={commitMax}
                    onKeyDown={e => e.key==="Enter" && commitMax()}
                    style={miniInput}
                  />
                ) : (
                  <button onClick={() => { if (!running) { setEditingMax(true); setInputMax(String(maxEnergy)); }}} style={{
                    ...miniInput,
                    background: C.color+"18",
                    border:`1px solid ${C.color}55`,
                    cursor:running?"not-allowed":"pointer",
                    opacity:running?0.5:1,
                  }}>
                    {Number.isInteger(maxEnergy) ? maxEnergy : maxEnergy.toFixed(1)} EN
                  </button>
                )}
              </div>
            </div>

            {/* ¼ / ½ / ¾ ボタン */}
            <div style={{ display:"grid", gridTemplateColumns:"repeat(3,1fr)", gap:6 }}>
              {[
                { label:"¼ EN", num:1, den:4 },
                { label:"½ EN", num:2, den:4 },
                { label:"¾ EN", num:3, den:4 },
              ].map(({ label, num, den }) => {
                const calcVal  = Math.round((maxEnergy * num / den) * 10) / 10;
                const active   = energy === calcVal;
                return (
                  <button key={label} onClick={() => setQuickFraction(num, den)} style={{
                    padding:"10px 0",
                    background: active ? C.color+"1a" : theme.cardInner,
                    border:`1px solid ${active ? C.color+"bb" : theme.border}`,
                    borderRadius:10,
                    color: active ? C.color : theme.btnText,
                    fontFamily:"inherit",
                    cursor:running?"not-allowed":"pointer", opacity:running?0.35:1,
                    fontWeight: active ? 700 : 400,
                  }}>
                    <div style={{ fontSize:13 }}>{label}</div>
                    <div style={{ fontSize:9, color: active ? C.color+"aa" : theme.textSub, marginTop:3 }}>
                      = {calcVal} EN
                    </div>
                  </button>
                );
              })}
            </div>

            {/* 計算式ヒント */}
            <div style={{ marginTop:10, padding:"8px 10px", background:theme.cardInner, borderRadius:8, display:"flex", alignItems:"center", gap:6 }}>
              <span style={{ fontSize:10 }}>💡</span>
              <span style={{ fontSize:9, color:theme.textSub }}>
                上限 {maxEnergy} EN × ¼ = {Math.round(maxEnergy*0.25*10)/10} EN (= {Math.round(maxEnergy*0.25*5)} 分)
              </span>
            </div>
          </div>
        </div>

        {/* リフィルタイムライン */}
        <div style={{ ...cardStyle, marginBottom:0 }}>
          <div style={{ display:"flex", justifyContent:"space-between", alignItems:"baseline", marginBottom:12 }}>
            <div style={{ fontSize:9, color:theme.textSub, letterSpacing:3 }}>ENERGY REFILL</div>
            <div style={{ fontSize:13, fontWeight:700, color:C.color,
              textShadow:light?"none":`0 0 10px ${C.color}66` }}>
              in {getNextRefill()}
            </div>
          </div>
          <RefillTimeline now={now} color={C.color} theme={theme} />
          <div style={{ display:"flex", justifyContent:"space-between", padding:"0 4px", marginTop:2 }}>
            <span style={{ fontSize:8, color:theme.textSub }}>0:00</span>
            <span style={{ fontSize:8, color:theme.textSub }}>24:00</span>
          </div>
        </div>

      </div>
    </div>
  );
}
