#!vanilla

repRow = (val, m) -> val for [1..m]

class $blab.Scope extends $blab.d3Object

    constructor: (@spec)->
        
        @hist = repRow(@spec.initVal, @spec.N) # Repeat initial

        super @spec.scope

        @obj.attr("width", @spec.width + @spec.margin.left + @spec.margin.right)
        @obj.attr("height", @spec.height + @spec.margin.top + @spec.margin.bottom)
        @obj.attr("id", "oscillator")

        @obj.append("g")
            .attr("id", "scope-axis")
            .attr("class", "axis")
            .attr("transform","translate(#{@spec.margin.left}, #{@spec.margin.top})")
            .call(@yAxis) 

        @screen = @obj.append('g')
            .attr("id", "screen")
            .attr('width', @spec.width)
            .attr('height', @spec.height)
            .attr("transform","translate(#{@spec.margin.left}, #{@spec.margin.top})")

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
            .range([@spec.height, 0])

        @xScale = d3.scale.linear()
            .domain([0, @spec.N-1])
            .range([0, @spec.width])

        @xAxis = d3.svg.axis()
            .scale(@xScale)
            .orient("bottom")
            .tickFormat(d3.format("d"))

        @yAxis = d3.svg.axis()
            .scale(@yScale)
            .orient("left")

