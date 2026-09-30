// Evidencia local con dobles de Prisma; no abre conexiones ni utiliza cuentas reales.
// node repro-seguridad.cjs C:/ruta/SaberPlus-Backend/backend
const assert = require('node:assert/strict');
const path = require('node:path');
const root = path.resolve(process.argv[2]);
const { TiraAflojaService } = require(path.join(root, 'dist/tira-afloja/tira-afloja.service.js'));
const { JwtGuard } = require(path.join(root, 'dist/auth/jwt.guard.js'));
const { RankingService, AlcanceRanking, PeriodoRanking } = require(path.join(root, 'dist/ranking/ranking.service.js'));
async function main() {
  const partida = { id:'partida-ficticia', jugadorAId:'a', jugadorBId:'b',
    estado:'FINALIZADA', jugadorA:{id:'a',nombre:'Nombre privado ficticio A',fotoPerfil:null},
    jugadorB:{id:'b',nombre:'Nombre privado ficticio B',fotoPerfil:'/uploads/ficticio.png'},
    preguntas:[], preguntaActual:null, rondaActual:0, posicionCuerda:0 };
  const tx = { $queryRaw:async()=>[], partidaTiraAfloja:{findUnique:async()=>partida} };
  const prisma = { ...tx, $transaction:async f=>f(tx), tiraAflojaEvento:{findMany:async()=>[]} };
  const tira = new TiraAflojaService(prisma,{notificar(){}});
  const result = await tira.obtener('a',partida.id);
  assert.equal(result.partida.rival.nombre, partida.jugadorB.nombre);
  assert.equal(result.partida.rival.id,'b');
  assert.equal(result.partida.rival.fotoPerfil,partida.jugadorB.fotoPerfil);
  await assert.rejects(()=>tira.obtener('otro',partida.id),/No perteneces/);
  console.log('CONFIRMADO P1: el participante recibe nombre privado, UUID y foto del rival; un tercero ajeno es rechazado.');
  const req={headers:{authorization:'Bearer token-ficticio'}};
  const guard=new JwtGuard({verifyAsync:async()=>({sub:'a'})},{usuario:{findUnique:async()=>({correo:'ficticio@example.invalid',nombre:'Ficticio',rol:'ESTUDIANTE',institucionId:null,debeCambiarContrasena:true})}});
  assert.equal(await guard.canActivate({switchToHttp:()=>({getRequest:()=>req})}),true);
  console.log('CONFIRMADO P1: JwtGuard permite una cuenta con cambio de contraseña inicial pendiente (doble de firma válida; no prueba criptográfica).');
  let filter;
  const ranking=new RankingService({usuario:{findUnique:async()=>({id:'p',rol:'PROFESOR',institucionId:'institucion-actual'}),findMany:async q=>{filter=q.where;return Array.from({length:80},(_,i)=>({id:'e'+i,xpTotal:100-i}));}}});
  const board=await ranking.obtenerRanking('p',AlcanceRanking.INSTITUCION,PeriodoRanking.TOTAL,100);
  assert.equal(filter.rol,'ESTUDIANTE');
  assert.equal(filter.institucionId,'institucion-actual');
  const array=Object.values(board).find(v=>Array.isArray(v));
  assert.equal(array.length,80);
  console.log('CONFIRMADO P2: servicio ranking acepta 100 entradas; filtra participantes ESTUDIANTE e institución actual; profesor puede consultar.');
}
main().catch(e=>{console.error(e.message);process.exitCode=1;});
