local Class = require 'lib.class'
local Eventos = require 'src.eventos'
local Proyectil = require 'src.proyectil'

local Jugador = Class{}

function Jugador:init(x, y)
    self.x = x
    self.y = y
    self.radio = 18
    self.velocidad = 300
    self.vidas = 3
    self.invulnerable = 0
    self.color = {0.2, 0.6, 1, 1}

    self.canon_ancho = 34
    self.canon_alto  = 10
    self.angulo = 0

    self.cd_normal_max = 0.35   -- Más rápido que antes (era 0.5)
    self.cd_normal = 0

    self.cd_pesado_max = 5.0    -- 5 segundos de recarga
    self.cd_pesado = 0
end

function Jugador:update(dt, mapa_w, mapa_h, mouse_mundo_x, mouse_mundo_y)
    local dx, dy = 0, 0
    if love.keyboard.isDown("w", "up") then dy = dy - 1 end
    if love.keyboard.isDown("s", "down") then dy = dy + 1 end
    if love.keyboard.isDown("a", "left") then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end

    if dx ~= 0 and dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        dx = dx / len
        dy = dy / len
    end

    self.x = self.x + dx * self.velocidad * dt
    self.y = self.y + dy * self.velocidad * dt

    self.x = math.max(self.radio, math.min(mapa_w - self.radio, self.x))
    self.y = math.max(self.radio, math.min(mapa_h - self.radio, self.y))

    if self.invulnerable > 0 then
        self.invulnerable = self.invulnerable - dt
    end

    if mouse_mundo_x and mouse_mundo_y then
        self.angulo = math.atan2(mouse_mundo_y - self.y, mouse_mundo_x - self.x)
    end

    -- Actualizar tiempos de recarga
    if self.cd_normal > 0 then
        self.cd_normal = math.max(0, self.cd_normal - dt)
    end
    if self.cd_pesado > 0 then
        self.cd_pesado = math.max(0, self.cd_pesado - dt)
    end
end

function Jugador:IntentarDispararNormal(lista_proyectiles)
    if self.cd_normal > 0 or self.vidas <= 0 then return end

    self.cd_normal = self.cd_normal_max

    local spawn_x = self.x + math.cos(self.angulo) * self.canon_ancho
    local spawn_y = self.y + math.sin(self.angulo) * self.canon_ancho

    local p = Proyectil(spawn_x, spawn_y, self.angulo, false)
    table.insert(lista_proyectiles, p)

    Eventos.emitir("disparo_realizado", spawn_x, spawn_y)
end

function Jugador:IntentarDisparoPesado(lista_proyectiles)
    if self.cd_pesado > 0 or self.vidas <= 0 then return end

    self.cd_pesado = self.cd_pesado_max

    local spawn_x = self.x + math.cos(self.angulo) * self.canon_ancho
    local spawn_y = self.y + math.sin(self.angulo) * self.canon_ancho

    local p = Proyectil(spawn_x, spawn_y, self.angulo, true)
    table.insert(lista_proyectiles, p)

    Eventos.emitir("disparo_pesado_realizado", spawn_x, spawn_y)
end

function Jugador:RecibirDanio(cantidad)
    if self.invulnerable > 0 or self.vidas <= 0 then return end

    self.vidas = self.vidas - cantidad
    self.invulnerable = 1.0

    Eventos.emitir("jugador_danado", self.vidas)

    if self.vidas <= 0 then
        Eventos.emitir("game_over")
    end
end

function Jugador:draw()
    if self.invulnerable > 0 and (math.floor(self.invulnerable * 10) % 2 == 0) then
        return
    end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angulo)
    
    love.graphics.setColor(0.15, 0.25, 0.35, 1)
    love.graphics.rectangle("fill", 0, -self.canon_alto * 0.5, self.canon_ancho, self.canon_alto)
    love.graphics.setColor(0.08, 0.12, 0.18, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 0, -self.canon_alto * 0.5, self.canon_ancho, self.canon_alto)
    love.graphics.setLineWidth(1)
    love.graphics.pop()

    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, self.radio)
    love.graphics.setColor(0.1, 0.3, 0.6, 1)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, self.radio)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 1, 1)
end

return Jugador