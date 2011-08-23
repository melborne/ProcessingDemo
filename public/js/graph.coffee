class Integrator
  # Ben Fry's Integrator
  constructor: (@value, @damping=0.5, @attraction=0.2) ->
    @mass = 1
    @targeting = false
    @vel = 0
    @force = 0.1

  update: ->
    if @targeting
      @force += @attraction * (@target - @value)
    accel = @force / @mass
    @vel = (@vel + accel) * @damping
    @value += @vel
    @force = 0

  set_target: (t) ->
    @targeting = true
    @target = t

[can_w, can_h] = [$(window).width(), 600]
[borderLeft, borderRight, borderTop, borderBottom] = [120, can_w-80, 60, can_h-70]
[dataMin, dataMax] = [0, 0]
[yInterval, yIntervalMinor, xInterval] = [0, 0, 0]
[xMin, yMin] = [0, 0]
[rowCount, columnCount, currentColumn] = [0, 0, 0]
[label, data] = [null, null]
[tabTop, tabBottom] = [borderTop - 35, borderTop]
[tabLeft, tabRight] = [[borderLeft], [borderLeft]]
tabPad = 10
color_set = [[138,192,222],[133,219,24],[246, 177, 195]]
areaColor = color_set[0]
interpolators = []

graph = (p) ->
  p.setup = ->
    [rowCount, columnCount] = [data.length-1, label.length-1]
    [dateMin, dateMax] = [data[0][columnCount], data[rowCount][columnCount]]
    [xMin, xMinorMin, xMinorSubMin] = [dateMin[0], dateMin[1], dateMin[2]]
    [yMin, xMinorMax, xMinorSubMax] = [dateMax[0], dateMax[1], dateMax[2]]
    p.size(can_w, can_h)
    p.frameRate(20)
    p.smooth()
    setTabPositions(p)
    for row in [0..rowCount]
      interpolators[row] = new Integrator(0)
      interpolators[row].set_target(data[row][0])

  p.draw = ->
    drawMainFrame(p)
    
    for row in [0..rowCount]
      interpolators[row].update()
      
    drawDataArea(p, areaColor)
    drawXLabels(p)
    drawYLabels(p)
    drawDataHighlight(p, [255, 63, 0])
    drawTabs(p)

  p.mousePressed = ->
    if tabTop < p.mouseY < tabBottom
      for col in [0..columnCount-1]
        if tabLeft[col] < p.mouseX < tabLeft[col] + label[col].length*15
          setCurrent(col)
  
  setCurrent = (col)->
    currentColumn = col
    areaColor = color_set[col]
    for row in [0..rowCount]
      interpolators[row].set_target(data[row][col])

  drawMainFrame = (p)->
    p.background(224)
    p.fill(255)
    p.rectMode(p.CORNERS)
    p.noStroke()
    p.rect(borderLeft, borderTop, borderRight, borderBottom)
  
  setTabPositions = (p)->
    for col in [0...columnCount]
      tabLeft[col] = tabRight[col-1] if col > 0
      tabRight[col] = tabLeft[col] + label[col].length*12+15

  drawTabs = (p)->
    for col in [0..columnCount-1]
      [x1,x2,y1,y2] = [tabLeft[col], tabTop, tabRight[col]-1, tabBottom]
      bgcolor = if col is currentColumn then 255 else 100
      p.fill(bgcolor)
      p.noStroke()
      p.rect(x1, x2, y1, y2)

      title = label[col]
      p.fill(0)
      p.textAlign(p.CENTER, p.CENTER)
      p.textSize(20)
      padLeft = (tabRight[col] - tabLeft[col])/2
      padTop = (tabBottom - tabTop)/2
      p.text(title, x1+padLeft, x2+padTop)

  drawXLabels = (p)->
    p.fill(0)
    p.textSize(10)
    p.textAlign(p.CENTER, p.TOP)
    p.stroke(255)
    p.strokeWeight(2)
  
    for xval in [xMin..yMin] by xInterval
      x = p.map(xval, xMin, yMin, borderLeft, borderRight)
      p.text(xval, x, borderBottom+10)
      p.line(x, borderTop, x, borderBottom)
  
  drawYLabels = (p)->
    p.fill(0)
    p.textSize(10)
    p.stroke(128)
    p.strokeWeight(1)
  
    for v in [dataMin..dataMax] by yIntervalMinor
      y = p.map(v, dataMin, dataMax, borderBottom, borderTop)
      if v % yInterval is 0
        switch v
          when dataMin, dataMax then p.textAlign(p.RIGHT)
          else p.textAlign(p.RIGHT, p.CENTER)
        p.text(p.floor(v), borderLeft-10, y)
        p.line(borderLeft-4, y, borderLeft, y)
      else
        p.line(borderLeft-2, y, borderLeft, y)

  drawDataArea = (p, color)->
    [r,g,b] = color
    p.fill(r,g,b)
    p.noStroke()
    p.beginShape()
    p.vertex(borderLeft, borderBottom)
    for row in [0..rowCount]
      year = data[row][columnCount][0]
      val = interpolators[row].value
      x = p.map(year, xMin, yMin, borderLeft, borderRight)
      y = p.map(val, dataMin, dataMax, borderBottom, borderTop)
      p.curveVertex(x, y)
      if row is 0 or row is rowCount
        p.curveVertex(x, y)
    p.vertex(borderRight, borderBottom)
    p.vertex(borderRight, borderBottom)
    p.endShape(p.CLOSE)

  drawDataHighlight = (p, color)->
    [r,g,b] = color
    for row in [0..rowCount]
      year = data[row][columnCount][0]
      val  = data[row][currentColumn]
      x = p.map(year, xMin, yMin, borderLeft, borderRight)
      y = p.map(val, dataMin, dataMax, borderBottom, borderTop)
      if x - 6 < p.mouseX < x + 6 and borderTop < p.mouseY < borderBottom
        p.stroke(r,g,b)
        p.strokeWeight(6)
        p.point(x, y)
        p.strokeWeight(1)
        p.line(x, borderTop, x, borderBottom)
        p.fill(0)
        p.textSize(16)
        p.textAlign(p.LEFT)
        p.text("#{val}(#{year})", x+3, y+20)
        
$ ->
  path = window.location.href.match(/\/\w+$/)
  $.getJSON "#{path}.json", (json) ->
    label = json.label
    data = json.data
    dataMax = Math.ceil(json.dataMax/10.0)*10
    dataMin = if json.dataMin > 0 then 0 else json.dataMin
    [yInterval, yIntervalMinor, xInterval] = json.intervals

    canvas = $("#processing")[0]
    processing = new Processing(canvas, graph)
