local Eventos = {
    _oyentes = {}
}

function Eventos.on(nombre, callback)
    if not Eventos._oyentes[nombre] then
        Eventos._oyentes[nombre] = {}
    end
    table.insert(Eventos._oyentes[nombre], callback)
end

function Eventos.emitir(nombre, ...)
    local lista = Eventos._oyentes[nombre]
    if lista then
        for _, cb in ipairs(lista) do
            cb(...)
        end
    end
end

function Eventos.limpiar()
    Eventos._oyentes = {}
end

return Eventos