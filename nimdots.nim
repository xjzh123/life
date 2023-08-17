import math, unicode, strutils

type
    BoolCanvas = seq[seq[bool]]
    StringCanvas = seq[seq[string]]

func heart*(width: int, height: int, trueRange: HSlice[float, float] = -Inf..0.0): BoolCanvas =
    var
        canvas: BoolCanvas

    for canvasY in 0..<height:
        canvas.add(@[])
        for canvasX in 0..<width:
            canvas[canvasY].add(false)
            var
                x = canvasX / width * 3 - 1.5
                y = 1.5 - canvasY / height * 3
            if (x ^ 2 + y ^ 2 - 1) ^ 3 - x ^ 2 * y ^ 3 in trueRange:
                canvas[canvasY][canvasX] = true
            else:
                canvas[canvasY][canvasX] = false

    return canvas

func getPixel*(canvas: BoolCanvas, y, x: int): bool =
    if x in 0..<canvas[0].len and y in 0..<canvas.len:
        canvas[y][x]
    else:
        false

func braille*(canvas: BoolCanvas): StringCanvas =
    let
        height = len(canvas)
        width = len(canvas[0])
        brailleWidth = ceil(width/2).int
        brailleHeight = ceil(height/4).int

    var
        brailleCanvas: StringCanvas

    for brailleY in 0..<brailleHeight:
        brailleCanvas.add(@[])
        for brailleX in 0..<brailleWidth:
            brailleCanvas[brailleY].add(" ")
            var leftX = brailleX * 2
            var topY = brailleY * 4
            brailleCanvas[brailleY][brailleX] = toUTF8(Rune(
                10240 +
                1 * int(canvas.getPixel(topY, leftX)) +
                2 * int(canvas.getPixel(topY + 1, leftX)) +
                4 * int(canvas.getPixel(topY + 2, leftX)) +
                8 * int(canvas.getPixel(topY, leftX + 1)) +
                16 * int(canvas.getPixel(topY + 1, leftX + 1)) +
                32 * int(canvas.getPixel(topY + 2, leftX + 1)) +
                64 * int(canvas.getPixel(topY + 3, leftX)) +
                128 * int(canvas.getPixel(topY + 3, leftX + 1))
            ))

    return brailleCanvas

func drawnCanvas*(canvas: BoolCanvas, trueString: string = "#",
        falseString: string = " "): string =
    for i in canvas:
        for j in i:
            result &= (
                if j:
                    trueString
                else:
                    falseString
            )
        result &= "\n"

func drawnStringCanvas*(brailleCanvas: StringCanvas): string  = ## 无需适配就适用于得意黑等字体
    for line in brailleCanvas:
        for charString in line:
            result &= charString
        result &= "\n"

func brailleStringNoteAdapt*(brailleString: string): string  = ## 适用于Note.ms字体，基本适用于微软雅黑
    return brailleString.replace(
        "⠀⠀⠀⠀⠀⠀⠀", "                   "
    ).replace(
        "⠀⠀⠀⠀", "　　　"
    ).replace("⠀⠀⠀", "　 　").replace("⠀⠀", "　  ").replace("⠀", "⠄")

func brailleStringAdaptLegacy*(brailleString: string): string  = ## 适用于几乎全部包含盲文的字体
    return brailleString.replace(
        "⠀", "⠄"
    )

func brailleStringSongAdapt*(brailleString: string): string  = ## 适用于宋体（等宽）等字体
    return brailleString.replace(
        "⠀⠀⠀⠀⠀⠀⠀⠀", "　　　　　　"
    ).replace(
        "⠀⠀⠀⠀⠀⠀", "　　 　　"
    ).replace(
        "⠀⠀⠀⠀", "　　　"
    ).replace(
        "⠀⠀", "　 "
    )
