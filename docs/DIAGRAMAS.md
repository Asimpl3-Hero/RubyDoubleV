# Guía de Diagramas Mermaid - FactuMarket

Los 3 tipos de diagramas esenciales usados en el proyecto.

---

## 1. Graph - Arquitectura del Sistema

**Uso**: Mostrar componentes y sus relaciones.

**Ejemplo:**
```mermaid
graph TB
    CS[Clientes Service<br/>:4001]
    FS[Facturas Service<br/>:4002]
    AS[Auditoría Service<br/>:4003]

    SQL[(SQLite/Oracle)]
    MONGO[(MongoDB)]

    FS -->|Valida| CS
    CS -->|Registra| AS
    FS -->|Registra| AS
    CS --> SQL
    FS --> SQL
    AS --> MONGO

    style CS fill:#51cf66,stroke:#2f9e44,color:#fff
    style FS fill:#4dabf7,stroke:#1971c2,color:#fff
    style AS fill:#ffd43b,stroke:#f59f00,color:#000
```

**Variantes:**
- `graph TB` - Vertical
- `graph LR` - Horizontal

---

## 2. Sequence Diagram - Flujos de Comunicación

**Uso**: Mostrar orden de operaciones entre servicios.

**Ejemplo:**
```mermaid
sequenceDiagram
    participant Client
    participant Facturas
    participant Clientes
    participant Auditoría

    Client->>Facturas: POST /facturas
    Facturas->>Clientes: GET /clientes/:id
    Clientes-->>Facturas: Cliente válido
    Facturas->>Auditoría: POST /auditoria
    Auditoría-->>Facturas: OK
    Facturas-->>Client: 201 Created
```

**Elementos:**
- `->>` Request
- `-->>` Response
- `Note right of X: Texto` Anotaciones

---

## 3. Flowchart - Lógica y Decisiones

**Uso**: Mostrar validaciones y flujos de decisión.

**Ejemplo:**
```mermaid
flowchart TD
    Start([Request]) --> Validate{Datos válidos?}
    Validate -->|No| Error[422 Error]
    Validate -->|Sí| Process[Procesar]
    Process --> Success[201 Created]

    style Success fill:#51cf66,stroke:#2f9e44,color:#fff
    style Error fill:#ff6b6b,stroke:#c92a2a,color:#fff
```

**Formas:**
- `([])` Inicio/Fin
- `[]` Proceso
- `{}` Decisión

---

## Paleta de Colores

```
Verde (Success):   fill:#51cf66,stroke:#2f9e44,color:#fff
Azul (Info):       fill:#4dabf7,stroke:#1971c2,color:#fff
Amarillo (Warning): fill:#ffd43b,stroke:#f59f00,color:#000
Rojo (Error):      fill:#ff6b6b,stroke:#c92a2a,color:#fff
```

---

## Dónde Ver los Diagramas

- **GitHub**: Auto-renderizado
- **VS Code**: Extensión "Markdown Preview Mermaid Support"
- **Online**: https://mermaid.live/

---

**Documentación oficial**: https://mermaid.js.org/
