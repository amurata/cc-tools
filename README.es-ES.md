

# Claude Code Plugins: Orquestación y Automatización

> **⚡ Actualizado para Sonnet 4.5 y Haiku 4.5** — Todos los agentes optimizados para los últimos modelos con orquestación híbrida
>
> **🎯 Habilidades de Agente Activadas** — 47 habilidades especializadas extienden las capacidades de Claude en todos los plugins con revelación progresiva

Un sistema integral listo para producción que combina **85 agentes de IA especializados**, **15 orquestadores de flujos de trabajo multiagente**, **47 habilidades de agente** y **44 herramientas de desarrollo** organizadas en **63 plugins enfocados y de propósito único** para [Claude Code](https://docs.claude.com/en/docs/claude-code/overview).

## Descripción general

Este repositorio unificado proporciona todo lo necesario para la automatización inteligente y la orquestación multiagente en el desarrollo de software moderno:

- **63 Plugins Enfocados** — Plugins granulares y de propósito único optimizados para un uso mínimo de tokens y composabilidad
- **85 Agentes Especializados** — Expertos en dominios con conocimiento profundo en arquitectura, lenguajes, infraestructura, calidad, datos/IA, documentación, operaciones comerciales y SEO
- **47 Habilidades de Agente** — Paquetes de conocimiento modulares con revelación progresiva para expertise especializado
- **15 Orquestadores de Flujos de Trabajo** — Sistemas de coordinación multiagente para operaciones complejas como desarrollo full-stack, fortalecimiento de seguridad, pipelines de ML y respuesta a incidentes
- **44 Herramientas de Desarrollo** — Utilidades optimizadas que incluyen andamiaje de proyectos, escaneo de seguridad, automatización de pruebas y configuración de infraestructura

### Características principales

- **Arquitectura de Plugins Granular**: 63 plugins enfocados optimizados para un uso mínimo de tokens
- **Herramientas Integrales**: 44 herramientas de desarrollo que incluyen generación de pruebas, andamiaje y escaneo de seguridad
- **Cobertura del 100% de Agentes**: Todos los plugins incluyen agentes especializados
- **Habilidades de Agente**: 47 habilidades especializadas que siguen la revelación progresiva y la eficiencia de tokens
- **Organización Clara**: 23 categorías con 1-6 plugins cada una para una fácil búsqueda
- **Diseño Eficiente**: Promedio de 3.4 componentes por plugin (sigue el patrón 2-8 de Anthropic)

### Cómo funciona

Cada plugin está completamente aislado con sus propios agentes, comandos y habilidades:

- **Instala solo lo que necesites** — Cada plugin carga solo sus agentes, comandos y habilidades específicos
- **Uso mínimo de tokens** — No se cargan recursos innecesarios en el contexto
- **Combina y adapta** — Compón múltiples plugins para flujos de trabajo complejos
- **Límites claros** — Cada plugin tiene un único propósito enfocado
- **Revelación progresiva** — Las habilidades cargan conocimiento solo cuando se activan

**Ejemplo**: Instalar `python-development` carga 3 agentes de Python, 1 herramienta de andamiaje y hace disponibles 5 habilidades (~300 tokens), no todo el marketplace.

## Inicio rápido

### Paso 1: Agregar el Marketplace

Agrega este marketplace a Claude Code:

```bash
/plugin marketplace add wshobson/agents
```

Esto hace que los 63 plugins estén disponibles para su instalación, pero **no carga ningún agente o herramienta** en tu contexto.

### Paso 2: Instalar Plugins

Explora los plugins disponibles:

```bash
/plugin
```

Instala los plugins que necesites:

```bash
# Essential development plugins
/plugin install python-development          # Python with 5 specialized skills
/plugin install javascript-typescript       # JS/TS with 4 specialized skills
/plugin install backend-development         # Backend APIs with 3 architecture skills

# Infrastructure & operations
/plugin install kubernetes-operations       # K8s with 4 deployment skills
/plugin install cloud-infrastructure        # AWS/Azure/GCP with 4 cloud skills

# Security & quality
/plugin install security-scanning           # SAST with security skill
/plugin install code-review-ai             # AI-powered code review

# Full-stack orchestration
/plugin install full-stack-orchestration   # Multi-agent workflows
```

Cada plugin instalado carga **solo sus agentes, comandos y habilidades específicos** en el contexto de Claude.

## Documentación

### Guías principales

- **[Referencia de Plugins](docs/plugins.md)** — Catálogo completo de los 63 plugins
- **[Referencia de Agentes](docs/agents.md)** — Los 85 agentes organizados por categoría
- **[Habilidades de Agente](docs/agent-skills.md)** — 47 habilidades especializadas con revelación progresiva
- **[Guía de Uso](docs/usage.md)** — Comandos, flujos de trabajo y mejores prácticas
- **[Arquitectura](docs/architecture.md)** — Principios y patrones de diseño

### Enlaces rápidos

- [Instalación](#quick-start) — Comienza en 2 pasos
- [Plugins Esenciales](docs/plugins.md#quick-start---essential-plugins) — Mejores plugins para productividad inmediata
- [Referencia de Comandos](docs/usage.md#command-reference-by-category) — Todos los comandos slash organizados por categoría
- [Flujos de Trabajo Multiagente](docs/usage.md#multi-agent-workflow-examples) — Ejemplos de orquestación preconfigurados
- [Configuración de Modelos](docs/agents.md#model-configuration) — Orquestación híbrida Haiku/Sonnet

## Novedades

### Habilidades de Agente (47 habilidades en 14 plugins)

Paquetes de conocimiento especializado que siguen la arquitectura de revelación progresiva de Anthropic:

**Desarrollo de Lenguajes:**
- **Python** (5 habilidades): patrones asíncronos, pruebas, empaquetado, rendimiento, administrador de paquetes UV
- **JavaScript/TypeScript** (4 habilidades): tipos avanzados, patrones de Node.js, pruebas, ES6+ moderno

**Infraestructura y DevOps:**
- **Kubernetes** (4 habilidades): manifiestos, gráficos de Helm, GitOps, políticas de seguridad
- **Infraestructura en la Nube** (4 habilidades): Terraform, multicloud, redes híbridas, optimización de costos
- **CI/CD** (4 habilidades): diseño de pipelines, GitHub Actions, GitLab CI, gestión de secretos

**Desarrollo y Arquitectura:**
- **Backend** (3 habilidades): diseño de API, patrones de arquitectura, microservicios
- **Aplicaciones de LLM** (4 habilidades): LangChain, ingeniería de prompts, RAG, evaluación

**Blockchain y Web3** (4 habilidades): protocolos DeFi, estándares NFT, seguridad Solidity, pruebas Web3

**Y más:** migración de frameworks, observabilidad, procesamiento de pagos, operaciones de ML, escaneo de seguridad

[→ Ver documentación completa de habilidades](docs/agent-skills.md)

### Orquestación de Modelos Híbrida

Asignación estratégica de modelos para un rendimiento y costo óptimos:
- **47 agentes Haiku** — Ejecución rápida para tareas deterministas
- **97 agentes Sonnet** — Razonamiento complejo y arquitectura

Los patrones de orquestación combinan modelos para mayor eficiencia:
```
Sonnet (planning) → Haiku (execution) → Sonnet (review)
```

[→ Ver detalles de configuración de modelos](docs/agents.md#model-configuration)

## Casos de uso populares

### Desarrollo de Funcionalidades Full-Stack

```bash
/full-stack-orchestration:full-stack-feature "user authentication with OAuth2"
```

Coordina más de 7 agentes: backend-architect → database-architect → frontend-developer → test-automator → security-auditor → deployment-engineer → observability-engineer

[→ Ver todos los ejemplos de flujos de trabajo](docs/usage.md#multi-agent-workflow-examples)

### Fortalecimiento de Seguridad

```bash
/security-scanning:security-hardening --level comprehensive
```

Evaluación de seguridad multiagente con SAST, escaneo de dependencias y revisión de código.

### Desarrollo en Python con Herramientas Modernas

```bash
/python-development:python-scaffold fastapi-microservice
```

Crea un proyecto FastAPI listo para producción con patrones asíncronos, activando las habilidades:
- `async-python-patterns` — AsyncIO y concurrencia
- `python-testing-patterns` — pytest y fixtures
- `uv-package-manager` — Gestión rápida de dependencias

### Implementación en Kubernetes

```bash
# Activates k8s skills automatically
"Create production Kubernetes deployment with Helm chart and GitOps"
```

Utiliza el agente kubernetes-architect con 4 habilidades especializadas para configuraciones de grado producción.

[→ Ver guía de uso completa](docs/usage.md)

## Categorías de Plugins

**23 categorías, 63 plugins:**

- 🎨 **Desarrollo** (4) - depuración, backend, frontend, multiplataforma
- 📚 **Documentación** (2) - documentación de código, especificaciones de API, diagramas
- 🔄 **Flujos de Trabajo** (3) - git, full-stack, TDD
- ✅ **Pruebas** (2) - pruebas unitarias, flujos de trabajo TDD
- 🔍 **Calidad** (3) - revisión de código, revisión integral, rendimiento
- 🤖 **IA y ML** (4) - aplicaciones LLM, orquestación de agentes, contexto, MLOps
- 📊 **Datos** (2) - ingeniería de datos, validación de datos
- 🗄️ **Base de Datos** (2) - diseño de base de datos, migraciones
- 🚨 **Operaciones** (4) - respuesta a incidentes, diagnóstico, depuración distribuida, observabilidad
- ⚡ **Rendimiento** (2) - rendimiento de aplicaciones, optimización de base de datos/nube
- ☁️ **Infraestructura** (5) - implementación, validación, Kubernetes, nube, CI/CD
- 🔒 **Seguridad** (4) - escaneo, cumplimiento, backend/API, frontend/móvil
- 💻 **Lenguajes** (7) - Python, JS/TS, sistemas, JVM, scripting, funcional, embebido
- 🔗 **Blockchain** (1) - contratos inteligentes, DeFi, Web3
- 💰 **Finanzas** (1) - trading cuantitativo, gestión de riesgos
- 💳 **Pagos** (1) - Stripe, PayPal, facturación
- 🎮 **Gaming** (1) - Unity, plugins de Minecraft
- 📢 **Marketing** (4) - contenido SEO, SEO técnico, análisis SEO, marketing de contenidos
- 💼 **Negocios** (3) - análisis, RRHH/legal, clientes/ventas
- Y más...

[→ Ver catálogo completo de plugins](docs/plugins.md)

## Aspectos Destacados de la Arquitectura

### Diseño Granular

- **Responsabilidad única** — Cada plugin hace una cosa bien
- **Uso mínimo de tokens** — Promedio de 3.4 componentes por plugin
- **Componible** — Combina y adapta para flujos de trabajo complejos
- **Cobertura del 100%** — Los 85 agentes son accesibles a través de los plugins

### Revelación Progresiva (Habilidades)

Arquitectura de tres niveles para la eficiencia de tokens:
1. **Metadatos** — Nombre y criterios de activación (siempre cargados)
2. **Instrucciones** — Orientación principal (cargadas al activarse)
3. **Recursos** — Ejemplos y plantillas (cargados bajo demanda)

### Estructura del Repositorio

```
claude-agents/
├── .claude-plugin/
│   └── marketplace.json          # 63 plugins
├── plugins/
│   ├── python-development/
│   │   ├── agents/               # 3 Python experts
│   │   ├── commands/             # Scaffolding tool
│   │   └── skills/               # 5 specialized skills
│   ├── kubernetes-operations/
│   │   ├── agents/               # K8s architect
│   │   ├── commands/             # Deployment tools
│   │   └── skills/               # 4 K8s skills
│   └── ... (61 more plugins)
├── docs/                          # Comprehensive documentation
└── README.md                      # This file
```

[→ Ver detalles de la arquitectura](docs/architecture.md)

## Contribuir

Para agregar nuevos agentes, habilidades o comandos:

1. Identifica o crea el directorio de plugin apropiado en `plugins/`
2. Crea archivos `.md` en el subdirectorio correspondiente:
   - `agents/` — Para agentes especializados
   - `commands/` — Para herramientas y flujos de trabajo
   - `skills/` — Para paquetes de conocimiento modulares
3. Sigue las convenciones de nomenclatura (minúsculas, separadas por guiones)
4. Escribe criterios de activación claros y contenido integral
5. Actualiza la definición del plugin en `.claude-plugin/marketplace.json`

Consulta la [Documentación de Arquitectura](docs/architecture.md) para pautas detalladas.

## Recursos

### Documentación
- [Documentación de Claude Code](https://docs.claude.com/en/docs/claude-code/overview)
- [Guía de Plugins](https://docs.claude.com/en/docs/claude-code/plugins)
- [Guía de Subagentes](https://docs.claude.com/en/docs/claude-code/sub-agents)
- [Guía de Habilidades de Agente](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview)
- [Referencia de Comandos Slash](https://docs.claude.com/en/docs/claude-code/slash-commands)

### Este Repositorio
- [Referencia de Plugins](docs/plugins.md)
- [Referencia de Agentes](docs/agents.md)
- [Guía de Habilidades de Agente](docs/agent-skills.md)
- [Guía de Uso](docs/usage.md)
- [Arquitectura](docs/architecture.md)

## Licencia

Licencia MIT - consulta el archivo [LICENSE](LICENSE) para más detalles.

## Historial de Estrellas

[![Star History Chart](https://api.star-history.com/svg?repos=wshobson/agents&type=date&legend=top-left)](https://www.star-history.com/#wshobson/agents&type=date&legend=top-left)
