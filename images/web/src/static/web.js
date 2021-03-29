// Copyright (c) 2021, Oracle and/or its affiliates. 
// All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

const getPixelRatio = (ctx) => {
    const dpr = window.devicePixelRatio || 1;
    const bsr = ctx.webkitBackingStorePixelRatio ||
                ctx.mozBackingStorePixelRatio ||
                ctx.msBackingStorePixelRatio ||
                ctx.oBackingStorePixelRatio ||
                ctx.backingStorePixelRatio || 1;
    return dpr / bsr;
}

const points = 600;
const refreshInterval = 10; //ms
let data = {};

const margin = {top: 20, right: 20, bottom: 30, left: 50};
const fullWidth = 0.95 * document.body.clientWidth; //960;
const fullHeight = 0.80 * document.body.clientHeight; //500;
const width = fullWidth - margin.left - margin.right;
const height = fullHeight - margin.top - margin.bottom;

const canvas = document.querySelector("canvas");
const context = canvas.getContext("2d", { alpha: false });
// const context = canvas.getContext("2d");
const pixelRatio = getPixelRatio(context);
canvas.height = pixelRatio * fullHeight;
canvas.width = pixelRatio * fullWidth;
canvas.style.width = fullWidth + "px";
canvas.style.height = fullHeight + "px";
context.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);

const x = d3.scaleTime().range([0, width]);
const y = d3.scaleLinear().range([height, 0]);
const colors = d3.scaleOrdinal(d3.schemeCategory20);

const line = d3.line()
        .x(function(d) { return x(new Date(d.date * 1000)) + margin.left; })
        .y(function(d) { return y(d.value) + margin.top; })
        .context(context);

// context.translate(margin.left, margin.top);

function xAxis() {
    const tickCount = 10;
    const tickSize = 6;
    const tickPadding = 3;
    const ticks = x.ticks(tickCount);
    const tickFormat = x.tickFormat();
  
    context.beginPath();
    ticks.forEach(function(d) {
      context.moveTo(x(d) + margin.left, height + margin.top);
      context.lineTo(x(d) + margin.left, height + margin.top + tickSize);
    });
    context.strokeStyle = "black";
    context.stroke();
  
    context.textAlign = "center";
    context.textBaseline = "top";
    ticks.forEach(function(d) {
      context.fillText(tickFormat(d), x(d) + margin.left, height + margin.top + tickSize + tickPadding);
    });
  }
  
  function yAxis() {
    const tickOffset = margin.left;
    const tickCount = 10;
    const tickSize = 6;
    const tickPadding = 3;
    const ticks = y.ticks(tickCount);
    const tickFormat = y.tickFormat(tickCount);
  
    context.beginPath();
    ticks.forEach(function(d) {
      context.moveTo(tickOffset, y(d) + margin.top);
      context.lineTo(tickOffset - 6, y(d) + margin.top);
    });
    context.strokeStyle = "black";
    context.stroke();
  
    context.beginPath();
    context.moveTo(tickOffset - tickSize, margin.top);
    context.lineTo(tickOffset - 0.5, margin.top);
    context.lineTo(tickOffset + 0.5, height + margin.top);
    context.lineTo(tickOffset - tickSize, height + margin.top);
    context.strokeStyle = "black";
    context.stroke();
  
    context.textAlign = "right";
    context.textBaseline = "middle";
    ticks.forEach(function(d) {
      context.fillText(tickFormat(d), tickOffset - tickSize - tickPadding, y(d) + margin.top);
    });
  }
  

const chart = () => {
    // Scale the range of the data
    const hostnames = Object.keys(data);
    const xExtents = hostnames.map(h => d3.extent(data[h], function(d) { return new Date(d.date * 1000); }));
    const yExtents = hostnames.map(h => d3.extent(data[h], function(d) { return d.value; }));
    // show only last minute of data
    const now = new Date();
    const then = new Date(now.getFullYear(),
                            now.getMonth(), 
                            now.getDate(), 
                            now.getHours(), 
                            now.getMinutes() - 1, 
                            now.getSeconds(), 
                            now.getMilliseconds()); 
    x.domain([then, now]);
    y.domain([Math.min(...yExtents.map(e => e[0])), Math.max(...yExtents.map(e => e[1]))]);
    context.fillStyle = "white";
    context.fillRect(0, 0, canvas.width, canvas.height);
    context.fillStyle = "black";

    xAxis();
    yAxis();
    Object.keys(data).map((k) => {
        context.beginPath();
        line(data[k]);
        context.lineWidth = 1.5;
        context.strokeStyle = colors(k);
        context.stroke();
    });

    setTimeout(() => window.requestAnimationFrame(chart), 50);

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
    
    // throttleFunction(chart, refreshInterval);
}

window.requestAnimationFrame(chart);

