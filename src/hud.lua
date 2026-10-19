local Class = require 'lib.class'
local Eventos = require 'src.eventos'

local HUD = Class{}

function HUD:init()
    self.vidas = 3
    self.score = 0
    self.oleada = 0
    self.mensaje_oleada = ""
    self.tiempo_mensaje = 0
    self.alerta_color = {1, 1, 1, 1}
    self.game_over = false

    local ruta_fuente = "fonts/fuente.ttf"
    if love.filesystem.getInfo(ruta_fuente) then
        self.fuente_ui = love.graphics.newFont(ruta_fuente, 16)
        self.fuente_chica = love.graphics.newFont(ruta_fuente, 13)
        self.fuente_grande = love.graphics.newFont(ruta_fuente, 32)
    else
        self.fuente_ui = love.graphics.newFont(16)
        self.fuente_chica = love.graphics.newFont(12)
        self.fuente_grande = love.graphics.newFont(30)
    end

    Eventos.on("oleada_iniciada", function(nro, cant)
        self.oleada = nro
        self.mensaje_oleada = "OLEADA " .. nro
        self.tiempo_mensaje = 2.5
    end)

    Eventos.on("oleada_completada", function(nro)
        self.mensaje_oleada = "¡OLEADA DESPEJADA!"
        self.tiempo_mensaje = 2.0
    end)

    Eventos.on("jugador_danado", function(vidas_restantes)
        self.vidas = vidas_restantes
        self.alerta_color = {1, 0.25, 0.25, 1}
    end)

    Eventos.on("enemigo_eliminado", function(puntos)
        self.score = self.score + puntos
    end)

    Eventos.on("game_over", function()
        self.game_over = true
    end)
end

function HUD:update(dt)
    if self.alerta_color[2] < 1 then
        self.alerta_color[2] = math.min(1, self.alerta_color[2] + dt * 2.5)
        self.alerta_color[3] = math.min(1, self.alerta_color[3] + dt * 2.5)
    end

    if self.tiempo_mensaje > 0 then
        self.tiempo_mensaje = self.tiempo_mensaje - dt
        if self.tiempo_mensaje <= 0 then
            self.mensaje_oleada = ""
        end
    end
end

local function dibujarMarco(x, y, w, h, borde_color)
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("fill", x + 3, y + 3, w, h, 6, 6)

    love.graphics.setColor(0.12, 0.12, 0.15, 0.88)
    love.graphics.rectangle("fill", x, y, w, h, 6, 6)

    borde_color = borde_color or {0.85, 0.75, 0.50, 1}
    love.graphics.setColor(borde_color)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 6, 6)
    love.graphics.setLineWidth(1)
end

function HUD:draw(ancho_v, alto_v, jugador)
    love.graphics.setFont(self.fuente_ui)

    -- 1. Marco Superior Izquierdo: Vidas y Puntaje
    dibujarMarco(20, 20, 240, 80, self.alerta_color)
    love.graphics.setColor(self.alerta_color)
    love.graphics.print("HP: " .. string.rep("♥ ", math.max(0, self.vidas)), 35, 30)
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.print("PUNTOS: " .. self.score, 35, 62)

    -- 2. Marco Superior Derecho: Ronda
    local ancho_ronda = 160
    local x_ronda = ancho_v - ancho_ronda - 20
    dibujarMarco(x_ronda, 20, ancho_ronda, 48)
    love.graphics.setColor(0.95, 0.85, 0.45, 1)
    love.graphics.printf("RONDA " .. self.oleada, x_ronda, 32, ancho_ronda, "center")

    -- 3. Marco Inferior Izquierdo: COOLDOWNS DE ARMAS
    if jugador and not self.game_over then
        local panel_cd_w = 260
        local panel_cd_h = 95
        local panel_cd_x = 20
        local panel_cd_y = alto_v - panel_cd_h - 20

        dibujarMarco(panel_cd_x, panel_cd_y, panel_cd_w, panel_cd_h, {0.3, 0.6, 0.8, 0.9})

        -- Habilidad 1: Disparo normal (ESPACIO)
        love.graphics.setFont(self.fuente_chica)
        love.graphics.setColor(0.85, 0.85, 0.85, 1)
        love.graphics.print("[ESPACIO] Básico", panel_cd_x + 12, panel_cd_y + 12)

        local progreso_normal = 1 - (jugador.cd_normal / jugador.cd_normal_max)
        love.graphics.setColor(0.2, 0.2, 0.25, 1)
        love.graphics.rectangle("fill", panel_cd_x + 12, panel_cd_y + 30, 236, 10, 3, 3)
        love.graphics.setColor(0.2, 0.7, 1, 1)
        love.graphics.rectangle("fill", panel_cd_x + 12, panel_cd_y + 30, 236 * progreso_normal, 10, 3, 3)

        -- Habilidad 2: Disparo pesado (R)
        love.graphics.setColor(0.85, 0.85, 0.85, 1)
        local texto_r = "[R] Cañón Pesado"
        if jugador.cd_pesado > 0 then
            texto_r = string.format("[R] Cañón Pesado (%.1fs)", jugador.cd_pesado)
        else
            texto_r = "[R] Cañón Pesado - ¡LISTO!"
        end
        love.graphics.print(texto_r, panel_cd_x + 12, panel_cd_y + 48)

        local progreso_pesado = 1 - (jugador.cd_pesado / jugador.cd_pesado_max)
        love.graphics.setColor(0.2, 0.2, 0.25, 1)
        love.graphics.rectangle("fill", panel_cd_x + 12, panel_cd_y + 66, 236, 12, 3, 3)
        
        if jugador.cd_pesado == 0 then
            love.graphics.setColor(1, 0.8, 0.2, 1) -- Dorado cuando está disponible
        else
            love.graphics.setColor(0.9, 0.4, 0.1, 1) -- Naranja cargando
        end
        love.graphics.rectangle("fill", panel_cd_x + 12, panel_cd_y + 66, 236 * progreso_pesado, 12, 3, 3)
    end

    -- 4. Cartel Central de Avisos de Oleada
    if self.mensaje_oleada ~= "" and not self.game_over then
        local banner_w = 400
        local banner_h = 60
        local banner_x = (ancho_v - banner_w) * 0.5
        local banner_y = 110

        dibujarMarco(banner_x, banner_y, banner_w, banner_h, {1, 0.85, 0.3, 1})
        love.graphics.setFont(self.fuente_grande)
        love.graphics.setColor(1, 0.9, 0.4, 1)
        love.graphics.printf(self.mensaje_oleada, banner_x, banner_y + 12, banner_w, "center")
    end

    -- 5. Pantalla de Game Over
    if self.game_over then
        local go_w = 500
        local go_h = 160
        local go_x = (ancho_v - go_w) * 0.5
        local go_y = (alto_v - go_h) * 0.45

        dibujarMarco(go_x, go_y, go_w, go_h, {0.9, 0.2, 0.2, 1})
        love.graphics.setFont(self.fuente_grande)
        love.graphics.setColor(1, 0.25, 0.25, 1)
        love.graphics.printf("GAME OVER", go_x, go_y + 25, go_w, "center")

        love.graphics.setFont(self.fuente_ui)
        love.graphics.setColor(0.9, 0.9, 0.9, 1)
        love.graphics.printf("Presiona 'ENTER' para reiniciar\nPresiona 'ESC' para salir", go_x, go_y + 85, go_w, "center")
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return HUD