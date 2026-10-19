local Class = require 'lib.class'
local Eventos = require 'src.eventos'
local Enemigo = require 'src.enemigo'

local GestorOleadas = Class{}

function GestorOleadas:init(mapa_w, mapa_h)
    self.mapa_w = mapa_w
    self.mapa_h = mapa_h
    self.oleada = 0
    self.enemigos = {}
    self.tiempo_proxima_oleada = 1.0
    self.esperando_siguiente = true
end

function GestorOleadas:IniciarSiguienteOleada()
    self.oleada = self.oleada + 1
    self.esperando_siguiente = false

    local cantidad = 4 + (self.oleada * 3)
    for _ = 1, cantidad do
        local x, y = self:GenerarPuntoExterior()
        
        -- Velocidades base mucho más moderadas y controladas
        local vel_inicial = 75 + math.min(self.oleada * 5, 60)
        local aceleracion = 3 + math.min(self.oleada * 1.5, 12)

        table.insert(self.enemigos, Enemigo(x, y, vel_inicial, aceleracion))
    end

    Eventos.emitir("oleada_iniciada", self.oleada, cantidad)
end

function GestorOleadas:GenerarPuntoExterior()
    local margen = 40
    local borde = math.random(1, 4)
    local x, y

    if borde == 1 then
        x = math.random(-margen, self.mapa_w + margen)
        y = -margen
    elseif borde == 2 then
        x = math.random(-margen, self.mapa_w + margen)
        y = self.mapa_h + margen
    elseif borde == 3 then
        x = -margen
        y = math.random(-margen, self.mapa_h + margen)
    else
        x = self.mapa_w + margen
        y = math.random(-margen, self.mapa_h + margen)
    end
    return x, y
end

function GestorOleadas:update(dt, jugador, proyectiles)
    if self.esperando_siguiente then
        self.tiempo_proxima_oleada = self.tiempo_proxima_oleada - dt
        if self.tiempo_proxima_oleada <= 0 then
            self:IniciarSiguienteOleada()
        end
        return
    end

    -- 1. Actualizar enemigos y colision con el jugador
    for i = #self.enemigos, 1, -1 do
        local e = self.enemigos[i]
        e:update(dt, jugador.x, jugador.y)

        local dx = e.x - jugador.x
        local dy = e.y - jugador.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist < (e.radio + jugador.radio) then
            jugador:RecibirDanio(1)
            e:Destruir(50)
            table.remove(self.enemigos, i)
        end
    end

    -- 2. Colision de proyectiles con enemigos
    for j = #proyectiles, 1, -1 do
        local p = proyectiles[j]
        local impacto = false

        for i = #self.enemigos, 1, -1 do
            local e = self.enemigos[i]
            local dx = e.x - p.x
            local dy = e.y - p.y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist < (e.radio + p.radio) then
                impacto = true

                if p.es_pesado then
                    -- EXPLOSIÓN EN ÁREA: Daña a todos los enemigos dentro del radio
                    p:Explotar()
                    for k = #self.enemigos, 1, -1 do
                        local ek = self.enemigos[k]
                        local dist_exp = math.sqrt((ek.x - p.x)^2 + (ek.y - p.y)^2)
                        if dist_exp <= p.radio_explosion then
                            ek:Destruir(150)
                            table.remove(self.enemigos, k)
                        end
                    end
                else
                    -- Impacto normal de bala única
                    e:Destruir(100)
                    table.remove(self.enemigos, i)
                    p.destruido = true
                end
                break
            end
        end

        if impacto or p.destruido then
            table.remove(proyectiles, j)
        end
    end

    -- 3. Fin de oleada
    if #self.enemigos == 0 and not self.esperando_siguiente then
        self.esperando_siguiente = true
        self.tiempo_proxima_oleada = 2.0
        Eventos.emitir("oleada_completada", self.oleada)
    end
end

function GestorOleadas:draw()
    for i = 1, #self.enemigos do
        self.enemigos[i]:draw()
    end
end

return GestorOleadas