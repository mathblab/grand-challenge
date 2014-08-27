#!vanilla

# Temp fix - to be done in puzlet.js.
Number.prototype.pow = (p) -> Math.pow this, p

# Global stuff

pi = Math.PI
sin = Math.sin
cos = Math.cos

repRow = (val, m) -> val for [1..m]
{rk, ode} = $blab.ode # Import ODE solver

f = (t, v, mu) -> # VdP equation
    [
        v[1]
        mu*(1-v[0]*v[0])*v[1]-v[0]
    ]

# Classes

class Vector

    z = -> new Vector

    constructor: (@x=0, @y=0) ->
        
    add: (v=z()) ->
        @x += v.x
        @y += v.y
        this
    
    mag: () -> Math.sqrt(@x*@x + @y*@y)
        
    ang: () -> Math.atan2(@y, @x)
        
    polar: (m, a) ->
        @x = m*Math.cos(a)
        @y = m*Math.sin(a)
        this


class Figure # Namespace for globals

    @xMax = 4 # horizontal plot limit
    @yMax = 4 # vertical plot limit
    @margin = {top: 65, right: 65, bottom: 65, left: 65}
    @width = 450 - @margin.left - @margin.top
    @height = 450 - @margin.left - @margin.top
    @xScale = d3.scale.linear() # sim units -> screen units
        .domain([-@xMax, @xMax])
        .range([0, @width])
    @yScale = d3.scale.linear() # sim units -> screen units
        .domain([-@yMax, @yMax])
        .range([@height, 0])


class Canvas

    margin = Figure.margin
    width = Figure.width
    height = Figure.height

    constructor: (id) ->

        @canvas = $(id) 
        @canvas[0].width = width
        @canvas[0].height = height
        @ctx = @canvas[0].getContext('2d')
        
    clear: -> @ctx.clearRect(0, 0, width, height)

    square: (pos, size, color) ->
        @ctx.fillStyle = color
        @ctx.fillRect(pos.x, pos.y, size, size)


class VfPoint # vector field point

    width  = Figure.width
    height = Figure.height
    
    constructor: (@x=1, @y=1, @mu=1) -> # See state function f
        @vel = new Vector 0, 0 # Velocity
        @d = 0 # Distance

    updateVelocity: ->
        vel = f(0, [@x, @y], @mu) # Global state function
        @vel.x = vel[0]
        @vel.y = vel[1]

    move: ->
        @updateVelocity()
        [@x, @y] = ode(rk[1], f, [0, 0.02], [@x, @y], @mu)[1]
        @d += @vel.mag()

    visible: -> (-Figure.xMax <= @x <= Figure.xMax) and
        (-Figure.yMax <= @y <= Figure.yMax) and
        @d < 200
    
class Particle extends VfPoint

    constructor: (@canvas, x, y, mu) ->
        super x, y, mu

        @size = 2
        @color = ["red", "green", "blue"][Math.floor(3*Math.random())]

    draw: ->
        pos = {x:Figure.xScale(@x), y:Figure.yScale(@y)}
        @canvas.square pos, @size, @color


class Emitter
    
    maxParticles: 500
    rate: 3
    
    constructor: (@canvas, @mu=1)->
        @particles = []

    directParticles: ->
        unless @particles.length > @maxParticles
            @particles.push(@newParticles()) for [1..@rate]
            
        @particles = @particles.filter (p) => p.visible()
        for particle in @particles
            particle.move()
            particle.draw()

    newParticles: ->
        u = Figure.xMax*(2*Math.random()-1)
        v = Figure.yMax*(2*Math.random()-1)
        position = new Vector u, v
        new Particle @canvas, position.x, position.y, @mu 

    updateMu: ->
        for particle in @particles
            particle.mu = @mu

    
class Checkbox

    constructor: (@id, @change) ->
        @checkbox = $ "##{id}"
        @checkbox.unbind()  # needed to clear event handlers
        @checkbox.on "change", =>
            val = @val()
            @change val
        
    val: -> @checkbox.is(":checked")
    
class d3Object

    constructor: (id) ->
        @element = d3.select "##{id}"
        @element.selectAll("svg").remove()
        @obj = @element.append "svg"
        @initAxes()
        
    append: (obj) -> @obj.append obj
    
    initAxes: -> 

        
class Oscillator extends d3Object
        
    margin = Figure.margin
    width = Figure.width
    height = Figure.height

    constructor: (X, @spec) ->
        super X 

        # Clear any previous event handlers.
        @obj.on("click", null)  
        d3.behavior.drag().on("drag", null)
       
        @obj.attr("width", width + margin.left + margin.right)
        @obj.attr("height", height + margin.top + margin.bottom)
        @obj.attr("id", "oscillator")

        @obj.append("g") # x axis
            .attr("class", "axis")
            .attr("transform", "translate(#{margin.left}, #{margin.top+height+10})")
            .call(@xAxis) 

        @obj.append("g") # y axis
            .attr("class", "axis")
            .attr("transform","translate(#{margin.left-10}, #{margin.top})")
            .call(@yAxis) 

        @plot = @obj.append("g") # Plot area
            .attr("id", "plot")
            .attr("transform", "translate(#{margin.left},#{margin.top})")

        @limitCircle = @plot.append("circle")
            .attr("cx", @xscale 0)
            .attr("cy", @yscale 0)
            .attr("r", @xscale(2)-@xscale(0))
            .style("fill", "transparent")
            .style("stroke", "ccc")

        @guide0 = @radialLine(@spec.guide0color)
        @guide1 = @radialLine(@spec.guide1color)

        @marker0 = @marker(@spec.marker0color, @guide0)
        @marker1 = @marker(@spec.marker1color, @guide1)

        @moveMarker(@marker0, -1000, -1000) # initially hide off-screen
        @moveMarker(@marker1, -1000, -1000)

    marker: (color, guide) ->
        m = @plot.append("circle")
            .attr("r",10)
            .style("fill", color)
            .style("stroke", color)
            .style("stroke-width","1")
            .call(
                d3.behavior
                .drag()
                .origin(=>
                    x:m.attr("cx")
                    y:m.attr("cy")
                )
                .on("drag", => @dragMarker(m, d3.event.x, d3.event.y, guide))
            )
        
    radialLine: (color) ->
        @plot.append('line')
            .attr("x1", @xscale 0)
            .attr("y1", @yscale 0)
            .style("stroke", color)
            .style("stroke-width","1")
        
    dragMarker: (marker, u, v, guide) ->
        marker.attr("cx", u)
        marker.attr("cy", v)
        phi = Math.atan2(@yscale.invert(v), @xscale.invert(u))
        guide.attr("x2", @xscale Figure.xMax*cos(phi))
        guide.attr("y2", @yscale Figure.xMax*sin(phi))

    moveMarker: (marker, u, v) ->
        marker.attr("cx", u)
        marker.attr("cy", v)

    moveGuide: (guide, phi) ->
        guide.attr("x2", @xscale Figure.xMax*cos(phi))
        guide.attr("y2", @yscale Figure.yMax*sin(phi))
         
    initAxes: ->
        @xscale = Figure.xScale
        @xAxis = d3.svg.axis()
            .scale(@xscale)
            .orient("bottom")
        @yscale = Figure.yScale
        @yAxis = d3.svg.axis()
            .scale(@yscale)
            .orient("left")


class Scope extends d3Object

    margin = Figure.margin
    width = Figure.width
    height = Figure.height
    
    constructor: (@spec)->
        
        @hist = repRow(@spec.initVal, @spec.N) # Repeat initial

        super @spec.scope

        @obj.attr("width", width + margin.left + margin.right)
        @obj.attr("height", height + margin.top + margin.bottom)
        @obj.attr("id", "oscillator")

        @obj.append("g")
            .attr("id", "scope-axis")
            .attr("class", "axis")
            .attr("transform","translate(#{margin.left}, #{margin.top})")
            .call(@yAxis) 

        @screen = @obj.append('g')
            .attr("id", "screen")
            .attr('width', width)
            .attr('height', height)
            .attr("transform","translate(#{margin.left}, #{margin.top})")

        gradient = @obj.append("svg:defs") # https://gist.github.com/mbostock/1086421
            .append("svg:linearGradient")
            .attr("id", "gradient")
            .attr("x1", "100%")
            .attr("y1", "100%")
            .attr("x2", "0%")
            .attr("y2", "100%")
            .attr("spreadMethod", "pad");

        gradient.append("svg:stop")
            .attr("offset", "0%")
            .attr("stop-color", "white")
            .attr("stop-opacity", 1);

        gradient.append("svg:stop")
            .attr("offset", "100%")
            .attr("stop-color", @spec.color)
            .attr("stop-opacity", 1);

        @line = d3.svg.line()
            .x((d) =>  @xScale(d))
            .y((d,i) =>  @hist[i])
            .interpolate("basis")

        if @spec.fade
            strokeSpec = "url(#gradient)"
        else
            strokeSpec = @spec.color    
                                           
        @screen.selectAll('path.trace')
            .data([[0...@spec.N]])
            .enter()
            .append("path")
            .attr("d", @line)
            .attr("class", "trace")
            .style("stroke", strokeSpec)
            .style("stroke-width", 2)

    draw: (val) ->
        @hist.unshift val
        @hist = @hist[0...@hist.length-1]
        @screen.selectAll('path.trace').attr("d", @line)

    show: (bit) ->
        if bit
            @obj.attr("visibility", "visible")
        else
            @obj.attr("visibility", "hidden")
                                                                    
    initAxes: ->
        
        @yScale = d3.scale.linear()
            .domain([@spec.yMin, @spec.yMax])
            .range([height, 0])

        @xScale = d3.scale.linear()
            .domain([0, @spec.N-1])
            .range([0, width])

        @xAxis = d3.svg.axis()
            .scale(@xScale)
            .orient("bottom")
            .tickFormat(d3.format("d"))

        @yAxis = d3.svg.axis()
            .scale(@yScale)
            .orient("left")

class VdPSim

    constructor: ->

        @canvas = new Canvas "#VdP-vector-field"

        @oscillator = new Oscillator "VdP-oscillator",
            marker0color: "black"
            marker1color: "transparent"
            guide0color: "transparent"
            guide1color: "transparent"

        @vectorField = new Emitter @canvas
        @markerPoint = new VfPoint

        @scopeX = new Scope
            scope : "x-scope"
            initVal : Figure.xScale(@markerPoint.x)
            color : "green"
            yMin : -4
            yMax : 4
            width : Figure.width
            height : Figure.height
            N: 255
            fade: 0

        @scopeY = new Scope
            scope : "y-scope"
            initVal: Figure.yScale(@markerPoint.y)
            color : "red"
            yMin : -4
            yMax : 4
            width : Figure.width
            height : Figure.height
            N: 255
            fade: 0

        @persist = new Checkbox "persist" , (v) =>  @.checked = v

        $("#mu-slider").on "change", => @updateMu()
        @updateMu()

        d3.selectAll("#intro-stop-button").on "click", => @stop()
        d3.selectAll("#intro-start-button").on "click", => @start()

    updateMu: ->
        k = parseFloat(d3.select("#mu-slider").property("value"))
        @markerPoint.mu = k
        @vectorField.mu = k
        @vectorField.updateMu() 
        d3.select("#mu-value").html(k)
        
    snapshot1: ->
        @canvas.clear() if not @.checked
        @vectorField.directParticles()
        @drawMarker()

    snapshot2: ->
        @scopeX.draw Figure.xScale(-1*@markerPoint.x) # ? -1 ?
        @scopeY.draw Figure.yScale(@markerPoint.y)

    drawMarker: ->
        @markerPoint.move()
        @oscillator.moveMarker(@oscillator.marker0,
            Figure.xScale(@markerPoint.x),
            Figure.yScale(@markerPoint.y)
        )

    animate: ->
        @timer1 = setInterval (=> @snapshot1()), 20
        @timer2 = setInterval (=> @snapshot2()), 50

    stop: ->
        clearInterval @timer1
        clearInterval @timer2
        @timer1 = null
        @timer2 = null

    start: ->
        setTimeout (=> @animate() ), 20

new VdPSim
