local Class = require 'lib.class'
local Camera = require 'lib.camera'
local Eventos = require 'src.eventos'

local CamaraMgr = Class{}

function CamaraMgr:init(ancho_v, alto_v, mapa_ancho, mapa_alto)
    self.cam = Camera()
    self.ancho_v = ancho_v
    self.alto_v = alto_v
    self.mapa_w = mapa_ancho
    self.mapa_h = mapa_alto
    
    self.shake_tiempo = 0
    self.shake_intensidad = 0

    Eventos.on("jugador_danado", function()
        self:Shake(0.25, 12)
    end)

    -- Shake contundente al detonar el tiro pesado
    Eventos.on("explosion_pesada", function()
        self:Shake(0.35, 18)
    end)
end

function CamaraMgr:Shake(duracion, intensidad)
    self.shake_tiempo = duracion
    self.shake_intensidad = intensidad
end

function CamaraMgr:update(dt, target_x, target_y)
    local cx = target_x
    local cy = target_y

    local medio_w = self.ancho_v * 0.5
    local medio_h = self.alto_v * 0.5

    if cx < medio_w then cx = medio_w end
    if cy < medio_h then cy = medio_h end
    if cx > (self.mapa_w - medio_w) then cx = self.mapa_w - medio_w end
    if cy > (self.mapa_h - medio_h) then cy = self.mapa_h - medio_h end

    if self.shake_tiempo > 0 then
        self.shake_tiempo = self.shake_tiempo - dt
        cx = cx + (math.random() * 2 - 1) * self.shake_intensidad
        cy = cy + (math.random() * 2 - 1) * self.shake_intensidad
    end

    self.cam:lookAt(math.floor(cx + 0.5), math.floor(cy + 0.5))
end

function CamaraMgr:attach()
    self.cam:attach(0, 0, self.ancho_v, self.alto_v)
end

function CamaraMgr:detach()
    self.cam:detach()
end

return CamaraMgr