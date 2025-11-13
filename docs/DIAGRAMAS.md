# Guía de Diagramas Mermaid - FactuMarket

Esta guía explica los diagramas Mermaid utilizados en el proyecto FactuMarket.

## Por Qué Usamos Mermaid

✅ **Versionable** - Los diagramas son código, se versionan con Git
✅ **Auto-renderizado** - GitHub/GitLab los muestran automáticamente
✅ **Fácil de editar** - Solo texto, no necesitas herramientas gráficas
✅ **Consistente** - Mismo estilo en toda la documentación

---

## Tipos de Diagramas Usados en el Proyecto

### 1. Graph (Arquitectura y Flujos)

**Uso**: Mostrar arquitectura de microservicios, capas de Clean Architecture, y relaciones entre componentes.

**Ejemplo del proyecto:**
```mermaid
graph TB
    subgraph "Microservicios"
        CS[Clientes Service<br/>:4001]
        FS[Facturas Service<br/>:4002]
        AS[Auditoría Service<br/>:4003]
    end

    subgraph "Bases de Datos"
        SQL[(SQLite/Oracle)]
        MONGO[(MongoDB)]
    end

    FS -->|Valida Cliente| CS
    CS -->|Registra Evento| AS
    FS -->|Registra Evento| AS
    CS --> SQL
    FS --> SQL
    AS --> MONGO

    style CS fill:#51cf66,stroke:#2f9e44,color:#fff
    style FS fill:#4dabf7,stroke:#1971c2,color:#fff
    style AS fill:#ffd43b,stroke:#f59f00,color:#000
```

**Variantes:**
- `graph TB` - Top to Bottom (vertical)
- `graph LR` - Left to Right (horizontal)

---

### 2. Sequence Diagram (Flujos de Comunicación)

**Uso**: Mostrar flujos entre microservicios, requests HTTP, y orden de operaciones.

**Ejemplo del proyecto:**
```mermaid
sequenceDiagram
    participant Client as Cliente
    participant FS as Facturas Service
    participant CS as Clientes Service
    participant AS as Auditoría Service

    Client->>FS: POST /facturas
    FS->>CS: GET /clientes/:id
    CS-->>FS: Cliente válido
    FS->>FS: Crear factura
    FS->>AS: POST /auditoria
    AS-->>FS: Evento registrado
    FS-->>Client: 201 Created
```

**Elementos clave:**
- `participant` - Define actores
- `->>` - Request síncrono
- `-->>` - Response
- `Note right of` - Anotaciones

---

### 3. Flowchart (Decisiones y Procesos)

**Uso**: Mostrar lógica de negocio, validaciones, y flujos de decisión.

**Ejemplo del proyecto:**
```mermaid
flowchart TD
    Start([Crear Factura]) --> ValidateData{Datos válidos?}

    ValidateData -->|No| Error1[422 Error]
    ValidateData -->|Sí| CheckClient[Validar Cliente]

    CheckClient -->|No existe| Error2[404 Error]
    CheckClient -->|Existe| SaveDB[Guardar en DB]

    SaveDB --> Audit[Registrar Auditoría]
    Audit --> Success[201 Created]

    Error1 --> End([Fin])
    Error2 --> End
    Success --> End

    style Start fill:#51cf66,stroke:#2f9e44,color:#fff
    style Success fill:#51cf66,stroke:#2f9e44,color:#fff
    style Error1 fill:#ff6b6b,stroke:#c92a2a,color:#fff
    style Error2 fill:#ff6b6b,stroke:#c92a2a,color:#fff
```

---

### 4. Mindmap (Organización de Conceptos)

**Uso**: Mostrar cobertura de tests, features del sistema, o estructura de módulos.

**Ejemplo del proyecto:**
```mermaid
mindmap
  root((FactuMarket))
    Microservicios
      Clientes
        CRUD
        Validaciones
      Facturas
        Crear
        Consultar
        Validar Cliente
      Auditoría
        Eventos
        Consultas
    Arquitectura
      Clean Architecture
      MVC
      REST APIs
    Testing
      Unit Tests
      Integration Tests
      WebMock
```

---

### 5. Pie Chart (Métricas)

**Uso**: Mostrar distribución de tests, cobertura de código, o porcentajes.

**Ejemplo del proyecto:**
```mermaid
pie title Test Coverage
    "Domain Layer" : 95
    "Integration Tests" : 100
    "Controllers" : 85
    "Not Covered" : 5
```

---

## Paleta de Colores del Proyecto

### Microservicios
```
Clientes:   fill:#51cf66,stroke:#2f9e44,color:#fff  (Verde)
Facturas:   fill:#4dabf7,stroke:#1971c2,color:#fff  (Azul)
Auditoría:  fill:#ffd43b,stroke:#f59f00,color:#000  (Amarillo)
```

### Estados
```
Success:  fill:#51cf66,stroke:#2f9e44,color:#fff  (Verde)
Error:    fill:#ff6b6b,stroke:#c92a2a,color:#fff  (Rojo)
Warning:  fill:#ffd43b,stroke:#f59f00,color:#000  (Amarillo)
Info:     fill:#4dabf7,stroke:#1971c2,color:#fff  (Azul)
Neutral:  fill:#ddd,stroke:#999,color:#666        (Gris)
```

### Bases de Datos
```
SQL:      fill:#ffd43b,stroke:#f59f00,color:#000  (Amarillo)
MongoDB:  fill:#ff6b6b,stroke:#c92a2a,color:#fff  (Rojo claro)
```

---

## Formas de Nodos

```mermaid
graph LR
    A[Rectángulo: Servicio/Componente]
    B[(Cilindro: Base de Datos)]
    C{Diamante: Decisión}
    D([Rectángulo Redondeado: Inicio/Fin])
```

---

## Convenciones del Proyecto

### 1. Siempre Usa Colores Consistentes

```mermaid
graph LR
    CS[Clientes]
    FS[Facturas]

    style CS fill:#51cf66,stroke:#2f9e44,color:#fff
    style FS fill:#4dabf7,stroke:#1971c2,color:#fff
```

### 2. Usa Labels Claros

```mermaid
graph TB
    A[Servicio de Clientes<br/>Puerto 4001<br/>SQLite]
```

### 3. Separa con Subgraphs

```mermaid
graph TB
    subgraph "Frontend"
        UI[Swagger UI]
    end

    subgraph "Backend"
        API[REST API]
    end

    UI --> API
```

---

## Dónde Se Usan en el Proyecto

| Archivo | Diagramas | Propósito |
|---------|-----------|-----------|
| `README.md` | Graph, Sequence | Arquitectura general |
| `docs/ARQUITECTURA.md` | Graph, Sequence, Flowchart | Clean Architecture detallada |
| `docs/TESTING.md` | Graph, Sequence, Flowchart, Mindmap, Pie | Estrategia y cobertura de tests |

---

## Cómo Ver los Diagramas

### En GitHub
Los diagramas se renderizan automáticamente en archivos `.md`

### En VS Code
Instala la extensión **Markdown Preview Mermaid Support**

### Online
https://mermaid.live/ - Editor y previsualizador

---

## Plantillas Rápidas

### Arquitectura de Microservicio

```mermaid
graph TB
    subgraph "Service Name"
        CTRL[Controller]
        UC[Use Cases]
        ENT[Entities]
        REPO[Repository]
    end

    CTRL --> UC
    UC --> ENT
    UC --> REPO
    REPO --> DB[(Database)]

    style CTRL fill:#4dabf7,stroke:#1971c2,color:#fff
    style UC fill:#ffd43b,stroke:#f59f00,color:#000
    style ENT fill:#51cf66,stroke:#2f9e44,color:#fff
```

### Flujo de Request

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Service
    participant DB as Database

    C->>S: POST /resource
    S->>DB: INSERT
    DB-->>S: OK
    S-->>C: 201 Created
```

### Validación con Errores

```mermaid
flowchart TD
    Start([Request]) --> Validate{Valid?}
    Validate -->|Yes| Process[Process]
    Validate -->|No| Error[Error Response]
    Process --> Success[Success Response]

    style Success fill:#51cf66,stroke:#2f9e44,color:#fff
    style Error fill:#ff6b6b,stroke:#c92a2a,color:#fff
```

---

## Tips

1. **Mantén los diagramas simples** - Máximo 10-12 nodos
2. **Usa colores con propósito** - No solo decoración
3. **Incluye leyendas** - Si usas símbolos especiales
4. **Actualízalos** - Cuando cambie la arquitectura

---

## Referencias

- [Mermaid Docs](https://mermaid.js.org/)
- [Mermaid Live Editor](https://mermaid.live/)
- [GitHub Mermaid Support](https://github.blog/2022-02-14-include-diagrams-markdown-files-mermaid/)

---

**Última actualización:** Enero 2025
