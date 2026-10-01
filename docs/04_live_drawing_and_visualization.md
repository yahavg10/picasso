# 04 - Excalidraw & Draw.io Diagram Synthesis Engine

## 1. Overview

Rather than requiring a custom web frontend, Picasso directly synthesizes native **`.excalidraw`** and **`.drawio`** diagram files. This enables immediate visualization, editing, and sharing in standard design and developer tools.

---

## 2. Excalidraw Generation Engine (`.excalidraw`)

Excalidraw files are structured JSON documents adhering to the Excalidraw schema (version 2). The Python generator constructs an array of visual elements (`elements`), binding text labels and arrow connectors together.

### Element Architecture
```
┌────────────────────────────────────────────────────────┐
│ Excalidraw File Structure                              │
│                                                        │
│  {                                                     │
│    "type": "excalidraw",                               │
│    "version": 2,                                       │
│    "source": "picasso-scanner",                        │
│    "elements": [                                       │
│      /* Account Boundary Rectangle */                  │
│      /* VPC Container Rectangle (dashed) */            │
│      /* Subnet Rectangles (solid / tinted) */          │
│      /* Workload Nodes (EC2, RDS, Lambda) */           │
│      /* Risk Callout Badges (Red / Orange) */          │
│      /* Attack Path Arrows (Animated / Red) */         │
│    ],                                                  │
│    "appState": { "viewBackgroundColor": "#1e1e1e" }    │
│  }                                                     │
└────────────────────────────────────────────────────────┘
```

### Visual Styling in Excalidraw
- **VPC Containers**: Large rectangular boundaries with `roughness: 1`, `strokeColor: "#4a5568"`, `fillStyle: "solid"`, `backgroundColor: "transparent"`.
- **Public Subnets**: Light-tinted yellow/red background (`#fff5f5` or dark-mode equivalent `#2d1515`).
- **Private Subnets**: Calm blue/green tint (`#f0fff4` or dark-mode `#14291e`).
- **Critical Risk Nodes**:
  - `strokeColor`: `"#e53e3e"` (Red)
  - `strokeWidth`: `2`
  - Floating threat badge text element: `"[!] 0.0.0.0/0:22 Open to Internet"`
- **Attack Paths**:
  - `type`: `"arrow"`
  - `strokeColor`: `"#e53e3e"`
  - `strokeStyle`: `"dashed"`
  - `strokeWidth`: `3`

---

## 3. Draw.io Generation Engine (`.drawio`)

Draw.io (diagrams.net) files are XML documents utilizing the **mxGraph** model. Draw.io natively supports **collapsible parent-child container groups**, making it ideal for deeply nested cloud architectures.

### XML mxGraph Hierarchy
```xml
<mxfile host="Picasso" modified="2026-10-02T00:00:00Z" agent="Picasso-Engine">
  <diagram id="aws-topology" name="AWS Security Topology">
    <mxGraphModel dx="1422" dy="794" grid="1" gridSize="10" guides="1">
      <root>
        <!-- Canvas Root Cells -->
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>

        <!-- VPC Container (Collapsible Group) -->
        <mxCell id="vpc-01" value="VPC: Production (10.0.0.0/16)" 
                style="swimlane;whiteSpace=wrap;html=1;startSize=26;fillColor=#f8fafc;strokeColor=#64748b;rounded=1;" 
                vertex="1" parent="1">
          <mxGeometry x="80" y="80" width="700" height="480" as="geometry"/>
        </mxCell>

        <!-- Public Subnet Container inside VPC -->
        <mxCell id="sub-01" value="Public Subnet (10.0.1.0/24) [us-east-1a]" 
                style="swimlane;whiteSpace=wrap;html=1;startSize=24;fillColor=#fef2f2;strokeColor=#ef4444;rounded=1;" 
                vertex="1" parent="vpc-01">
          <mxGeometry x="30" y="50" width="300" height="380" as="geometry"/>
        </mxCell>

        <!-- Workload inside Subnet -->
        <mxCell id="ec2-01" value="&lt;b&gt;Web-Server-01&lt;/b&gt;&lt;br&gt;i-0a1b2c3d4e&lt;br&gt;&lt;font color='#ef4444'&gt;⚠ Ingress 0.0.0.0/0:22&lt;/font&gt;" 
                style="rounded=1;whiteSpace=wrap;html=1;fillColor=#fee2e2;strokeColor=#dc2626;strokeWidth=2;" 
                vertex="1" parent="sub-01">
          <mxGeometry x="30" y="60" width="240" height="90" as="geometry"/>
        </mxCell>

        <!-- Attack Path Connector -->
        <mxCell id="edge-01" value="Exploitable Ingress" 
                style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#ef4444;strokeWidth=3;dashed=1;" 
                edge="1" parent="1" source="igw-01" target="ec2-01">
          <mxGeometry relative="1" as="geometry"/>
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

---

## 4. Automated Grid & Layout Engine (Python)

To ensure generated diagrams look organized without overlapping shapes, Picasso implements a **hierarchical bounding box layout engine**:

1. **Subnet Sizing**: Computes required width and height based on the number of compute and datastore nodes inside the subnet.
2. **VPC Sizing**: Aligns subnets side-by-side or in multi-tier rows (Public tier on top, Private App in middle, Database tier on bottom) with standard 30px padding.
3. **Region / Account Sizing**: Surrounds VPCs with regional boundary frames.
4. **Router & Gateway Alignment**: Positions Internet Gateways, NAT Gateways, and Transit Gateways at perimeter entry/exit coordinates.

---

## 5. How to View and Edit Generated Files

| File Extension | Native Mac / VS Code Viewer | Web Viewer |
| :--- | :--- | :--- |
| **`.excalidraw`** | **VS Code Excalidraw Extension** (by pomdtr) | **[excalidraw.com](https://excalidraw.com)** (drag & drop) |
| **`.drawio`** | **Draw.io Integration Extension** (by Henning Dieterichs) | **[app.diagrams.net](https://app.diagrams.net)** |

Both files are saved directly to the project output directory (e.g. `./output/aws_topology.excalidraw` and `./output/aws_topology.drawio`) and can be committed directly to Git.
