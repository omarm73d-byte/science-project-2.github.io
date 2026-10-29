<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Electric Circuits, Switches & Real-Life Lab</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #0b0f19;
            color: #f3f4f6;
            text-align: center;
            margin: 0;
            padding: 20px;
        }
        h1 { color: #38bdf8; margin-bottom: 5px; }
        p.subtitle { color: #9ca3af; margin-top: 0; margin-bottom: 25px; }
        .container {
            display: flex;
            flex-wrap: wrap;
            justify-content: center;
            gap: 20px;
            max-width: 1100px;
            margin: 0 auto;
        }
        .circuit-card {
            background-color: #1e293b;
            border: 1px solid #334155;
            border-radius: 12px;
            padding: 15px;
            width: 320px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
            text-align: left;
        }
        h3 { color: #38bdf8; margin-top: 0; font-size: 15px; text-align: center; }
        canvas {
            background-color: #0f172a;
            border-radius: 8px;
            border: 1px solid #475569;
            margin-bottom: 10px;
            display: block;
            margin-left: auto;
            margin-right: auto;
        }
        .meter-display {
            background-color: #090d16;
            border: 1px solid #22c55e;
            color: #22c55e;
            font-family: monospace;
            padding: 8px;
            border-radius: 6px;
            font-size: 12px;
            margin-bottom: 8px;
            min-height: 70px;
        }
        .real-life {
            font-size: 11px;
            color: #fbbf24;
            background: #292524;
            padding: 6px;
            border-radius: 4px;
            margin-bottom: 10px;
        }
        .btn-group {
            display: flex;
            gap: 5px;
            margin-bottom: 5px;
        }
        .btn {
            background-color: #3b82f6;
            color: white;
            border: none;
            padding: 7px 10px;
            font-size: 12px;
            font-weight: bold;
            border-radius: 6px;
            cursor: pointer;
            flex: 1;
            transition: background 0.2s;
        }
        .btn:hover { background-color: #2563eb; }
        .btn-switch {
            background-color: #ef4444;
        }
        .btn-switch.closed {
            background-color: #22c55e;
        }
    </style>
</head>
<body>

    <h1>⚡ Electric Circuits, Switches & Real-Life Lab</h1>
    <p class="subtitle">Explore series vs. parallel setups, toggle switches, add cells, and watch open vs. closed electron behavior!</p>

    <div class="container" id="circuit-container"></div>

    <script>
        const circuits = [
            { 
                id: 1, 
                name: "1. Series Circuit (Christmas Lights)", 
                type: "Series", 
                cells: 2, 
                cellVoltage: 6, 
                resistance: 4, 
                switchClosed: true,
                realLife: "💡 **Real-Life Example:** Old Christmas tree lights. If one bulb breaks (Open Circuit), the path is interrupted and all lights turn off!"
            },
            { 
                id: 2, 
                name: "2. Parallel Circuit (House Outlets)", 
                type: "Parallel", 
                cells: 2, 
                cellVoltage: 12, 
                resistance: 4, 
                switchClosed: true,
                realLife: "💡 **Real-Life Example:** House wall sockets. Each appliance has its own path, so turning off one device doesn't affect the others."
            },
            { 
                id: 3, 
                name: "3. Open vs Closed Flow Lab", 
                type: "Standard", 
                cells: 1, 
                cellVoltage: 15, 
                resistance: 5, 
                switchClosed: false,
                realLife: "🔋 **Concept:** Toggle the switch to see how electrons flow continuously in a closed loop, but freeze instantly when the circuit opens."
            }
        ];

        let circuitStats = {};
        let electrons = {};

        const container = document.getElementById("circuit-container");

        circuits.forEach(circ => {
            circuitStats[circ.id] = { time: 0, charge: 0 };
            
            electrons[circ.id] = [];
            for(let i=0; i<5; i++) {
                electrons[circ.id].push({ pos: i * 55 });
            }

            const card = document.createElement("div");
            card.className = "circuit-card";
            card.innerHTML = `
                <h3>${circ.name}</h3>
                <canvas id="canvas-${circ.id}" width="280" height="90"></canvas>
                <div class="real-life">${circ.realLife}</div>
                <div class="meter-display" id="meter-${circ.id}">Loading...</div>
                <div class="btn-group">
                    <button class="btn" onclick="addCell(${circ.id})">🔋 Add Cell</button>
                    <button class="btn btn-switch ${circ.switchClosed ? 'closed' : ''}" id="btn-switch-${circ.id}" onclick="toggleSwitch(${circ.id})">Switch: ${circ.switchClosed ? 'CLOSED' : 'OPEN'}</button>
                </div>
            `;
            container.appendChild(card);
        });

        function addCell(id) {
            const circ = circuits.find(c => c.id === id);
            circ.cells += 1;
            if (circ.cells > 4) circ.cells = 1;
        }

        function toggleSwitch(id) {
            const circ = circuits.find(c => c.id === id);
            circ.switchClosed = !circ.switchClosed;
            
            const btn = document.getElementById(`btn-switch-${id}`);
            if (circ.switchClosed) {
                btn.className = "btn btn-switch closed";
                btn.innerText = "Switch: CLOSED";
            } else {
                btn.className = "btn btn-switch";
                btn.innerText = "Switch: OPEN";
            }
        }

        let lastTime = performance.now();

        function updateSimulation(currentTime) {
            const dt = (currentTime - lastTime) / 1000;
            lastTime = currentTime;

            circuits.forEach(circ => {
                const stats = circuitStats[circ.id];
                
                let totalVoltage = 0;
                if (circ.type === "Parallel") {
                    totalVoltage
