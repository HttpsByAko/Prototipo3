local Class = require 'lib.class'
local Eventos = require 'src.eventos'

local Enemigo = Class{}

function Enemigo:init(x, y, velocidad_inicial, tasa_aceleracion)
    self.x = x
    self.y = y
    self.radio = 14
    self.velocidad = velocidad_inicial or 175
    self.velocidad_maxima = self.velocidad * 1.35
    self.aceleracion = tasa_aceleracion or 1.2
    self.color = {0.92, 0.25, 0.25, 1}
    self.vivo = true
end

function Enemigo:update(dt, objetivo_x, objetivo_y)
    if not self.vivo then return end

    if self.velocidad < self.velocidad_maxima then
        self.velocidad = math.min(self.velocidad_maxima, self.velocidad + self.aceleracion * dt)
    end

    local dx = objetivo_x - self.x
    local dy = objetivo_y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 0 then
        self.x = self.x + (dx / dist) * self.velocidad * dt
        self.y = self.y + (dy / dist) * self.velocidad * dt
    end
end

function Enemigo:draw()
    if not self.vivo then return end

    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, self.radio)
    
    love.graphics.setColor(0.5, 0.1, 0.1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, self.radio)
    
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.circle("fill", self.x, self.y, self.radio * 0.35)
    
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

function Enemigo:Destruir(puntos)
    if not self.vivo then return end
    self.vivo = false
    Eventos.emitir("enemigo_eliminado", puntos or 100, self.x, self.y)
end

return Enemigo