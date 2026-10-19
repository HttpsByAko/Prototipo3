local Jugador = require 'src.jugador'
local GestorOleadas = require 'src.gestor_oleadas'
local CamaraMgr = require 'src.camara_mgr'
local HUD = require 'src.hud'
local Eventos = require 'src.eventos'

local MAPA = {
    ancho = 3000,
    alto  = 3000,
    tile_size = 64,
    color_base = {0.88, 0.78, 0.55},
    color_linea = {0.82, 0.72, 0.48}
}

local jugador = nil
local oleadas = nil
local camara = nil
local hud = nil
local proyectiles = {}
local efectos_explosion = {}

local function reproducirSonido(freq_inicial, amortiguacion, longitud)
    local sound_data = love.sound.newSoundData(longitud, 22050, 16, 1)
    for i = 0, longitud - 1 do
        sound_data:setSample(i, math.sin(i * freq_inicial) * math.exp(-i / amortiguacion))
    end
    local sfx = love.audio.newSource(sound_data)
    sfx:play()
end

local function dibujarSueloArena()
    love.graphics.setColor(MAPA.color_base)
    love.graphics.rectangle("fill", 0, 0, MAPA.ancho, MAPA.alto)

    love.graphics.setColor(MAPA.color_linea)
    love.graphics.setLineWidth(1)
    for x = 0, MAPA.ancho, MAPA.tile_size do
        love.graphics.line(x, 0, x, MAPA.alto)
    end
    for y = 0, MAPA.alto, MAPA.tile_size do
        love.graphics.line(0, y, MAPA.ancho, y)
    end

    love.graphics.setColor(0.40, 0.30, 0.15)
    love.graphics.setLineWidth(6)
    love.graphics.rectangle("line", 0, 0, MAPA.ancho, MAPA.alto)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1)
end

local function reiniciarJuego()
    Eventos.limpiar()
    proyectiles = {}
    efectos_explosion = {}

    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    if love.audio then
        Eventos.on("jugador_danado", function()
            reproducirSonido(0.22, 220, 1400)
        end)
        Eventos.on("disparo_realizado", function()
            reproducirSonido(0.65, 80, 800)
        end)
        Eventos.on("disparo_pesado_realizado", function()
            reproducirSonido(0.18, 300, 2500)
        end)
        Eventos.on("explosion_pesada", function(x, y, radio)
            reproducirSonido(0.09, 500, 4000)
            table.insert(efectos_explosion, {x = x, y = y, radio_max = radio, r_actual = 5, alfa = 1})
        end)
        Eventos.on("enemigo_eliminado", function()
            reproducirSonido(0.35, 120, 900)
        end)
    end

    jugador = Jugador(MAPA.ancho * 0.5, MAPA.alto * 0.5)
    oleadas = GestorOleadas(MAPA.ancho, MAPA.alto)
    camara  = CamaraMgr(w, h, MAPA.ancho, MAPA.alto)
    hud     = HUD()
end

function love.load()
    math.randomseed(os.time())
    reiniciarJuego()
end

function love.resize(w, h)
    if camara then
        camara.ancho_v = w
        camara.alto_v = h
    end
end

local function obtenerMouseEnMundo()
    local mx, my = love.mouse.getPosition()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    return (mx - w * 0.5) + camara.cam.x, (my - h * 0.5) + camara.cam.y
end

function love.update(dt)
    if not hud then return end

    hud:update(dt)

    if not hud.game_over then
        local mundo_mx, mundo_my = obtenerMouseEnMundo()

        jugador:update(dt, MAPA.ancho, MAPA.alto, mundo_mx, mundo_my)

        if love.keyboard.isDown("space") then
            jugador:IntentarDispararNormal(proyectiles)
        end

        for i = #proyectiles, 1, -1 do
            local p = proyectiles[i]
            p:update(dt, MAPA.ancho, MAPA.alto)
            if p.destruido then
                table.remove(proyectiles, i)
            end
        end

        for i = #efectos_explosion, 1, -1 do
            local ef = efectos_explosion[i]
            ef.r_actual = ef.r_actual + (ef.radio_max - ef.r_actual) * 12 * dt
            ef.alfa = ef.alfa - dt * 2.5
            if ef.alfa <= 0 then
                table.remove(efectos_explosion, i)
            end
        end

        oleadas:update(dt, jugador, proyectiles)
    end

    if camara and jugador then
        camara:update(dt, jugador.x, jugador.y)
    end
end

function love.draw()
    if not hud or not camara or not jugador or not oleadas then return end

    local ancho_pantalla = love.graphics.getWidth()
    local alto_pantalla  = love.graphics.getHeight()

    camara:attach()
        dibujarSueloArena()

        for _, ef in ipairs(efectos_explosion) do
            love.graphics.setColor(1, 0.5, 0.1, ef.alfa * 0.4)
            love.graphics.circle("fill", ef.x, ef.y, ef.r_actual)
            love.graphics.setColor(1, 0.8, 0.2, ef.alfa)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", ef.x, ef.y, ef.r_actual)
            love.graphics.setLineWidth(1)
        end

        oleadas:draw()

        for i = 1, #proyectiles do
            proyectiles[i]:draw()
        end

        jugador:draw()
    camara:detach()

    hud:draw(ancho_pantalla, alto_pantalla, jugador)
end

function love.keypressed(key)
    if key == "r" and not hud.game_over then
        jugador:IntentarDisparoPesado(proyectiles)
    elseif (key == "return" or key == "kpenter") and hud.game_over then
        reiniciarJuego()
    elseif key == "escape" then
        love.event.quit()
    end
end