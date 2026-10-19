local Class = require 'lib.class'
local Eventos = require 'src.eventos'

local Proyectil = Class{}

function Proyectil:init(x, y, angulo, es_pesado)
    self.x = x
    self.y = y
    self.es_pesado = es_pesado or false

    if self.es_pesado then
        self.radio = 10
        self.velocidad = 550
        self.radio_explosion = 90
        self.color = {1, 0.45, 0.1, 1}
    else
        self.radio = 5
        self.velocidad = 700
        self.radio_explosion = 0
        self.color = {1, 1, 1, 1}
    end

    self.vx = math.cos(angulo) * self.velocidad
    self.vy = math.sin(angulo) * self.velocidad
    self.vida_util = 3.0
    self.destruido = false
end

function Proyectil:update(dt, mapa_w, mapa_h)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    self.vida_util = self.vida_util - dt

    if self.vida_util <= 0 or self.x < 0 or self.x > mapa_w or self.y < 0 or self.y > mapa_h then
        self.destruido = true
    end
end

function Proyectil:Explotar()
    self.destruido = true
    if self.es_pesado then
        Eventos.emitir("explosion_pesada", self.x, self.y, self.radio_explosion)
    end
end

function Proyectil:draw()
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, self.radio)

    if self.es_pesado then
        love.graphics.setColor(1, 0.8, 0.2, 0.6)
        love.graphics.circle("line", self.x, self.y, self.radio + 3)
    else
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.circle("line", self.x, self.y, self.radio + 2)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Proyectil