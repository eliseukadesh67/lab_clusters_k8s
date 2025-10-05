## Inicializando o Web Client

#### Instale as Dependências

Execute o comando abaixo para instalar todas as dependências listadas no arquivo package.json:

```bash
npm install
```

#### Configure as Variáveis de Ambiente


Crie um arquivo chamado .env na raiz do projeto. Dentro deste arquivo, adicione a seguinte linha, substituindo pela URL real da sua API:

```bash
API_URL=http://endereco-da-sua-api.com
```

#### Inicie o Servidor

Com tudo configurado, inicie o servidor com o seguinte comando:

```bash
node app.js
```

Como alternativa, você pode adicionar um script start ao seu package.json e usar npm start.

#### Acesse a Aplicação

Com o servidor em execução, abra seu navegador de internet e acesse a seguinte URL:

http://localhost:3000


# Visão Geral - Tecnologias Frontend

## Stack Tecnológica Principal

### 1. **Template Engine - EJS (Embedded JavaScript)**
- **Versão**: 3.1.10
- **Função**: Renderização server-side de templates HTML dinâmicos
- **Características**:
  - Sintaxe simples e familiar (similar ao HTML)
  - Suporte a JavaScript embarcado
  - Renderização no servidor (SSR)
  - Partials para reutilização de componentes
  - Passagem de dados do backend para frontend

**Exemplo de uso**:
```ejs
<% if (playlists && playlists.items.length > 0) { %>
    <% playlists.items.forEach(playlist => { %>
        <div class="playlist-item">
            <%= playlist.name %>
        </div>
    <% }) %>
<% } %>
```

### 2. **Framework CSS - Bootstrap 5.3.3**
- **CDN**: jsdelivr.net
- **Função**: Framework CSS responsivo e componentes UI
- **Características**:
  - Sistema de grid flexível (Flexbox/CSS Grid)
  - Componentes pré-construídos (cards, navbar, forms, buttons)
  - Utilitários CSS extensivos
  - Responsividade mobile-first
  - Customização via CSS custom properties

**Componentes utilizados**:
- `navbar` - Navegação principal
- `card` - Containers de conteúdo
- `form-control` - Campos de formulário
- `btn` - Botões estilizados
- `list-group` - Listas de itens
- `alert` - Mensagens de feedback

### 3. **Ícones - Font Awesome 6.4.0**
- **CDN**: cdnjs.cloudflare.com
- **Função**: Biblioteca de ícones vetoriais
- **Características**:
  - Ícones escaláveis (SVG/Web Fonts)
  - Ampla variedade de símbolos
  - Consistência visual
  - Suporte a animações CSS

**Ícones implementados**:
- `fas fa-download` - Download de vídeos
- `fas fa-list` - Playlists
- `fas fa-plus` - Adicionar itens
- `fas fa-trash` - Excluir itens
- `fas fa-play-circle` - Reprodução
- `fas fa-video` - Vídeos
- `fas fa-clock` - Duração
- `fas fa-cassette-tape` - Tema cassete

## Tecnologias CSS Avançadas

### 4. **CSS Custom Properties (Variáveis CSS)**
```css
:root {
    --cassette-primary: #2c3e50;
    --cassette-secondary: #e74c3c;
    --cassette-accent: #f39c12;
    --cassette-dark: #1a252f;
    --cassette-light: #ecf0f1;
    --cassette-muted: #7f8c8d;
}
```
- **Função**: Sistema de design consistente
- **Benefícios**: Manutenibilidade, tematização, reutilização

### 5. **CSS Gradients**
```css
background: linear-gradient(135deg, var(--cassette-primary) 0%, var(--cassette-dark) 100%);
```
- **Tipos utilizados**: Linear gradients
- **Aplicação**: Navbar, botões, backgrounds
- **Efeito**: Profundidade visual e modernidade

### 6. **CSS Transitions & Transforms**
```css
transition: all 0.3s ease;
transform: translateY(-1px);
```
- **Função**: Animações suaves e micro-interações
- **Propriedades animadas**: transform, box-shadow, background, color
- **Duração**: 0.3s para responsividade ideal

### 7. **CSS Box Shadow**
```css
box-shadow: 0 8px 32px rgba(0,0,0,0.1);
```
- **Função**: Profundidade e hierarquia visual
- **Variações**: Sombras sutis, médias e pronunciadas
- **Estados**: Normal, hover, focus

## Arquitetura de Layout

### 8. **Flexbox Layout**
- **Uso**: Alinhamento de elementos, distribuição de espaço
- **Classes Bootstrap**: `d-flex`, `justify-content-between`, `align-items-center`
- **Benefícios**: Layout responsivo e flexível

### 9. **CSS Grid (via Bootstrap)**
- **Sistema**: 12 colunas responsivas
- **Breakpoints**: xs, sm, md, lg, xl, xxl
- **Classes**: `container`, `row`, `col-*`

### 10. **Responsive Design**
- **Abordagem**: Mobile-first
- **Viewport meta tag**: Configurado para dispositivos móveis
- **Media queries**: Integradas via Bootstrap
- **Unidades**: rem, em, % para escalabilidade

## Tipografia e Fontes

### 11. **Font Stack**
```css
font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
```
- **Estratégia**: System fonts para performance
- **Fallbacks**: Múltiplas opções para compatibilidade
- **Características**: Legibilidade, modernidade, suporte universal

### 12. **Hierarquia Tipográfica**
- **Títulos**: `h1`, `h2` com pesos diferenciados
- **Corpo**: Classes Bootstrap (`lead`, `text-muted`)
- **Tamanhos**: Sistema modular baseado em rem

## Interatividade e Estados

### 13. **Estados de Hover**
```css
.btn:hover {
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(44, 62, 80, 0.3);
}
```
- **Elementos**: Botões, links, cards, itens de lista
- **Efeitos**: Elevação, mudança de cor, sombras

### 14. **Estados de Focus**
```css
.form-control:focus {
    border-color: var(--cassette-primary);
    box-shadow: 0 0 0 0.2rem rgba(44, 62, 80, 0.15);
}
```
- **Acessibilidade**: Indicadores visuais claros
- **Elementos**: Campos de formulário, botões, links

## JavaScript Frontend

### 15. **Bootstrap JavaScript 5.3.3**
- **CDN**: jsdelivr.net (bundle completo)
- **Função**: Componentes interativos
- **Recursos utilizados**:
  - Navbar collapse (menu mobile)
  - Modal behaviors (potencial uso futuro)
  - Tooltip/Popover (potencial uso futuro)

### 16. **JavaScript Nativo**
```javascript
onclick="return confirm('Excluir esta playlist?')"
```
- **Função**: Confirmações de ações destrutivas
- **Implementação**: Inline handlers para simplicidade
- **Benefício**: Prevenção de ações acidentais


## Compatibilidade

### 17. **Browser Support**
- **Modernos**: Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- **Tecnologias**: CSS Grid, Flexbox, Custom Properties
- **Fallbacks**: Graceful degradation via Bootstrap

## Estrutura de Arquivos Frontend

```
views/
├── partials/
│   ├── header.ejs          # CSS global, navbar, meta tags
│   └── footer.ejs          # Scripts, fechamento de tags
├── index.ejs               # Página de download
├── playlists.ejs           # Lista de playlists
└── playlist-detalhe.ejs    # Detalhes da playlist
```
