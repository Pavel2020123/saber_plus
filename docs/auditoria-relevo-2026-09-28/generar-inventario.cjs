const fs=require('fs'),path=require('path'),cp=require('child_process'),crypto=require('crypto');
const roots={Flutter:path.resolve(__dirname,'../..'),Backend:path.resolve(process.argv[2]||'../SaberPlus-Backend')};
const out=roots.Flutter+'/docs/auditoria-relevo-2026-09-28';
const ts=require(roots.Backend+'/backend/node_modules/typescript');
const esc=s=>String(s??'').replace(/\|/g,'\\|').replace(/[\r\n]+/g,' ').replace(/\s+/g,' ').trim();
const tracked=r=>cp.execFileSync('git',['-c','core.quotePath=false','ls-files','-z'],{cwd:r}).toString().split('\0').filter(Boolean);
const files=[],texts=new Map();
for(const [repo,root] of Object.entries(roots))for(const f of tracked(root)){
 const b=fs.readFileSync(root+'/'+f),binary=/\.(png|mp3|jpg|jpeg|ico|pdf|zip|jar|ttf|woff2?)$/i.test(f),generated=/\.g\.dart$|package-lock\.json$|pubspec.lock$/.test(f);
 const text=binary?'':b.toString('utf8'); if(!binary)texts.set(repo+':'+f,text);
 const symbols=[...text.matchAll(/(?:export\s+)?(?:abstract\s+)?(?:class|enum|model|interface|mixin)\s+(\w+)/g)].map(m=>m[1]);
 files.push({repo,file:f,bytes:b.length,lines:binary?null:text.split('\n').length,sha256:crypto.createHash('sha256').update(b).digest('hex'),kind:binary?'ASSET BINARIO':generated?'GENERADO/LOCK':/\.md$/.test(f)?'DOCUMENTACION':/test|spec/.test(f)?'PRUEBA':'CODIGO/CONFIG',symbols});
}
fs.writeFileSync(out+'/inventario.json',JSON.stringify(files,null,2)+'\n');
fs.writeFileSync(out+'/inventario.md','# Inventario de archivos versionados\n\nLectura estructural del contenido textual; no equivale a verificación funcional de cada línea. Binarios identificados por función/ruta; generados y lockfiles se clasifican aparte. SHA-256 y símbolos completos en inventario.json. Archivos nuevos de esta auditoría no forman parte de HEAD.\n\n| Repo | Archivo | Tipo | Líneas | Símbolos |\n|---|---|---|---:|---|\n'+files.map(x=>`| ${x.repo} | ${esc(x.file)} | ${x.kind} | ${x.lines??'—'} | ${esc(x.symbols.join(', '))} |`).join('\n')+'\n');
const decs=n=>(ts.canHaveDecorators(n)?ts.getDecorators(n):[])||[];
const dec=(n,name)=>decs(n).filter(d=>ts.isCallExpression(d.expression)&&d.expression.expression.getText()===name).map(d=>d.expression);
const val=n=>!n?'':ts.isStringLiteral(n)||ts.isNoSubstitutionTemplateLiteral(n)?n.text:n.getText();
const allclasses=new Map(),sources=[];
for(const [key,text] of texts)if(key.startsWith('Backend:backend/src/')&&key.endsWith('.ts')&&!key.endsWith('.spec.ts')){
 const file=key.slice(8), sf=ts.createSourceFile(file,text,ts.ScriptTarget.Latest,true);sources.push(sf);
 for(const c of sf.statements)if(ts.isClassDeclaration(c)&&c.name)allclasses.set(c.name.text,{c,sf,file});
}
const endpoints=[];
for(const sf of sources)for(const c of sf.statements){if(!ts.isClassDeclaration(c)||!dec(c,'Controller').length)continue;
 const bases=dec(c,'Controller').flatMap(d=>{const a=d.arguments[0];return a&&ts.isArrayLiteralExpression(a)?a.elements.map(val):[val(a)]});
 const ctor=c.members.find(ts.isConstructorDeclaration),inject=new Map((ctor?.parameters||[]).map(p=>[p.name.getText(),p.type?.getText()]));
 for(const m of c.members){if(!ts.isMethodDeclaration(m))continue;for(const d of decs(m)){
  if(!ts.isCallExpression(d.expression))continue;const verb=d.expression.expression.getText();if(!['Get','Post','Put','Patch','Delete','All','Head','Options'].includes(verb))continue;
  const a=d.expression.arguments[0],parts=a&&ts.isArrayLiteralExpression(a)?a.elements.map(val):[val(a)];
  const guards=[...dec(c,'UseGuards'),...dec(m,'UseGuards')].flatMap(d=>d.arguments.map(x=>x.getText()));
  if(dec(m,'RetiredEditorialWrite').length) guards.push('LegacyEditorialWriteGuard (410)');
  if(dec(m,'InstitutionReviewAccess').length) guards.push('InstitutionReviewAccess (exenci?n operacional, no de identidad)');
  const calls=[...m.getText().matchAll(/this\.(\w+)\.(\w+)\s*\(/g)].map(x=>({property:x[1],method:x[2],type:inject.get(x[1])}));
  const services=calls.map(x=>{const sc=allclasses.get(x.type),sm=sc?.c.members.find(n=>ts.isMethodDeclaration(n)&&n.name.getText()===x.method);return {...x,file:sc?.file,line:sm?sc.sf.getLineAndCharacterOfPosition(sm.getStart()).line+1:null,body:sm?.getText()||''}});
  for(const base of bases)for(const part of parts){const route='/'+[base,part].filter(Boolean).join('/');
   const literal=route.split('/:')[0];
   const consumers=kind=>[...texts].filter(([k,t])=>k.startsWith(kind==='Flutter'?'Flutter:lib/':'Backend:admin/public/')&&t.includes(literal)&&literal.length>2).map(([k])=>k.split(':').slice(1).join(':'));
   const testfiles=files.filter(x=>x.repo==='Backend'&&x.kind==='PRUEBA'&&(x.file.startsWith(path.posix.dirname(sf.fileName)+'/')||services.some(s=>s.type&&texts.get('Backend:'+x.file)?.includes(s.type)))).map(x=>x.file);
   endpoints.push({method:verb.toUpperCase(),route,controller:c.name.text,symbol:m.name.getText(),file:sf.fileName,line:sf.getLineAndCharacterOfPosition(m.getStart()).line+1,guards,params:m.parameters.map(p=>p.getText()),responseType:m.type?.getText()||'Inferida; ver devolución de servicio',returns:[...m.getText().matchAll(/return\s+([^;]+);/g)].map(x=>x[1]),services:services.map(({body,...s})=>s),prisma:[...new Set(services.flatMap(s=>[...s.body.matchAll(/(?:this\.)?(?:prisma|tx)\.(\w+)/g)].map(x=>x[1])))],flutter:consumers('Flutter'),admin:consumers('ADMIN'),tests:[...new Set(testfiles)],body:m.getText()});
  }
 }}
}
fs.writeFileSync(out+'/endpoints.json',JSON.stringify(endpoints,null,2)+'\n');
fs.writeFileSync(out+'/endpoints.md','# Matriz B — Endpoints desde AST TypeScript\n\nExtracción de todos los decoradores HTTP de controllers, incluidos controllers dentro de module.ts. Guards acumulados de clase/método. Los consumidores son candidatos por prefijo literal: requieren contraste manual (ver informe). «Sin coincidencia» no demuestra endpoint huérfano. Prisma enumera acceso directo del método llamado; auxiliares/transacciones pueden añadir modelos. Tests son archivos relacionados, no prueba de cobertura individual del endpoint. JSON conserva parámetros y delegación completos.\n\n| Método | Ruta | Auth | Guards/Roles | DTO entrada | Respuesta | Servicio | Prisma directo | Consumidor Flutter (candidato) | Consumidor ADMIN (candidato) | Tests relacionados | Evidencia / Observaciones |\n|---|---|---|---|---|---|---|---|---|---|---|---|\n'+endpoints.map(e=>[e.method,e.route,e.guards.length?'Ver guards':'Sin guard declarado',e.guards.join(', ')||'—',e.params.join('; '),e.responseType+'; '+e.returns.join('; '),e.services.map(s=>`${s.type||s.property}.${s.method}${s.file?' ('+s.file+':'+s.line+')':''}`).join('; '),e.prisma.join(', ')||'Indirecto/ninguno',e.flutter.join('; ')||'Sin coincidencia literal',e.admin.join('; ')||'Sin coincidencia literal',e.tests.join('; ')||'Sin prueba relacionada localizada',`${e.file}:${e.line} ${e.controller}.${e.symbol}`].map(esc).join(' | ')).map(s=>'| '+s+' |').join('\n')+'\n');
const schema=texts.get('Backend:backend/prisma/schema.prisma'),models=[...schema.matchAll(/^(model|enum)\s+(\w+)\s*\{([\s\S]*?)^\}/gm)].map(m=>({kind:m[1],name:m[2],line:schema.slice(0,m.index).split('\n').length,definition:m[3]}));
const migrations=files.filter(x=>x.repo==='Backend'&&x.file.endsWith('/migration.sql')).map(x=>({...x,sql:texts.get('Backend:'+x.file)}));
fs.writeFileSync(out+'/datos.md','# Matriz C — Esquema y migraciones\n\nInventario completo del schema actual y SQL versionado. No acredita aplicación en Supabase. Las pruebas de PostgreSQL de esta ronda se bloquearon por binarios ausentes. El informe interpreta por dominio las restricciones y riesgos.\n\n'+models.map(m=>`## ${m.kind} ${m.name}\n\nFuente: backend/prisma/schema.prisma:${m.line}\n\n\`\`\`prisma\n${m.kind} ${m.name} {${m.definition}}\n\`\`\`\n`).join('\n')+'\n## Migraciones, en orden\n\n'+migrations.map(m=>`### ${m.file.split('/')[3]}\n\nFuente: ${m.file}; SHA-256 ${m.sha256}.\n\n\`\`\`sql\n${m.sql.trim()}\n\`\`\`\n`).join('\n'));
const debt=[];for(const [key,t] of texts)if(!/package-lock|pubspec.lock|\.g.dart/.test(key))t.split('\n').forEach((line,i)=>{const tags=line.match(/\b(TODO|FIXME|HACK|TEMP|mock|demo|fake|hardcoded)\b/gi);if(tags)debt.push({file:key,line:i+1,tags:[...new Set(tags.map(s=>s.toLowerCase()))]})});
fs.writeFileSync(out+'/marcadores-deuda.json',JSON.stringify(debt,null,2)+'\n');
fs.writeFileSync(process.env.TEMP+'/saberplus-endpoint-summary.txt',endpoints.map(e=>`${e.method} ${e.route} [${e.guards}] ${e.services.map(s=>s.type+'.'+s.method).join(',')}`).join('\n'));
console.log(JSON.stringify({files:files.length,endpoints:endpoints.length,models:models.filter(m=>m.kind==='model').length,enums:models.filter(m=>m.kind==='enum').length,migrations:migrations.length,debtMarkers:debt.length}));
