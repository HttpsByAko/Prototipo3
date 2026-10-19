local function new(x, y, zoom, rot)
    x = x or love.graphics.getWidth() * 0.5
    y = y or love.graphics.getHeight() * 0.5
    zoom = zoom or 1
    rot = rot or 0

    local camera = {x = x, y = y, scale = zoom, rot = rot}

    function camera:lookAt(target_x, target_y)
        self.x = target_x
        self.y = target_y
        return self
    end

    function camera:attach(x, y, w, h)
        x = x or 0
        y = y or 0
        w = w or love.graphics.getWidth()
        h = h or love.graphics.getHeight()

        love.graphics.push()
        love.graphics.setScissor(x, y, w, h)
        love.graphics.translate(x + w * 0.5, y + h * 0.5)
        love.graphics.scale(self.scale)
        love.graphics.rotate(self.rot)
        love.graphics.translate(-self.x, -self.y)
    end

    function camera:detach()
        love.graphics.setScissor()
        love.graphics.pop()
    end

    return camera
end

return new