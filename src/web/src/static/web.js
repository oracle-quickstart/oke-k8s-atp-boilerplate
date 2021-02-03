const points = 200
let data = {};

const margin = {top: 20, right: 20, bottom: 30, left: 50},
    width = 960 - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom;


const chart = () => {
    d3.select("body").select("svg").remove();
    const svg = d3.select("body").append("svg")
                .attr("width", width + margin.left + margin.right)
                .attr("height", height + margin.top + margin.bottom)
                .append("g")
                .attr("transform",
                    "translate(" + margin.left + "," + margin.top + ")");

    var x = d3.scaleTime().range([0, width]);
    var y = d3.scaleLinear().range([height, 0]);
    const colors = d3.scaleOrdinal(d3.schemeCategory20)

    // Scale the range of the data
    const hostnames = Object.keys(data);
    const xExtents = hostnames.map(h => d3.extent(data[h], function(d) { return new Date(d.date * 1000); }));
    const yExtents = hostnames.map(h => d3.extent(data[h], function(d) { return d.value; }));
    x.domain([Math.min(...xExtents.map(e => e[0])), Math.max(...xExtents.map(e => e[1]))]);
    y.domain([Math.min(...yExtents.map(e => e[0])), Math.max(...yExtents.map(e => e[1]))]);

    var valueline = d3.line()
        .x(function(d) { return x(new Date(d.date * 1000)); })
        .y(function(d) { return y(d.value); });

    // Add the valueline path.
    svg.select("path").remove();
    svg.select("g").remove();
    Object.keys(data).map((k) => {
        svg.append("path")
            .data([data[k]])
            .attr("class", "line")
            .attr("stroke", colors(k))
            .attr("d", valueline);
    })
    
    // Add the X Axis
    svg.append("g")
        .attr("transform", "translate(0," + height + ")")
        .call(d3.axisBottom(x)
                // .tickFormat(d3.timeFormat("%H:%M:%s"))
            );

    // Add the Y Axis
    svg.append("g")
        .call(d3.axisLeft(y));
}

let timerId; 
const  throttleFunction  =  function (func, delay) {
	if (timerId) { return; }
	timerId  =  setTimeout(function () {
		func()
		timerId  =  undefined;
	}, delay)
}

// Subscribe to the event data stream
const eventSource = new EventSource("/data", { withCredentials: true });

eventSource.onmessage = function(event) {
    // On data received, parse JSON and render chart
    const eventData = JSON.parse(event.data);
    // console.log(data);
    if (!data[eventData['host']]) {
        data[eventData['host']] = []
    }
    const lastTick = eventData['date'];
    data[eventData['host']].unshift(eventData);

    Object.keys(data).forEach(k => {
        data[k] = data[k].slice(0, points);
        while (data[k][data[k].length - 1] < (lastTick - points * 0.1)) {
            data[k].pop();
        }
    })
    
    throttleFunction(chart, 1000);
}

