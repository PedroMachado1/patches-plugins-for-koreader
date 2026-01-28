local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local ImageWidget = require("ui/widget/imagewidget")
local OverlapGroup = require("ui/widget/overlapgroup")
local ReaderUI = require("apps/reader/readerui")
local RenderImage = require("ui/renderimage")
local ScreenSaverWidget = require("ui/widget/screensaverwidget")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local DataStorage = require("datastorage")
local SQ3 = require("lua-ljsqlite3/init")
local lfs = require("libs/libkoreader-lfs")
local bit = require("bit")
local util = require("util")
local _ = require("gettext")

local Screen = Device.screen

-- Constantes
local STATISTICS_DB_PATH = DataStorage:getSettingsDir() .. "/statistics.sqlite3"

-- Chaves de configuração
local SETTINGS = {
    DARK_MODE = "kobo_style_screensaver_dark_mode",
    LAST_BOOK_DATA = "kobo_style_last_book_data",
    LANGUAGE = "kobo_style_language",  -- "pt" ou "en"
    -- Escala global
    GLOBAL_SCALE = "kobo_style_global_scale",
    -- Tamanhos de fonte
    FONT_SIZE_TITLE = "kobo_style_font_size_title",
    FONT_SIZE_CHAPTER = "kobo_style_font_size_chapter", 
    FONT_SIZE_STATUS = "kobo_style_font_size_status",
    FONT_SIZE_QUOTE = "kobo_style_font_size_quote",
    -- Elementos visíveis
    SHOW_TITLE = "kobo_style_show_title",
    SHOW_CHAPTER = "kobo_style_show_chapter",
    SHOW_PROGRESS = "kobo_style_show_progress",
    SHOW_TIME_LEFT = "kobo_style_show_time_left",
    SHOW_TODAY_TIME = "kobo_style_show_today_time",
    SHOW_COVER = "kobo_style_show_cover",
    SHOW_PAGES = "kobo_style_show_pages",
    SHOW_QUOTE = "kobo_style_show_quote",
    -- Fontes de Citação
    QUOTE_SOURCE_HIGHLIGHTS = "kobo_style_quote_source_highlights",
    QUOTE_SOURCE_BOOKMARKS = "kobo_style_quote_source_bookmarks",
    -- Limites de caracteres
    MAX_TITLE_CHARS = "kobo_style_max_title_chars",
    MAX_CHAPTER_CHARS = "kobo_style_max_chapter_chars",
    MAX_QUOTE_CHARS = "kobo_style_max_quote_chars",
    -- Posição do box
    BOX_MARGIN_BOTTOM = "kobo_style_box_margin_bottom",
    -- Estilo do box
    BOX_BORDER_RADIUS = "kobo_style_box_border_radius",
}

-- Valores padrão
local DEFAULTS = {
    LANGUAGE = "en",
    GLOBAL_SCALE = 100,
    FONT_SIZE_TITLE = 13,
    FONT_SIZE_CHAPTER = 10,
    FONT_SIZE_STATUS = 10,
    FONT_SIZE_QUOTE = 10,
    SHOW_TITLE = true,
    SHOW_CHAPTER = true,
    SHOW_PROGRESS = true,
    SHOW_TIME_LEFT = true,
    SHOW_TODAY_TIME = true,
    SHOW_COVER = true,
    SHOW_TODAY_TIME = true,
    SHOW_COVER = true,
    SHOW_PAGES = false,
    SHOW_QUOTE = true,
    QUOTE_SOURCE_HIGHLIGHTS = true,
    QUOTE_SOURCE_BOOKMARKS = true,
    MAX_TITLE_CHARS = 40,
    MAX_CHAPTER_CHARS = 30,
    MAX_QUOTE_CHARS = 500, -- Aumentado para suportar parágrafos
    BOX_MARGIN_BOTTOM = 80,
    BOX_BORDER_RADIUS = 0,
}

-- ============================================================================
-- SISTEMA DE TRADUÇÃO
-- ============================================================================

local TRANSLATIONS = {
    pt = {
        -- Textos do screensaver
        no_title = "Sem título",
        percent_read = "%d%% lido",
        at_percent_time_left = "Em %d%% · %s",
        time_left_hm = "%dh %dmin restantes",
        time_left_h = "%dh restantes",
        time_left_m = "%d min restantes",
        time_left_less = "< 1 min restante",
        time_read_today = "%s lido hoje",
        page_of = "Página %d de %d",
        duration_hm = "%dh %dmin",
        duration_h = "%dh",
        duration_m = "%d min",
        duration_less = "< 1 min",
        
        -- Menu principal
        menu_kobo_style = "Estilo Kobo (capa + progresso)",
        menu_settings = "Configurações Estilo Kobo",
        
        -- Seções do menu
        section_language = "── Idioma ──",
        section_appearance = "── Aparência ──",
        section_elements = "── Elementos Visíveis ──",
        section_sizes = "── Tamanhos ──",
        section_text_limits = "── Limites de Texto ──",
        section_positioning = "── Posicionamento ──",
        section_actions = "── Ações ──",
        
        -- Opções de idioma
        language_portuguese = "Português",
        language_english = "English",
        
        -- Opções de aparência
        dark_mode = "Modo escuro",
        show_cover = "Exibir capa do livro",
        
        -- Elementos visíveis
        show_title = "Exibir título do livro",
        show_chapter = "Exibir capítulo atual",
        show_progress = "Exibir progresso",
        show_time_left = "Exibir tempo restante",
        show_today_time = "Exibir tempo lido hoje",
        show_pages = "Exibir página atual/total",
        show_quote = "Exibir citação aleatória",
        page_prefix = "Pág.",
        
        -- Fontes de citação
        section_quote_source = "── Fontes de Citação ──",
        quote_source_highlights = "Usar Destaques (Highlights)",
        quote_source_bookmarks = "Usar Marcadores (Bookmarks)",
        
        -- Tamanhos
        global_scale = "Escala global (%)",
        font_size_title = "Tamanho do título",
        font_size_chapter = "Tamanho do capítulo",
        font_size_status = "Tamanho do status",
        font_size_quote = "Tamanho da citação",
        
        -- Limites de texto
        max_title_chars = "Máx. caracteres do título",
        max_chapter_chars = "Máx. caracteres do capítulo",
        max_quote_chars = "Máx. caracteres da citação",
        
        -- Posicionamento
        margin_bottom = "Margem inferior (px)",
        box_border_radius = "Arredondamento dos cantos (px)",
        
        -- Ações
        restore_defaults = "Restaurar padrões",
        clear_last_book = "Limpar dados do último livro",
        settings_restored = "Configurações restauradas para o padrão",
        last_book_cleared = "Dados do último livro removidos",
        
        -- SpinWidget
        save = "Salvar",
    },
    
    en = {
        -- Screensaver texts
        no_title = "No title",
        percent_read = "%d%% read",
        at_percent_time_left = "At %d%% · %s",
        time_left_hm = "%dh %dmin left",
        time_left_h = "%dh left",
        time_left_m = "%d min left",
        time_left_less = "< 1 min left",
        time_read_today = "%s read today",
        page_of = "Page %d of %d",
        duration_hm = "%dh %dmin",
        duration_h = "%dh",
        duration_m = "%d min",
        duration_less = "< 1 min",
        
        -- Main menu
        menu_kobo_style = "Kobo Style (cover + progress)",
        menu_settings = "Kobo Style Settings",
        
        -- Menu sections
        section_language = "── Language ──",
        section_appearance = "── Appearance ──",
        section_elements = "── Visible Elements ──",
        section_sizes = "── Sizes ──",
        section_text_limits = "── Text Limits ──",
        section_positioning = "── Positioning ──",
        section_actions = "── Actions ──",
        
        -- Language options
        language_portuguese = "Português",
        language_english = "English",
        
        -- Appearance options
        dark_mode = "Dark mode",
        show_cover = "Show book cover",
        
        -- Visible elements
        show_title = "Show book title",
        show_chapter = "Show current chapter",
        show_progress = "Show progress",
        show_time_left = "Show time left",
        show_today_time = "Show time read today",
        show_pages = "Show current/total pages",
        show_quote = "Show random quote",
        page_prefix = "Page",
        
        -- Quote sources
        section_quote_source = "── Quote Sources ──",
        quote_source_highlights = "Use Highlights",
        quote_source_bookmarks = "Use Bookmarks",
        
        -- Sizes
        global_scale = "Global scale (%)",
        font_size_title = "Title font size",
        font_size_chapter = "Chapter font size",
        font_size_status = "Status font size",
        font_size_quote = "Quote font size",
        
        -- Text limits
        max_title_chars = "Max title characters",
        max_chapter_chars = "Max chapter characters",
        max_quote_chars = "Max quote characters",
        
        -- Positioning
        margin_bottom = "Bottom margin (px)",
        box_border_radius = "Box border radius (px)",
        
        -- Actions
        restore_defaults = "Restore defaults",
        clear_last_book = "Clear last book data",
        settings_restored = "Settings restored to defaults",
        last_book_cleared = "Last book data cleared",
        
        -- SpinWidget
        save = "Save",
    },
}

-- Função para obter o idioma atual
local function getCurrentLanguage()
    local lang = G_reader_settings:readSetting(SETTINGS.LANGUAGE)
    if lang == nil then return DEFAULTS.LANGUAGE end
    return lang
end

-- Função de tradução
local function T(key)
    local lang = getCurrentLanguage()
    local translations = TRANSLATIONS[lang] or TRANSLATIONS["pt"]
    return translations[key] or key
end

-- ============================================================================
-- FUNÇÕES AUXILIARES
-- ============================================================================

-- Retorna o valor da configuração ou o padrão
local function getSetting(key, default)
    local value = G_reader_settings:readSetting(key)
    if value == nil then return default end
    return value
end

-- Retorna se uma configuração booleana está ativa
local function isSettingEnabled(key, default)
    local value = G_reader_settings:readSetting(key)
    if value == nil then return default end
    return value == true
end

-- Trunca texto no primeiro dois-pontos
local function truncateAtColon(title)
    if not title or title == "" then return "" end
    local colon_pos = title:find(":")
    if colon_pos then
        return util.trim(title:sub(1, colon_pos - 1))
    end
    return title
end

-- Conta caracteres UTF-8
local function utf8Len(str)
    if not str or str == "" then return 0 end
    local len = 0
    local i = 1
    while i <= #str do
        local byte = string.byte(str, i)
        if byte >= 0xF0 then i = i + 4
        elseif byte >= 0xE0 then i = i + 3
        elseif byte >= 0xC0 then i = i + 2
        else i = i + 1 end
        len = len + 1
    end
    return len
end

-- Corta string UTF-8 com limite de caracteres
local function utf8Sub(str, max_chars)
    if not str or str == "" or max_chars <= 0 then return "" end
    local len = #str
    local i = 1
    local count = 0
    while i <= len and count < max_chars do
        local byte = string.byte(str, i)
        if byte >= 0xF0 then i = i + 4
        elseif byte >= 0xE0 then i = i + 3
        elseif byte >= 0xC0 then i = i + 2
        else i = i + 1 end
        count = count + 1
    end
    if i <= len then
        return str:sub(1, i - 1) .. " …"
    end
    return str
end

-- Verifica se há documento ativo
local function hasActiveDocument(ui)
    return ui and ui.document ~= nil
end

-- Formata duração em horas/minutos
local function formatDuration(secs)
    if not secs or secs <= 0 then return nil end
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    if h > 0 and m > 0 then
        return string.format(T("duration_hm"), h, m)
    elseif h > 0 then
        return string.format(T("duration_h"), h)
    elseif m > 0 then
        return string.format(T("duration_m"), m)
    else
        return T("duration_less")
    end
end

-- Formata tempo restante
local function formatTimeLeft(avg_time, pages_left)
    if not avg_time or avg_time <= 0 or not pages_left then return nil end
    local secs = avg_time * pages_left
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    if h > 0 and m > 0 then
        return string.format(T("time_left_hm"), h, m)
    elseif h > 0 then
        return string.format(T("time_left_h"), h)
    elseif m > 0 then
        return string.format(T("time_left_m"), m)
    else
        return T("time_left_less")
    end
end

-- ============================================================================
-- FUNÇÕES DE BANCO DE DADOS
-- ============================================================================

-- Obtém tempo de leitura de hoje pelo ID do livro
local function getBookTodayDurationById(id_book)
    if not id_book then return nil end
    if not STATISTICS_DB_PATH or STATISTICS_DB_PATH == "" then return nil end
    
    local attrs = lfs.attributes(STATISTICS_DB_PATH, "mode")
    if attrs ~= "file" then return nil end
    
    local now_stamp = os.time()
    local now_t = os.date("*t", now_stamp)
    local from_begin_day = now_t.hour * 3600 + now_t.min * 60 + now_t.sec
    local start_today_time = now_stamp - from_begin_day
    
    local ok_conn, conn = pcall(SQ3.open, STATISTICS_DB_PATH)
    if not ok_conn or not conn then return nil end
    
    local sql_stmt = string.format([[SELECT sum(sum_duration)
        FROM (
            SELECT sum(duration) AS sum_duration
            FROM page_stat
            WHERE start_time >= %d AND id_book = %d
            GROUP BY page
        );
    ]], start_today_time, id_book)
    
    local ok_row, today_duration = pcall(function()
        return conn:rowexec(sql_stmt)
    end)
    conn:close()
    
    if not ok_row or today_duration == nil then return nil end
    today_duration = tonumber(today_duration)
    if not today_duration or today_duration <= 0 then return nil end
    return today_duration
end

-- Obtém tempo de leitura de hoje usando o objeto statistics
local function getBookTodayDuration(statistics)
    if not statistics then return nil end
    if statistics.isEnabled and not statistics:isEnabled() then return nil end
    if statistics.insertDB then pcall(statistics.insertDB, statistics) end

    local id_book = statistics.id_curr_book
    if (not id_book) and statistics.getIdBookDB then
        local ok, book_id = pcall(statistics.getIdBookDB, statistics)
        if ok then id_book = book_id end
    end
    
    return getBookTodayDurationById(id_book)
end

-- ============================================================================
-- FUNÇÕES DE PERSISTÊNCIA
-- ============================================================================

-- Salva dados do último livro lido
local function saveLastBookData(data)
    if data then
        G_reader_settings:saveSetting(SETTINGS.LAST_BOOK_DATA, data)
    end
end

-- Carrega dados do último livro lido
local function loadLastBookData()
    return G_reader_settings:readSetting(SETTINGS.LAST_BOOK_DATA)
end

-- Coleta dados do livro atual
local function collectCurrentBookData(ui, state)
    if not hasActiveDocument(ui) then return nil end
    
    local doc_props = ui.doc_props or {}
    local book_title = truncateAtColon(doc_props.display_title or "") or ""
    if book_title == "" then book_title = "Sem título" end
    
    local doc_page_no = (state and state.page) or 1
    
    local toc = ui.toc
    local chapter_title = ""
    
    if toc then
        chapter_title = toc:getTocTitleByPage(doc_page_no) or ""
        local colon_pos = chapter_title:find(":")
        if colon_pos then
            chapter_title = util.trim(chapter_title:sub(1, colon_pos - 1))
        end
    end
    
    local doc_settings = ui.doc_settings and ui.doc_settings.data or {}
    local doc_page_total = doc_settings.doc_pages or 1
    if doc_page_total <= 0 then doc_page_total = 1 end
    if doc_page_no < 1 then doc_page_no = 1 end
    if doc_page_no > doc_page_total then doc_page_no = doc_page_total end
    
    local page_no_numeric = doc_page_no
    local page_total_numeric = doc_page_total
    
    if ui.pagemap and ui.pagemap:wantsPageLabels() then
        local _, idx, count = ui.pagemap:getCurrentPageLabel(true)
        if idx and count then
            page_no_numeric = idx
            page_total_numeric = count
        end
    end
    
    local statistics = ui.statistics
    local avg_time = statistics and statistics.avg_time
    local id_book = statistics and statistics.id_curr_book
    
    local cover_path = nil
    if ui.document then
        cover_path = ui.document.file
    end
    
    return {
        title = book_title,
        chapter = chapter_title,
        page_no = page_no_numeric,
        page_total = page_total_numeric,
        avg_time = avg_time,
        id_book = id_book,
        cover_path = cover_path,
        timestamp = os.time(),
    }
end

-- ============================================================================
-- FUNÇÕES DE HIGHLIGHTS/CITAÇÕES
-- ============================================================================

-- Remove a extensão do arquivo para obter o caminho base
local function getBookBasePath(book_path)
    if not book_path then return nil end
    -- Remove a extensão do arquivo (ex: .epub, .pdf, .mobi, etc)
    local base = book_path:match("(.+)%.[^%.]+$")
    return base or book_path
end

-- Encontra o arquivo de metadados do livro
local function findMetadataFile(book_path)
    if not book_path then return nil end
    
    -- A pasta .sdr usa o nome do arquivo SEM a extensão
    local base_path = getBookBasePath(book_path)
    local sdr_path = base_path .. ".sdr"
    
    -- Verifica se o diretório .sdr existe
    local sdr_attrs = lfs.attributes(sdr_path, "mode")
    if sdr_attrs ~= "directory" then return nil end
    
    -- Lista de possíveis nomes de arquivos de metadados
    local possible_files = {
        "metadata.lua",
        "metadata.epub.lua",
        "metadata.pdf.lua",
        "metadata.mobi.lua",
        "metadata.azw3.lua",
        "metadata.azw.lua",
        "metadata.fb2.lua",
        "metadata.cbz.lua",
        "metadata.txt.lua",
        "metadata.html.lua",
        "metadata.htm.lua",
    }
    
    -- Tenta encontrar um arquivo que exista
    for _, filename in ipairs(possible_files) do
        local filepath = sdr_path .. "/" .. filename
        local attrs = lfs.attributes(filepath, "mode")
        if attrs == "file" then
            return filepath
        end
    end
    
    -- Tenta encontrar qualquer arquivo metadata.*.lua no diretório
    for entry in lfs.dir(sdr_path) do
        if entry:match("^metadata%..*%.lua$") or entry == "metadata.lua" then
            local filepath = sdr_path .. "/" .. entry
            local attrs = lfs.attributes(filepath, "mode")
            if attrs == "file" then
                return filepath
            end
        end
    end
    
    return nil
end

-- Função auxiliar para carregar metadados com pcall
local function loadMetadata(metadata_path)
    local ok, metadata = pcall(dofile, metadata_path)
    if not ok or not metadata then return nil end
    return metadata
end

-- Carrega os highlights de um livro
local function loadBookHighlights(book_path, include_highlights, include_bookmarks)
    if not book_path then return {} end
    
    -- Se filtros não forem especificados, assumir todos (comportamento padrão)
    if include_highlights == nil then include_highlights = true end
    if include_bookmarks == nil then include_bookmarks = true end
    
    local metadata_path = findMetadataFile(book_path)
    if not metadata_path then return {} end
    
    -- Tenta carregar os metadados
    local metadata = loadMetadata(metadata_path)
    if not metadata then return {} end
    
    local highlights = {}
    
    -- Método 1: Busca na tabela "highlight" (estrutura antiga/específica)
    if include_highlights and metadata.highlight then
        for page, page_highlights in pairs(metadata.highlight) do
            if type(page_highlights) == "table" then
                for _, hl in pairs(page_highlights) do
                    if hl.text and hl.text ~= "" then
                        table.insert(highlights, {
                            text = hl.text,
                            page = hl.pageno or page,
                            chapter = hl.chapter or "",
                        })
                    end
                end
            end
        end
    end
    
    -- Método 2: Busca na tabela "bookmarks" (Favoritos)
    if include_bookmarks and metadata.bookmarks then
        for _, bm in pairs(metadata.bookmarks) do
            -- Bookmarks podem ter texto (notes) ou não (apenas marcador)
            -- Se tiver texto ou anotação, consideramos.
            local text = bm.text or bm.notes
            if text and text ~= "" then
                table.insert(highlights, {
                    text = text,
                    page = bm.page, -- Bookmarks geralmente usam xpointer, convertemos na exibicao se der
                    chapter = bm.chapter or "",
                })
            end
        end
    end
    
    -- Método 3: Busca na tabela "annotations" (Highlights modernos do KOReader)
    if include_highlights and metadata.annotations then
        for _, ann in pairs(metadata.annotations) do
            if ann.text and ann.text ~= "" then
                table.insert(highlights, {
                    text = ann.text,
                    page = ann.pageno or ann.page,
                    chapter = ann.chapter or "",
                })
            end
        end
    end
    
    return highlights
end

-- Seleciona uma citação aleatória dos highlights
local function getRandomHighlight(book_path, max_chars)
    if not book_path then return nil end
    
    -- Lê configurações de filtro
    local use_highlights = isSettingEnabled(SETTINGS.QUOTE_SOURCE_HIGHLIGHTS, DEFAULTS.QUOTE_SOURCE_HIGHLIGHTS)
    local use_bookmarks = isSettingEnabled(SETTINGS.QUOTE_SOURCE_BOOKMARKS, DEFAULTS.QUOTE_SOURCE_BOOKMARKS)
    
    local highlights = loadBookHighlights(book_path, use_highlights, use_bookmarks)
    
    -- Se não encontrou highlights, retorna nil
    if #highlights == 0 then return nil end
    
    -- Seleciona um highlight aleatório
    math.randomseed(os.time())
    local random_index = math.random(1, #highlights)
    local selected = highlights[random_index]
    
    if not selected or not selected.text then return nil end
    
    -- Aplica o limite de caracteres
    local text = selected.text
    if max_chars and max_chars > 0 then
        text = utf8Sub(text, max_chars)
    end
    
    return {
        text = tostring(text),
        page = selected.page and tostring(selected.page) or nil,
        chapter = selected.chapter and tostring(selected.chapter) or "",
    }
end

-- ============================================================================
-- FUNÇÕES DE CONSTRUÇÃO DE WIDGETS
-- ============================================================================

-- Obtém capa do documento ativo
local function getActiveDocumentCover(ui)
    if not ui or not ui.document or not ui.bookinfo then return nil end
    return ui.bookinfo:getCoverImage(ui.document)
end

-- Constrói widget de capa a partir de blitbuffer
local function buildCoverWidget(cover_bb)
    if not cover_bb then return nil end
    local screen_size = Screen:getSize()
    local scaled_bb = RenderImage:scaleBlitBuffer(cover_bb, screen_size.w, screen_size.h, true)
    return ImageWidget:new{
        image = scaled_bb,
        width = screen_size.w,
        height = screen_size.h,
        alpha = true,
    }
end

-- Constrói capa a partir do path do arquivo
local function buildCoverFromPath(file_path)
    if not file_path then return nil end
    
    local attrs = lfs.attributes(file_path, "mode")
    if attrs ~= "file" then return nil end
    
    local DocumentRegistry = require("document/documentregistry")
    local doc = DocumentRegistry:openDocument(file_path)
    if not doc then return nil end
    
    local cover_bb = nil
    if doc.getCoverPageImage then
        local ok, cover = pcall(doc.getCoverPageImage, doc)
        if ok then cover_bb = cover end
    end
    doc:close()
    
    return buildCoverWidget(cover_bb)
end

-- Constrói o widget estilo Kobo
local function buildKoboStyleWidget(book_data, ui)
    local TextBoxWidget = require("ui/widget/textboxwidget") -- Importação necessária
    local screen_size = Screen:getSize()
    if not book_data then return nil end
    
    -- Carregar configurações
    local show_title = isSettingEnabled(SETTINGS.SHOW_TITLE, DEFAULTS.SHOW_TITLE)
    local show_chapter = isSettingEnabled(SETTINGS.SHOW_CHAPTER, DEFAULTS.SHOW_CHAPTER)
    local show_progress = isSettingEnabled(SETTINGS.SHOW_PROGRESS, DEFAULTS.SHOW_PROGRESS)
    local show_time_left = isSettingEnabled(SETTINGS.SHOW_TIME_LEFT, DEFAULTS.SHOW_TIME_LEFT)
    local show_today_time = isSettingEnabled(SETTINGS.SHOW_TODAY_TIME, DEFAULTS.SHOW_TODAY_TIME)
    local show_cover = isSettingEnabled(SETTINGS.SHOW_COVER, DEFAULTS.SHOW_COVER)
    local show_pages = isSettingEnabled(SETTINGS.SHOW_PAGES, DEFAULTS.SHOW_PAGES)
    local show_quote = isSettingEnabled(SETTINGS.SHOW_QUOTE, DEFAULTS.SHOW_QUOTE)
    
    -- Escala global (100 = 100%)
    local global_scale = getSetting(SETTINGS.GLOBAL_SCALE, DEFAULTS.GLOBAL_SCALE) / 100
    
    -- Tamanhos de fonte com escala aplicada
    local font_size_title = math.floor(getSetting(SETTINGS.FONT_SIZE_TITLE, DEFAULTS.FONT_SIZE_TITLE) * global_scale)
    local font_size_chapter = math.floor(getSetting(SETTINGS.FONT_SIZE_CHAPTER, DEFAULTS.FONT_SIZE_CHAPTER) * global_scale)
    local font_size_status = math.floor(getSetting(SETTINGS.FONT_SIZE_STATUS, DEFAULTS.FONT_SIZE_STATUS) * global_scale)
    local font_size_quote = math.floor(getSetting(SETTINGS.FONT_SIZE_QUOTE, DEFAULTS.FONT_SIZE_QUOTE) * global_scale)
    
    local max_title_chars = getSetting(SETTINGS.MAX_TITLE_CHARS, DEFAULTS.MAX_TITLE_CHARS)
    local max_chapter_chars = getSetting(SETTINGS.MAX_CHAPTER_CHARS, DEFAULTS.MAX_CHAPTER_CHARS)
    local max_quote_chars = getSetting(SETTINGS.MAX_QUOTE_CHARS, DEFAULTS.MAX_QUOTE_CHARS)
    local box_margin_bottom = math.floor(getSetting(SETTINGS.BOX_MARGIN_BOTTOM, DEFAULTS.BOX_MARGIN_BOTTOM) * global_scale)
    local box_border_radius = math.floor(getSetting(SETTINGS.BOX_BORDER_RADIUS, DEFAULTS.BOX_BORDER_RADIUS) * global_scale)
    
    -- Dados do livro
    local book_title = book_data.title or T("no_title")
    local chapter_title = book_data.chapter or ""
    local page_no = book_data.page_no or 1
    local page_total = book_data.page_total or 1
    local avg_time = book_data.avg_time
    local id_book = book_data.id_book
    local cover_path = book_data.cover_path
    
    -- Cálculos de progresso
    local page_left = math.max(page_total - page_no, 0)
    local percentage = math.floor((page_no / page_total) * 100 + 0.5)
    
    -- Tempo restante
    local time_left_str = nil
    if show_time_left and avg_time then
        time_left_str = formatTimeLeft(avg_time, page_left)
    end
    
    -- Tempo lido hoje
    local today_str = nil
    if show_today_time then
        local today_duration = nil
        if ui and ui.statistics then
            today_duration = getBookTodayDuration(ui.statistics)
        elseif id_book then
            today_duration = getBookTodayDurationById(id_book)
        end
        today_str = formatDuration(today_duration)
    end
    
    -- Montar texto de progresso
    local progress_text = string.format(T("percent_read"), percentage)
    if time_left_str then 
        progress_text = string.format(T("at_percent_time_left"), percentage, time_left_str)
    end
    
    -- Texto de tempo lido hoje
    local today_text = nil
    if today_str then
        today_text = string.format(T("time_read_today"), today_str)
    end
    
    -- Dimensões e espaçamentos (com escala aplicada)
    local screen_size = Screen:getSize()
    local padding = Screen:scaleBySize(math.floor(12 * global_scale))
    local spacing = Screen:scaleBySize(math.floor(2 * global_scale))
    
    -- Texto de páginas
    local pages_text = nil
    if show_pages then
        pages_text = string.format(T("page_of"), page_no, page_total)
    end
    
    -- Citação aleatória
    local quote_data = nil
    if show_quote and cover_path then
        quote_data = getRandomHighlight(cover_path, max_quote_chars)
    end
    
    -- Cores baseadas no modo escuro
    local dark_mode = G_reader_settings:isTrue(SETTINGS.DARK_MODE)
    local bg_color, text_color, text_color_medium, text_color_light, border_color, border_size
    if dark_mode then
        bg_color = Blitbuffer.COLOR_BLACK
        text_color = Blitbuffer.COLOR_WHITE
        text_color_medium = Blitbuffer.COLOR_GRAY_B  -- Cor intermediária para citação
        text_color_light = Blitbuffer.COLOR_GRAY_E
        border_color = Blitbuffer.COLOR_WHITE
        border_size = 1
    else
        bg_color = Blitbuffer.COLOR_WHITE
        text_color = Blitbuffer.COLOR_BLACK
        text_color_medium = Blitbuffer.COLOR_GRAY_5  -- Cor intermediária para citação (mais escura)
        text_color_light = Blitbuffer.COLOR_GRAY_3
        border_color = Blitbuffer.COLOR_BLACK
        border_size = 1
    end
    
    -- Fontes
    local title_face = Font:getFace("cfont", Screen:scaleBySize(font_size_title))
    local chapter_face = Font:getFace("cfont", Screen:scaleBySize(font_size_chapter))
    local status_face = Font:getFace("cfont", Screen:scaleBySize(font_size_status))
    local quote_face = Font:getFace("cfont", Screen:scaleBySize(font_size_quote))
    
    -- Construir elementos
    local elements = {}
    
    -- Título do livro
    if show_title then
        local title_text = utf8Sub(book_title, max_title_chars)
        table.insert(elements, TextWidget:new{
            text = title_text,
            face = title_face,
            fgcolor = text_color,
            bold = true,
        })
    end

    -- Citação aleatória (Configuração: Dentro do box principal)
    local quote_widget = nil
    if show_quote and quote_data and quote_data.text and quote_data.text ~= "" then
        -- Calcula largura disponível com margem segura
        local safe_margin = Screen:scaleBySize(40)
        local box_max_width = screen_size.w - (safe_margin * 2)
        
        quote_widget = TextBoxWidget:new{
            text = "“" .. quote_data.text .. "”",
            face = quote_face,
            fgcolor = text_color_medium,
            bold = true,
            width = box_max_width, -- Importante: TextBoxWidget precisa de largura fixa
            align = "left",
        }
    end
    
    -- Título do capítulo
    if show_chapter and chapter_title ~= "" then
        local chapter_text = utf8Sub(chapter_title, max_chapter_chars)
        if #elements > 0 then
            table.insert(elements, VerticalSpan:new{ width = spacing })
        end
        table.insert(elements, TextWidget:new{
            text = chapter_text,
            face = chapter_face,
            fgcolor = text_color_light,
            bold = true,
        })
    end
    
    -- Progresso Geral
    if show_progress then
        if #elements > 0 then
            table.insert(elements, VerticalSpan:new{ width = spacing })
        end
        table.insert(elements, TextWidget:new{
            text = progress_text,
            face = chapter_face,
            fgcolor = text_color_light,
            bold = true,
        })
    end
    
    -- Tempo lido hoje
    if show_today_time and today_text then
        if #elements > 0 then
            table.insert(elements, VerticalSpan:new{ width = spacing })
        end
        table.insert(elements, TextWidget:new{
            text = today_text,
            face = status_face,
            fgcolor = text_color_light,
            bold = true,
        })
    end
    
    -- Página atual / total
    if show_pages and pages_text then
        if #elements > 0 then
            table.insert(elements, VerticalSpan:new{ width = spacing })
        end
        table.insert(elements, TextWidget:new{
            text = pages_text,
            face = status_face,
            fgcolor = text_color_light,
            bold = true,
        })
    end
    
    -- Se não há elementos para mostrar, retorna nil
    if #elements == 0 then
        return nil
    end
    
    -- Montar box de conteúdo principal
    local box_content = VerticalGroup:new{ align = "left" }
    for _, el in ipairs(elements) do
        table.insert(box_content, el)
    end
    
    local info_box = FrameContainer:new{
        background = bg_color,
        bordersize = border_size,
        color = border_color,
        radius = box_border_radius,
        padding = padding,
        box_content,
    }
    
    -- Montar box de citação separado (se houver)
    local quote_box_container = nil
    if quote_widget then
        -- Calcula largura disponível com margem segura
        local safe_margin = Screen:scaleBySize(40)
        local box_max_width = screen_size.w - (safe_margin * 2)
        
        local wrapped_quote_widget = TextBoxWidget:new{
            text = "“" .. quote_data.text .. "”",
            face = quote_face,
            fgcolor = text_color_medium,
            bold = true,
            width = box_max_width,
            align = "left",
        }
        
        local quote_content = VerticalGroup:new{ align = "left" }
        table.insert(quote_content, wrapped_quote_widget)
        
        -- Adiciona informações de origem (Capítulo/Página)
        local source_parts = {}
        if quote_data.chapter and quote_data.chapter ~= "" then
            table.insert(source_parts, quote_data.chapter)
        end
        if quote_data.page then
            table.insert(source_parts, T("page_prefix") .. " " .. quote_data.page)
        end
        
        if #source_parts > 0 then
            table.insert(quote_content, VerticalSpan:new{ width = spacing * 2 })
            table.insert(quote_content, TextWidget:new{
                text = table.concat(source_parts, " · "),
                face = status_face, -- Fonte menor
                fgcolor = text_color_light,
                italic = true,
                width = box_max_width,
            })
        end
        
        quote_box_container = FrameContainer:new{
            background = bg_color,
            bordersize = border_size,
            color = border_color,
            radius = box_border_radius,
            padding = padding,
            quote_content,
        }
    end
    
    local margin_left = 0
    local margin_bottom = Screen:scaleBySize(box_margin_bottom)
    
    -- Calcula altura total para posicionamento
    local total_height = info_box:getSize().h
    local spacer_height = 0
    
    if quote_box_container then
        spacer_height = spacing * 4 -- Espaço entre os dois boxes
        total_height = total_height + quote_box_container:getSize().h + spacer_height
    end
    
    -- Grupo vertical contendo os boxes
    local content_group = VerticalGroup:new{ align = "left" }
    
    -- Se tiver citação separada, ela vai EMBAIXO (como pedido)
    -- Mas espera, geralmente queremos info principal em baixo e citação em cima?
    -- O user pediu "abaixo do principal". O principal é o info_box (título, cap, etc).
    -- Então: Info Box -> Espaço -> Quote Box (mais embaixo ainda? Ou quote box acima?)
    -- Geralmente overlays são no bottom. Se eu colocar abaixo, pode sair da tela se a margin for pequena.
    -- Vamos assumir que "abaixo" significa visualmente abaixo do título, que está no info_box.
    -- Se for um box separado, ele ficaria EMPILHADO.
    
    -- Vamos empilhar: InfoBox (topo da pilha bottom) e QuoteBox (abaixo dele).
    -- Como estamos alinhando no bottom da tela:
    -- Topo
    -- ...
    -- Info Box
    -- Quote Box
    -- Margin Bottom
    
    table.insert(content_group, info_box)
    
    if quote_box_container then
        table.insert(content_group, VerticalSpan:new{ width = spacer_height })
        table.insert(content_group, quote_box_container)
    end
    
    local positioned_box = OverlapGroup:new{
        dimen = screen_size,
        VerticalGroup:new{
            VerticalSpan:new{ width = screen_size.h - total_height - margin_bottom },
            HorizontalGroup:new{
                HorizontalSpan:new{ width = margin_left },
                content_group,
            },
        },
    }
    
    -- Construir capa de fundo
    local bg_widget = nil
    if show_cover then
        if ui and hasActiveDocument(ui) then
            local cover_bb = getActiveDocumentCover(ui)
            bg_widget = buildCoverWidget(cover_bb)
        elseif cover_path then
            bg_widget = buildCoverFromPath(cover_path)
        end
    end
    
    if bg_widget then
        return OverlapGroup:new{
            dimen = screen_size,
            bg_widget,
            positioned_box,
        }
    else
        return OverlapGroup:new{
            dimen = screen_size,
            positioned_box,
        }
    end
end

-- ============================================================================
-- INTEGRAÇÃO COM SCREENSAVER
-- ============================================================================

local Screensaver = require("ui/screensaver")
local orig_screensaver_show = Screensaver.show

Screensaver.show = function(self)
    if self.screensaver_type ~= "kobo_style" then
        return orig_screensaver_show(self)
    end

    local ui = self.ui or ReaderUI.instance
    local receipt_widget = nil
    local book_data = nil
    
    if hasActiveDocument(ui) then
        -- Documento ativo: coletar e salvar dados
        local state = ui and ui.view and ui.view.state
        book_data = collectCurrentBookData(ui, state)
        if book_data then
            saveLastBookData(book_data)
        end
        receipt_widget = buildKoboStyleWidget(book_data, ui)
    else
        -- Sem documento ativo: usar dados salvos
        book_data = loadLastBookData()
        if book_data then
            receipt_widget = buildKoboStyleWidget(book_data, nil)
        end
    end
    
    if not receipt_widget then
        return orig_screensaver_show(self)
    end

    if self.screensaver_widget then
        UIManager:close(self.screensaver_widget)
        self.screensaver_widget = nil
    end

    Device.screen_saver_mode = true

    local rotation_mode = Screen:getRotationMode()
    Device.orig_rotation_mode = rotation_mode
    if bit.band(rotation_mode, 1) == 1 then
        Screen:setRotationMode(Screen.DEVICE_ROTATED_UPRIGHT)
    else
        Device.orig_rotation_mode = nil
    end

    self.screensaver_widget = ScreenSaverWidget:new{
        widget = receipt_widget,
        background = Blitbuffer.COLOR_WHITE,
        covers_fullscreen = true,
    }
    self.screensaver_widget.modal = true
    self.screensaver_widget.dithered = true
    UIManager:show(self.screensaver_widget, "full")
end

-- ============================================================================
-- MENU DE CONFIGURAÇÕES
-- ============================================================================

local orig_dofile = dofile
_G.dofile = function(filepath)
    local result = orig_dofile(filepath)
    if filepath and filepath:match("screensaver_menu%.lua$") then
        if result and result[1] and result[1].sub_item_table then
            local wallpaper_submenu = result[1].sub_item_table

            local function isKoboStyleEnabled()
                return G_reader_settings:readSetting("screensaver_type") == "kobo_style"
            end
            
            -- Função auxiliar para criar spinners de tamanho
            local function createSizeSpinner(title_key, setting_key, default_value, min_val, max_val, step)
                local SpinWidget = require("ui/widget/spinwidget")
                return {
                    text = T(title_key),
                    callback = function()
                        local current = getSetting(setting_key, default_value)
                        local spin = SpinWidget:new{
                            title_text = T(title_key),
                            value = current,
                            value_min = min_val,
                            value_max = max_val,
                            value_step = step or 1,
                            default_value = default_value,
                            ok_text = T("save"),
                            callback = function(spin)
                                G_reader_settings:saveSetting(setting_key, spin.value)
                            end,
                        }
                        UIManager:show(spin)
                    end,
                }
            end

            -- Opção principal do Estilo Kobo
            table.insert(wallpaper_submenu, 6, {
                text = T("menu_kobo_style"),
                checked_func = function()
                    return G_reader_settings:readSetting("screensaver_type") == "kobo_style"
                end,
                callback = function()
                    G_reader_settings:saveSetting("screensaver_type", "kobo_style")
                end,
                radio = true,
            })

            -- Submenu de configurações
            table.insert(wallpaper_submenu, 7, {
                text = T("menu_settings"),
                enabled_func = isKoboStyleEnabled,
                sub_item_table = {
                    -- Seção: Idioma
                    {
                        text = T("section_language"),
                        enabled = false,
                    },
                    {
                        text = T("language_portuguese"),
                        checked_func = function()
                            return getCurrentLanguage() == "pt"
                        end,
                        callback = function()
                            G_reader_settings:saveSetting(SETTINGS.LANGUAGE, "pt")
                        end,
                        radio = true,
                    },
                    {
                        text = T("language_english"),
                        checked_func = function()
                            return getCurrentLanguage() == "en"
                        end,
                        callback = function()
                            G_reader_settings:saveSetting(SETTINGS.LANGUAGE, "en")
                        end,
                        radio = true,
                    },
                    
                    -- Seção: Aparência
                    {
                        text = T("section_appearance"),
                        enabled = false,
                    },
                    {
                        text = T("dark_mode"),
                        checked_func = function()
                            return G_reader_settings:isTrue(SETTINGS.DARK_MODE)
                        end,
                        callback = function()
                            G_reader_settings:flipNilOrFalse(SETTINGS.DARK_MODE)
                        end,
                    },
                    {
                        text = T("show_cover"),
                        checked_func = function()
                            return isSettingEnabled(SETTINGS.SHOW_COVER, DEFAULTS.SHOW_COVER)
                        end,
                        callback = function()
                            local current = isSettingEnabled(SETTINGS.SHOW_COVER, DEFAULTS.SHOW_COVER)
                            G_reader_settings:saveSetting(SETTINGS.SHOW_COVER, not current)
                        end,
                    },
                    
                    -- Seção: Elementos Visíveis
                    {
                        text = T("section_elements"),
                        enabled = false,
                    },
                    {
                        text = T("show_title"),
                        checked_func = function()
                            return isSettingEnabled(SETTINGS.SHOW_TITLE, DEFAULTS.SHOW_TITLE)
                        end,
                        callback = function()
                            local current = isSettingEnabled(SETTINGS.SHOW_TITLE, DEFAULTS.SHOW_TITLE)
                            G_reader_settings:saveSetting(SETTINGS.SHOW_TITLE, not current)
                        end,
                    },
                    {
                        text = T("show_chapter"),
                        checked_func = function()
                            return isSettingEnabled(SETTINGS.SHOW_CHAPTER, DEFAULTS.SHOW_CHAPTER)
                        end,
                        callback = function()
                            local current = isSettingEnabled(SETTINGS.SHOW_CHAPTER, DEFAULTS.SHOW_CHAPTER)
                            G_reader_settings:saveSetting(SETTINGS.SHOW_CHAPTER, not current)
                        end,
                    },
                    {
                        text = T("show_progress"),
                        checked_func = function()
                            return isSettingEnabled(SETTINGS.SHOW_PROGRESS, DEFAULTS.SHOW_PROGRESS)
                        end,
                        callback = function()
                            local current = isSettingEnabled(SETTINGS.SHOW_PROGRESS, DEFAULTS.SHOW_PROGRESS)
                            G_reader_settings:saveSetting(SETTINGS.SHOW_PROGRESS, not current)
                        end,
                    },
                    {
                        text = T("show_time_left"),
                        checked_func = function()
                            return isSettingEnabled(SETTINGS.SHOW_TIME_LEFT, DEFAULTS.SHOW_TIME_LEFT)
                        end,
                        callback = function()
                            local current = isSettingEnabled(SETTINGS.SHOW_TIME_LEFT, DEFAULTS.SHOW_TIME_LEFT)
                            G_reader_settings:saveSetting(SETTINGS.SHOW_TIME_LEFT, not current)
                        end,
                    },
                    {
                        text = T("show_today_time"),
                        checked_func = function()
                            return isSettingEnabled(SETTINGS.SHOW_TODAY_TIME, DEFAULTS.SHOW_TODAY_TIME)
                        end,
                        callback = function()
                            local current = isSettingEnabled(SETTINGS.SHOW_TODAY_TIME, DEFAULTS.SHOW_TODAY_TIME)
                            G_reader_settings:saveSetting(SETTINGS.SHOW_TODAY_TIME, not current)
                        end,
                    },
                    {
                        text = T("show_pages"),
                        checked_func = function()
                            return isSettingEnabled(SETTINGS.SHOW_PAGES, DEFAULTS.SHOW_PAGES)
                        end,
                        callback = function()
                            local current = isSettingEnabled(SETTINGS.SHOW_PAGES, DEFAULTS.SHOW_PAGES)
                            G_reader_settings:saveSetting(SETTINGS.SHOW_PAGES, not current)
                        end,
                    },
                    {
                        text = T("show_quote"),
                        checked_func = function()
                            return isSettingEnabled(SETTINGS.SHOW_QUOTE, DEFAULTS.SHOW_QUOTE)
                        end,
                        callback = function()
                            local current = isSettingEnabled(SETTINGS.SHOW_QUOTE, DEFAULTS.SHOW_QUOTE)
                            G_reader_settings:saveSetting(SETTINGS.SHOW_QUOTE, not current)
                        end,
                    },
                    
                    -- Seção: Fontes de Citação
                    {
                        text = T("section_quote_source"),
                        enabled = false,
                    },
                    {
                        text = T("quote_source_highlights"),
                        checked_func = function()
                            return isSettingEnabled(SETTINGS.QUOTE_SOURCE_HIGHLIGHTS, DEFAULTS.QUOTE_SOURCE_HIGHLIGHTS)
                        end,
                        callback = function()
                            local current = isSettingEnabled(SETTINGS.QUOTE_SOURCE_HIGHLIGHTS, DEFAULTS.QUOTE_SOURCE_HIGHLIGHTS)
                            G_reader_settings:saveSetting(SETTINGS.QUOTE_SOURCE_HIGHLIGHTS, not current)
                        end,
                    },
                    {
                        text = T("quote_source_bookmarks"),
                        checked_func = function()
                            return isSettingEnabled(SETTINGS.QUOTE_SOURCE_BOOKMARKS, DEFAULTS.QUOTE_SOURCE_BOOKMARKS)
                        end,
                        callback = function()
                            local current = isSettingEnabled(SETTINGS.QUOTE_SOURCE_BOOKMARKS, DEFAULTS.QUOTE_SOURCE_BOOKMARKS)
                            G_reader_settings:saveSetting(SETTINGS.QUOTE_SOURCE_BOOKMARKS, not current)
                        end,
                    },
                    
                    -- Seção: Tamanhos
                    {
                        text = T("section_sizes"),
                        enabled = false,
                    },
                    createSizeSpinner("global_scale", SETTINGS.GLOBAL_SCALE, DEFAULTS.GLOBAL_SCALE, 50, 200, 10),
                    createSizeSpinner("font_size_title", SETTINGS.FONT_SIZE_TITLE, DEFAULTS.FONT_SIZE_TITLE, 8, 24, 1),
                    createSizeSpinner("font_size_chapter", SETTINGS.FONT_SIZE_CHAPTER, DEFAULTS.FONT_SIZE_CHAPTER, 6, 20, 1),
                    createSizeSpinner("font_size_status", SETTINGS.FONT_SIZE_STATUS, DEFAULTS.FONT_SIZE_STATUS, 6, 20, 1),
                    createSizeSpinner("font_size_quote", SETTINGS.FONT_SIZE_QUOTE, DEFAULTS.FONT_SIZE_QUOTE, 6, 18, 1),
                    
                    -- Seção: Limites de Texto
                    {
                        text = T("section_text_limits"),
                        enabled = false,
                    },
                    createSizeSpinner("max_title_chars", SETTINGS.MAX_TITLE_CHARS, DEFAULTS.MAX_TITLE_CHARS, 15, 80, 5),
                    createSizeSpinner("max_chapter_chars", SETTINGS.MAX_CHAPTER_CHARS, DEFAULTS.MAX_CHAPTER_CHARS, 10, 60, 5),
                    createSizeSpinner("max_quote_chars", SETTINGS.MAX_QUOTE_CHARS, DEFAULTS.MAX_QUOTE_CHARS, 50, 2000, 50),
                    
                    -- Seção: Posicionamento
                    {
                        text = T("section_positioning"),
                        enabled = false,
                    },
                    createSizeSpinner("margin_bottom", SETTINGS.BOX_MARGIN_BOTTOM, DEFAULTS.BOX_MARGIN_BOTTOM, 0, 200, 10),
                    createSizeSpinner("box_border_radius", SETTINGS.BOX_BORDER_RADIUS, DEFAULTS.BOX_BORDER_RADIUS, 0, 50, 2),
                    
                    -- Seção: Ações
                    {
                        text = T("section_actions"),
                        enabled = false,
                    },
                    {
                        text = T("restore_defaults"),
                        callback = function()
                            -- Limpar todas as configurações personalizadas
                            G_reader_settings:delSetting(SETTINGS.DARK_MODE)
                            G_reader_settings:delSetting(SETTINGS.LANGUAGE)
                            G_reader_settings:delSetting(SETTINGS.GLOBAL_SCALE)
                            G_reader_settings:delSetting(SETTINGS.FONT_SIZE_TITLE)
                            G_reader_settings:delSetting(SETTINGS.FONT_SIZE_CHAPTER)
                            G_reader_settings:delSetting(SETTINGS.FONT_SIZE_STATUS)
                            G_reader_settings:delSetting(SETTINGS.FONT_SIZE_QUOTE)
                            G_reader_settings:delSetting(SETTINGS.SHOW_TITLE)
                            G_reader_settings:delSetting(SETTINGS.SHOW_CHAPTER)
                            G_reader_settings:delSetting(SETTINGS.SHOW_PROGRESS)
                            G_reader_settings:delSetting(SETTINGS.SHOW_TIME_LEFT)
                            G_reader_settings:delSetting(SETTINGS.SHOW_TODAY_TIME)
                            G_reader_settings:delSetting(SETTINGS.SHOW_COVER)
                            G_reader_settings:delSetting(SETTINGS.SHOW_PAGES)
                            G_reader_settings:delSetting(SETTINGS.SHOW_QUOTE)
                            G_reader_settings:delSetting(SETTINGS.QUOTE_SOURCE_HIGHLIGHTS)
                            G_reader_settings:delSetting(SETTINGS.QUOTE_SOURCE_BOOKMARKS)
                            G_reader_settings:delSetting(SETTINGS.MAX_TITLE_CHARS)
                            G_reader_settings:delSetting(SETTINGS.MAX_CHAPTER_CHARS)
                            G_reader_settings:delSetting(SETTINGS.MAX_QUOTE_CHARS)
                            G_reader_settings:delSetting(SETTINGS.BOX_MARGIN_BOTTOM)
                            G_reader_settings:delSetting(SETTINGS.BOX_BORDER_RADIUS)
                            
                            local Notification = require("ui/widget/notification")
                            UIManager:show(Notification:new{
                                text = T("settings_restored"),
                            })
                        end,
                    },
                    {
                        text = T("clear_last_book"),
                        callback = function()
                            G_reader_settings:delSetting(SETTINGS.LAST_BOOK_DATA)
                            
                            local Notification = require("ui/widget/notification")
                            UIManager:show(Notification:new{
                                text = T("last_book_cleared"),
                            })
                        end,
                    },
                },
            })
        end
    end
    return result
end
