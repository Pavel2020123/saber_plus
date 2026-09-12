from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor, white
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'output' / 'pdf' / 'SaberPlus_pitch_resumen.pdf'
OUT.parent.mkdir(parents=True, exist_ok=True)
pdfmetrics.registerFont(TTFont('Arial', 'C:/Windows/Fonts/arial.ttf'))
pdfmetrics.registerFont(TTFont('ArialBold', 'C:/Windows/Fonts/arialbd.ttf'))
pdfmetrics.registerFontFamily('Arial', normal='Arial', bold='ArialBold')
W, H = A4
TEAL = HexColor('#176459')
INK = HexColor('#18303A')
GRAY = HexColor('#53656B')
LIGHT = HexColor('#EDF6F3')
BODY = ParagraphStyle('body', fontName='Arial', fontSize=11.5, leading=17,
                      textColor=INK, spaceAfter=0)
SMALL = ParagraphStyle('small', parent=BODY, fontSize=10, leading=14, textColor=GRAY)
c = canvas.Canvas(str(OUT), pagesize=A4)
c.setTitle('SaberPlus | Guía breve para el pitch')
c.setAuthor('Equipo SaberPlus')

def para(text, x, top, width=W-96, style=BODY):
    p = Paragraph(text, style)
    _, h = p.wrap(width, H)
    p.drawOn(c, x, top-h)
    return top-h

def page(number, title, subtitle):
    c.setFillColor(TEAL)
    c.roundRect(48, H-86, 42, 42, 11, fill=1, stroke=0)
    c.setFillColor(white)
    c.setFont('ArialBold', 17)
    c.drawCentredString(69, H-71, 'S+')
    c.setFillColor(TEAL)
    c.setFont('ArialBold', 10)
    c.drawString(102, H-57, 'SABERPLUS / PITCH DEL PROYECTO')
    c.setFillColor(GRAY)
    c.setFont('Arial', 10)
    c.drawString(102, H-76, 'Guía breve para preparar la presentación en Figma')
    c.setFillColor(INK)
    c.setFont('ArialBold', 25)
    c.drawString(48, H-130, title)
    para(subtitle, 48, H-144, style=SMALL)
    c.setStrokeColor(HexColor('#DCE6E3'))
    c.line(48, 47, W-48, 47)
    c.setFillColor(GRAY)
    c.setFont('Arial', 9)
    c.drawString(48, 31, 'SaberPlus | Propuesta académica en desarrollo')
    c.drawRightString(W-48, 31, f'{number} / 2')
    return H-192

def section(n, title, text, y):
    c.setFillColor(TEAL)
    c.setFont('ArialBold', 13)
    c.drawString(48, y, f'{n:02d}  {title}')
    return para(text, 48, y-13)-25

y = page(1, 'La idea y su propósito',
         'Un pitch explica, en pocos minutos, el problema, la solución y a quién ayuda.')
y = section(1, '¿Qué es SaberPlus?',
    '<b>Aprende, identifica tus dificultades y prepárate para Saber 11.</b><br/>'
    'SaberPlus es una aplicación móvil que combina estudio organizado, práctica, '
    'juegos y seguimiento del aprendizaje.', y)
y = section(2, '¿Qué problema solucionamos?',
    'Muchos estudiantes se preparan con materiales dispersos y responden preguntas '
    'sin saber qué temas necesitan reforzar. Además, no todos pueden pagar una '
    'preparación adicional.<br/><b>Buscamos ofrecer una preparación organizada, '
    'accesible y personalizada.</b>', y)
y = section(3, '¿Cuál es nuestro público?',
    '<b>Público principal:</b> estudiantes que se preparan para Saber 11 y egresados '
    'que quieren volver a presentar el examen.<br/>'
    '<b>También:</b> profesores y colegios que necesitan acompañar y supervisar '
    'la preparación de sus estudiantes.', y)
y = section(4, '¿Qué hará la aplicación?',
    '<b>Diagnóstico:</b> identificar áreas por reforzar.<br/>'
    '<b>Estudio:</b> contenido por área, tema y subtema.<br/>'
    '<b>Práctica y simulacros:</b> preguntas con revisión y explicaciones.<br/>'
    '<b>Motivación y seguimiento:</b> progreso, cuaderno de errores, juegos y rachas.', y)
y = para('<b>Ejemplo:</b> si un estudiante presenta dificultades repetidas en regla '
         'de tres, la app podrá orientarlo a reforzar ese subtema. Una sola '
         'respuesta incorrecta no basta para concluir que no lo domina.',
         48, y+4, style=SMALL)
assert y > 60, f'Page 1 overflow: {y}'
c.showPage()

y = page(2, 'El modelo y la presentación',
         'La propuesta comercial y el estado del proyecto deben explicarse con claridad.')
y = section(5, '¿Qué nos diferencia?',
    'Combinamos <b>identificar dificultades, estudiar y practicar</b> en la misma '
    'aplicación. Los juegos y las rachas motivan; el progreso académico se basa '
    'en respuestas y resultados, no solo en puntos.<br/>'
    'No afirmamos ser los únicos sin comparar antes otras aplicaciones.', y)
y = section(6, '¿Cómo ganaremos dinero?',
    '<b>Modelo propuesto: acceso gratuito con publicidad.</b> Las funciones '
    'académicas del estudiante serán gratuitas. El plan de pago quitará anuncios '
    'y añadirá beneficios cosméticos. Habrá anuncios voluntarios con recompensas '
    'válidas en juegos.<br/>Los profesores tendrán una modalidad gratuita y otra '
    'con mayor capacidad de seguimiento institucional.', y)
c.setFillColor(LIGHT)
c.roundRect(48, y-54, W-96, 61, 8, fill=1, stroke=0)
para('<b>Precios propuestos</b><br/>9.900 COP / mes · 49.900 COP / seis meses · '
     '69.900 COP / año', 61, y-3, W-122, SMALL)
y -= 80
y = section(7, '¿Cómo se mostrará en Figma?',
    'Un recorrido corto: <b>inicio, diagnóstico, tema por reforzar, práctica y '
    'progreso</b>. Añadimos una pantalla de un juego como ejemplo de motivación.<br/>'
    'Usamos pantallas reales y distinguimos los diseños de funciones pendientes.', y)
y = section(8, 'Estado actual y siguiente paso',
    'Contamos con una aplicación en desarrollo, un backend propio y un panel '
    'para administrar contenido. El siguiente paso es validar la experiencia '
    'completa con usuarios y contenido revisado antes de publicar.<br/>'
    '<b>Los cobros y anuncios reales todavía requieren implementación y pruebas.</b>', y)
y = para('<b>Frase de cierre</b><br/>“Queremos que el estudiante no solo practique '
         'más, sino que sepa qué necesita aprender y cómo está avanzando.”',
         48, y+2, style=BODY)
assert y > 60, f'Page 2 overflow: {y}'
c.save()
reader = PdfReader(str(OUT))
assert len(reader.pages) == 2
for p in reader.pages:
    assert len(p.extract_text()) > 600
print(f'Created: {OUT} | {len(reader.pages)} pages')
