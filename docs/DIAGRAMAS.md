# Guía de Diagramas Mermaid - FactuMarket

Este documento explica los diagramas Mermaid utilizados en la documentación del sistema FactuMarket.

## Tipos de Diagramas Utilizados

### 1. Graph (Grafos)

Usados para mostrar arquitectura y relaciones entre componentes.

**Ejemplo - Arquitectura de Microservicios:**
```mermaid
graph TB
    CS[Clientes Service]
    FS[Facturas Service]
    AS[Auditoría Service]

    FS -->|Valida Cliente| CS
    CS -->|Registra Evento| AS
    FS -->|Registra Evento| AS

    style CS fill:#4CAF50,color:#fff
    style FS fill:#2196F3,color:#fff
    style AS fill:#FF9800,color:#fff
```

**Variantes:**
- `graph TB` - Top to Bottom (vertical)
- `graph LR` - Left to Right (horizontal)
- `graph TD` - Top Down (igual que TB)

### 2. Sequence Diagrams (Diagramas de Secuencia)

Usados para mostrar flujos de comunicación entre componentes a lo largo del tiempo.

**Ejemplo - Flujo de Creación de Factura:**
```mermaid
sequenceDiagram
    autonumber
    participant Usuario
    participant Facturas as Facturas Service
    participant Clientes as Clientes Service
    participant DB as Database

    Usuario->>+Facturas: POST /facturas
    Facturas->>+Clientes: GET /clientes/:id
    Clientes-->>-Facturas: Cliente válido
    Facturas->>+DB: INSERT factura
    DB-->>-Facturas: OK
    Facturas-->>-Usuario: 201 Created

    style Facturas fill:#2196F3
    style Clientes fill:#4CAF50
```

**Elementos:**
- `participant` - Define actores/componentes
- `->>` - Llamada síncrona
- `-->>` - Respuesta
- `+` - Activación
- `-` - Desactivación
- `autonumber` - Numeración automática
- `Note` - Notas explicativas
- `alt` - Flujos alternativos
- `par` - Operaciones paralelas

### 3. Subgraphs (Subgrafos)

Usados para agrupar componentes relacionados.

**Ejemplo:**
```mermaid
graph TB
    subgraph "Microservicios"
        CS[Clientes]
        FS[Facturas]
    end

    subgraph "Bases de Datos"
        DB1[(Oracle)]
        DB2[(MongoDB)]
    end

    CS --> DB1
    FS --> DB1
    CS --> DB2
    FS --> DB2
```

## Paleta de Colores Utilizada

### Microservicios
- **Clientes Service**: `#4CAF50` (Verde) - `fill:#4CAF50,color:#fff`
- **Facturas Service**: `#2196F3` (Azul) - `fill:#2196F3,color:#fff`
- **Auditoría Service**: `#FF9800` (Naranja) - `fill:#FF9800,color:#fff`

### Capas de Clean Architecture
- **Presentation Layer**: `#2196F3` (Azul claro) - `fill:#E3F2FD`
- **Application Layer**: `#FF9800` (Naranja claro) - `fill:#FFF3E0`
- **Domain Layer**: `#4CAF50` (Verde claro) - `fill:#E8F5E9`
- **Infrastructure Layer**: `#9C27B0` (Púrpura claro) - `fill:#FCE4EC`

### Bases de Datos
- **SQLite/Oracle**: `#607D8B` (Gris azulado)
- **MongoDB**: `#9C27B0` (Púrpura)

## Convenciones de Nomenclatura

### Formas de Nodos

```mermaid
graph LR
    A[Rectángulo: Componente/Servicio]
    B[(Cilindro: Base de Datos)]
    C((Círculo: Evento))
    D{Diamante: Decisión}
    E[/Paralelo: Entrada-Salida/]
```

### Tipos de Flechas

```mermaid
graph LR
    A -->|Sólida: Dependencia fuerte| B
    A -.->|Punteada: Dependencia débil| C
    A ==>|Gruesa: Flujo principal| D
    A ~~~ E
```

## Ejemplos por Tipo de Documentación

### README Principal

**Arquitectura General del Sistema:**
- Graph TB con subgraphs
- Muestra los 3 microservicios
- Bases de datos diferenciadas
- Comunicación entre servicios

**Sequence Diagram:**
- Flujo completo de una operación
- Incluye todos los servicios involucrados
- Muestra comunicación síncrona y asíncrona

### docs/ARQUITECTURA.md

**Clean Architecture:**
- Graph TD mostrando las 4 capas
- Flujo de dependencias
- Representación de interfaces

**Comunicación entre Servicios:**
- Graph LR simple
- Focus en relaciones HTTP
- Indica si es síncrono o asíncrono

**Flujos Detallados:**
- Sequence Diagrams numerados
- Notas explicativas
- Manejo de errores con `alt`

### READMEs de Microservicios

**Arquitectura Interna:**
- Graph TD con capas específicas del servicio
- Conexiones a servicios externos
- Base de datos específica

**Integración:**
- Graph mostrando conexiones con otros servicios
- Indicadores de timeout y tipo de comunicación

**Flujos de Operación:**
- Sequence Diagrams detallados
- Validaciones y transformaciones
- Manejo de errores

## Tips para Crear Diagramas

### 1. Consistencia en Estilos

Siempre usar los mismos colores para los mismos componentes:

```mermaid
graph TB
    CS[Clientes]
    FS[Facturas]
    AS[Auditoría]

    style CS fill:#4CAF50,color:#fff
    style FS fill:#2196F3,color:#fff
    style AS fill:#FF9800,color:#fff
```

### 2. Claridad en Labels

Usar `<br/>` para dividir texto largo:

```mermaid
graph TB
    A[Clientes Service<br/>Puerto 4001<br/>Clean Architecture]
```

### 3. Notas Explicativas

Agregar contexto con `Note`:

```mermaid
sequenceDiagram
    A->>B: Request
    Note over A,B: Comunicación síncrona<br/>Timeout: 5s
    B-->>A: Response
```

### 4. Flujos Alternativos

Usar `alt` para mostrar errores:

```mermaid
sequenceDiagram
    A->>B: Request

    alt Success
        B-->>A: 200 OK
    else Error
        B-->>A: 500 Error
        Note right of A: Reintenta
    end
```

### 5. Operaciones Paralelas

Usar `par` para mostrar concurrencia:

```mermaid
sequenceDiagram
    par Servicio 1
        A->>B: Request 1
    and Servicio 2
        A->>C: Request 2
    end
```

## Renderizado

Los diagramas Mermaid se renderizan automáticamente en:
- GitHub
- GitLab
- Visual Studio Code (con extensión)
- Muchos editores Markdown

Para verlos localmente:
1. Instalar extensión Mermaid para tu editor
2. O usar un previsualizador online: https://mermaid.live/

## Referencias

- [Documentación oficial de Mermaid](https://mermaid.js.org/)
- [Mermaid Live Editor](https://mermaid.live/)
- [Mermaid GitHub](https://github.com/mermaid-js/mermaid)

## Ventajas de Usar Mermaid

✅ **Versionable**: Los diagramas son texto, se pueden versionar con Git
✅ **Fácil de editar**: No necesitas herramientas gráficas
✅ **Renderizado automático**: GitHub y GitLab los muestran directamente
✅ **Consistente**: Mismo estilo en todos los diagramas
✅ **Mantenible**: Cambios rápidos sin editar imágenes
✅ **Portable**: Funciona en cualquier plataforma
