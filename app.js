const K="alOracleTrail";let S=JSON.parse(localStorage.getItem(K)||'{"done":{},"pts":0,"sim":{},"tries":{}}');S.tries=S.tries||{};
const save=()=>localStorage.setItem(K,JSON.stringify(S));
const RANKS=[[0,"Scout 🌱"],[800,"Query Writer ✏️"],[2000,"Join Master 🔗"],[3500,"PL/SQL Reader 📜"],[5500,"Recon Pro 🧮"],[8000,"Interview Ready 🌟"]];
const rank=()=>RANKS.filter(r=>S.pts>=r[0]).pop()[1];
const allUnits=()=>TRAILS.flatMap(t=>t.units.map(u=>({...u,trail:t})));
const tDone=t=>t.units.filter(u=>S.done[u.id]).length;
const $=h=>document.getElementById("app").innerHTML=h;
const esc=s=>s.replace(/[&<>"]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[c]));
function stats(){document.getElementById("stats").innerHTML=`<b>${S.pts}</b> pts · ${rank()}<br>${Object.keys(S.done).length}/${allUnits().length} lessons`}
function links(u){return u.links?`<p>📚 Further reading</p><ul>${u.links.map(l=>`<li><a target="_blank" rel="noopener" href="${l[0]}">${l[1]}</a></li>`).join("")}</ul>`:""}
function cp(b){const t=b.nextElementSibling.innerText;(navigator.clipboard?navigator.clipboard.writeText(t):Promise.reject()).then(()=>{b.textContent="Copied ✓";setTimeout(()=>b.textContent="Copy",1500)}).catch(()=>{const r=document.createRange();r.selectNodeContents(b.nextElementSibling);const s=getSelection();s.removeAllRanges();s.addRange(r)})}
function home(){const n=Object.keys(S.done).length,tot=allUnits().length;
$(`<div class="card"><h1>Hai AL 👋</h1>
<p>Irene built this one for you, same warm trail as your Salesforce and Tableau pages. An Oracle SQL and PL/SQL refresher bootcamp, so you can walk into the Coforge Technical BA interview, or any Oracle-heavy role, and feel calm when they say "Can you write that in SQL?"</p>
<p>You already think in data: IBM signings and backlog validation, month-end reporting, Lenovo APJ metrics, Siebel and Salesforce behind the screens, Jira and UAT. This trail puts that thinking into proper Oracle words, one short lesson at a time. Every example was run on a real Oracle database, and you can open the result under each one.</p>
<p>Read on your phone anytime. Practise free on <a target="_blank" rel="noopener" href="https://freesql.com">Oracle FreeSQL</a> (the new Live SQL) after loading the <a href="#schema">practice schema</a>. Jom!</p>
<div class="bar"><i style="width:${n/tot*100}%"></i></div><p>${n}/${tot} lessons · Rank: <b>${rank()}</b></p></div>
<div class="card"><h3>🏅 Badges</h3><div class="badges">${TRAILS.map(t=>`<span class="${tDone(t)==t.units.length?'':'off'}">${t.icon} ${t.title}</span>`).join("")}<span class="${Object.keys(S.sim).length>=SIM.length?'':'off'}">🎤 Interview Ready</span></div></div>
${TRAILS.map(t=>`<a class="card unit" href="#t/${t.id}"><div><b>${t.icon} ${t.title}</b><br><small>${t.desc}</small><div class="bar" style="margin-top:6px"><i style="width:${tDone(t)/t.units.length*100}%"></i></div></div><span>${tDone(t)}/${t.units.length}</span></a>`).join("")}
<a class="card unit" href="#schema"><div><b>🗂️ Practice schema</b><br><small>One script, nine tables, a few hidden data problems. Load it first.</small></div><span>→</span></a>
<a class="card unit" href="#cheat"><div><b>📌 Oracle cheat sheet</b><br><small>Syntax on one page for the night before</small></div><span>→</span></a>
<a class="card unit" href="#xlate"><div><b>🔁 SQL Server / MySQL to Oracle</b><br><small>${XLATE.length} everyday translations</small></div><span>→</span></a>
<a class="card unit" href="#sim"><div><b>🎤 Interview Simulator</b><br><small>${SIM.length} Technical BA and Oracle questions with honest model answers</small></div><span>${Object.keys(S.sim).length}/${SIM.length}</span></a>
<div class="card"><button class="sec" onclick="if(confirm('Reset all progress?')){localStorage.removeItem(K);location.reload()}">Reset progress</button></div>`)}
function trail(id){const t=TRAILS.find(x=>x.id==id);if(!t)return home();
$(`<div class="card"><a href="#">← Home</a><h1>${t.icon} ${t.title}</h1><p>${t.desc}</p></div><div class="card">${t.units.map(u=>`<a class="unit" href="#u/${u.id}"><span>${allUnits().findIndex(x=>x.id==u.id)+1}. ${u.title}</span><span>${S.done[u.id]?'✅ +'+S.done[u.id]:'~'+(u.quiz.length*100+100)+' pts'}</span></a>`).join("")}</div>`)}
let Q;
function unit(id){const u=allUnits().find(x=>x.id==id);if(!u)return home();Q={u,ans:{},short:false};const num=allUnits().findIndex(x=>x.id==id)+1;
$(`<div class="card"><a href="#t/${u.trail.id}">← ${u.trail.title}</a><h1>${num}. ${u.title}</h1>${u.lesson}
${links(u)}</div>
<div class="card"><h3>🧪 Try it</h3><p><small>Have a go in FreeSQL first, then peek. +25 pts the first time you open each solution.</small></p>${u.tries.map((t,i)=>`<div class="try"><p><b>${i+1}.</b> ${t.q}</p><button onclick="tryShow(this,'${u.id}-${i}')">${S.tries[u.id+'-'+i]?'Show solution again':'Show solution'}</button><div style="display:none">${t.s}</div></div>`).join("")}</div>
<div class="card"><h3>✅ Quiz</h3>${u.quiz.map((q,i)=>`<div id="q${i}"><p><b>${i+1}. ${q.q}</b></p>${q.o.map((o,j)=>`<button class="opt" onclick="pick(${i},${j})">${o}</button>`).join("")}<div id="e${i}"></div></div>`).join("")}</div>
${u.short?`<div class="card"><h3>✍️ Your turn</h3><p>${u.short.q}</p><textarea placeholder="Type your answer…"></textarea><button onclick="this.nextElementSibling.style.display='block';Q.short=true;check()">Reveal model answer</button><div class="ex" style="display:none">${u.short.m}</div></div>`:""}
<div class="card" id="fin"></div>`);check()}
function tryShow(b,k){b.nextElementSibling.style.display='block';b.style.display='none';if(!S.tries[k]){S.tries[k]=1;S.pts+=25;save();stats()}}
function pick(i,j){if(Q.ans[i]!=null)return;const q=Q.u.quiz[i];Q.ans[i]=j;
document.querySelectorAll(`#q${i} .opt`).forEach((b,k)=>{if(k==q.a)b.classList.add('ok');else if(k==j)b.classList.add('bad');});
document.getElementById("e"+i).innerHTML=`<div class="ex">${j==q.a?'🎉 Betul!':'😅 Not quite.'} ${q.e}</div>`;check()}
function check(){const u=Q.u,n=Object.keys(Q.ans).length,f=document.getElementById("fin");
if(n<u.quiz.length||(u.short&&!Q.short)){f.innerHTML=`<small>Answer all quiz questions and reveal the model answer to complete this lesson.</small>`;return}
const right=u.quiz.filter((q,i)=>Q.ans[i]==q.a).length,pts=100+right*100;
if(!S.done[u.id]||pts>S.done[u.id]){S.pts+=pts-(S.done[u.id]||0);S.done[u.id]=pts;save();stats()}
const list=allUnits(),idx=list.findIndex(x=>x.id==u.id),nx=list[idx+1],t=u.trail;
f.innerHTML=`<h3>🏁 Lesson complete! ${right}/${u.quiz.length} correct · +${pts} pts</h3>${tDone(t)==t.units.length?`<p>🏅 Badge earned: <b>${t.icon} ${t.title}</b>! Hebat!</p>`:""}
${right<u.quiz.length?`<button class="sec" onclick="unit('${u.id}')">Retry for full points</button>`:""}${nx?`<a class="btn" href="#u/${nx.id}">Next lesson →</a>`:`<a class="btn" href="#sim">On to the interview simulator →</a>`}`}
function sim(){$(`<div class="card"><a href="#">← Home</a><h1>🎤 Interview Simulator</h1><p>Answer out loud or type, then compare with the model answer and rate yourself. +150 pts each. Be honest. These answers use only your real background and never claim production PL/SQL you have not done.</p></div>`+
SIM.map((s,i)=>`<div class="card"><p><b>Q${i+1}. ${s.q}</b></p><textarea></textarea><button onclick="this.nextElementSibling.style.display='block'">Show model answer</button><div class="ex" style="display:none">${s.m}<br><br>How did you do? <button onclick="rate(${i},2)">💪 Nailed it</button><button class="sec" onclick="rate(${i},1)">🙂 Partly</button></div>${S.sim[i]?'<small>✅ done</small>':''}</div>`).join(""))}
function rate(i,v){if(!S.sim[i]){S.pts+=150;save();stats()}S.sim[i]=v;save();sim()}
function schema(){$(`<div class="card"><a href="#">← Home</a><h1>🗂️ Practice schema</h1>${SCHEMA_INTRO}</div>
<div class="card"><h3>The script</h3><p><a class="btn" href="schema.sql" download>⬇️ Download schema.sql</a></p><div class="code"><button class="copy" onclick="cp(this)">Copy</button><pre>${esc(SCHEMA_SQL)}</pre></div></div>`)}
function cheat(){$(`<div class="card cheat"><a href="#">← Home</a><h1>📌 Oracle cheat sheet</h1><p>Everything on one page. Skim it the night before.</p>${CHEAT}</div>`)}
function xlate(){$(`<div class="card"><a href="#">← Home</a><h1>🔁 SQL Server / MySQL to Oracle</h1><p>If you think it in T-SQL or MySQL first, here is how to say it in Oracle. Mentioning one or two of these in an interview shows you have worked across databases.</p>
<div class="tablewrap"><table><tr><th>Task</th><th>SQL Server</th><th>MySQL</th><th>Oracle</th></tr>${XLATE.map(r=>`<tr><td><b>${esc(r[0])}</b></td><td><code>${esc(r[1])}</code></td><td><code>${esc(r[2])}</code></td><td><code>${esc(r[3])}</code></td></tr>`).join("")}</table></div></div>`)}
function route(){const h=location.hash.slice(1).split("/");stats();window.scrollTo(0,0);
if(h[0]=="t")trail(h[1]);else if(h[0]=="u")unit(h[1]);else if(h[0]=="sim")sim();else if(h[0]=="schema")schema();else if(h[0]=="cheat")cheat();else if(h[0]=="xlate")xlate();else home()}
window.addEventListener("hashchange",route);route();
