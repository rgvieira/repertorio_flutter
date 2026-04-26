from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas

# tamanho A4 em pontos (1 ponto = 1/72 polegada)
width, height = A4

# conversão: 1 mm = 2.83465 pontos
mm_to_pt = 2.83465

def draw_grid(pdf):
    step_mm = 20  # 2 cm
    step_pt = step_mm * mm_to_pt

    # linhas horizontais
    y = 0
    while y <= height:
        pdf.line(0, y, width, y)
        pdf.drawString(5, y + 2, f"{int(y/mm_to_pt)} mm")
        y += step_pt

    # linhas verticais
    x = 0
    while x <= width:
        pdf.line(x, 0, x, height)
        pdf.drawString(x + 2, 10, f"{int(x/mm_to_pt)} mm")
        x += step_pt

# cria PDF
pdf = canvas.Canvas("regua_a4.pdf", pagesize=A4)
draw_grid(pdf)
pdf.showPage()
pdf.save()
o