import std/[strutils, sequtils, parseopt, random, sugar, terminal, strformat, os]
import nimdots

type Init = enum
  initEmpty,
  initRandom

type Map = seq[seq[bool]]

proc opt(): auto =
  result = (width: 20, height: 20, init: initRandom, prob: 0.2, nogetch: false,
      heatmap: false, debug: false)

  for kind, key, val in getopt(longnoval = @["nogetch", "heatmap", "debug"]):
    echo &"Commandline argument / option: {kind=} {key=} {val=}"

    case kind

    of cmdShortOption:
      case key

      of "w":
        result.width = parseInt(val)

      of "h":
        result.height = parseInt(val)

    of cmdLongOption:
      case key

      of "init":
        case val

        of "empty":
          result.init = initEmpty

        of "random":
          result.init = initRandom

      of "prob":
        result.prob = parseFloat(val)

      of "nogetch":
        result.nogetch = true

      of "heatmap":
        result.heatmap = true

      of "debug":
        result.debug = true

    else:
      discard


template width(map: Map): int = map[0].len


template height(map: Map): int = map.len


func getcell(map: Map, x: int, y: int): bool =
  map[abs((y + map.len) mod map.len)][abs((x + map[0].len) mod map[0].len)]


func nextcell(map: Map, x: int, y: int): bool =
  var sum = 0
  for dx in -1..1:
    for dy in -1..1:
      if dx == 0 and dy == 0:
        continue
      if map.getcell(x+dx, y+dy):
        inc sum

  return
    if map.getcell(x, y): # The result is evaluated with a conditional expression
      sum in 2..3
    else:
      sum == 3


func next(map: Map): auto =
  result = map

  for x in 0..<map.width:
    for y in 0..<map.height:
      result[y][x] = map.nextcell(x, y)


func heatmap(prev: Map, current: Map): Map =
  collect:
    for y in 0..<prev.height:
      collect:
        for x in 0..<prev.width:
          prev[y][x] != current[y][x]


func map_string(map: Map): string =
  drawnStringCanvas(braille(map))[0..^2]


func map_string_with_heatmap(prev, current, heatmap: Map): string =
  let heatmap_string = drawnStringCanvas(braille(heatmap))[0..^2]
  let map_lines = map_string(current).splitLines()
  let heatmap_lines = heatmap_string.splitLines()
  let lines = collect:
    for i in 0..<map_lines.len:
      map_lines[i] & " | " & heatmap_lines[i]
  lines.join("\n")


when isMainModule:
  let options = opt()
  echo options

  if options.init == initRandom:
    randomize()

  var map = collect:
    for i in 0..<options.height:
      collect:
        for i in 0..<options.width:
          case options.init
          of initEmpty:
            false
          of initRandom:
            rand(1.0) < options.prob

  echo &"{map.width=}, {map.height=}"

  var i = 0

  var prev_map = map

  while true:
    if not options.nogetch and getch() != '\13':
      break
    let heatmap = heatmap(prev_map, map)
    if not any(heatmap, line => any(line, cell => cell)) and i != 0:
      echo "The world has stopped."
      quit()
    let temp =
      if options.heatmap:
        map_string_with_heatmap(prev_map, map, heatmap)
      else:
        map_string(map)
    let buffer = &"Life game written in Nim\n{i}th step\n{temp}\n"
    if not options.debug:
      stdout.eraseScreen()
      setCursorPos(0, 0)
    discard stdout.writeBuffer(cstring(buffer), len(buffer))
    prev_map = map
    map = next(map)
    inc i
    if options.nogetch:
      sleep(10)
